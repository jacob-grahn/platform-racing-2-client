package pr2.page;

#if js
import js.Browser;
#end
import openfl.display.DisplayObject;
import openfl.display.StageQuality;
import openfl.events.MouseEvent;
import pr2.app.AppStage;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyLeft;
import pr2.lobby.LobbyPopups;
import pr2.lobby.LobbyRight;
import pr2.lobby.LobbySession;
import pr2.net.FormPostClient;
import pr2.net.LobbySocket;
import pr2.net.ServerInfo;
import pr2.net.ServerConfig;
import pr2.runtime.PR2MovieClip;
import pr2.audio.AudioManager;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.HoverPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.store.StorePopup;
import pr2.util.DisplayUtil;

typedef LobbyLogoutPostFactory = String->Map<String, String>->Void;

/**
	Port of Flash `lobby.Lobby`: the post-login lobby shell.

	Lays out the `LobbyGraphic` background, the left pane (`LobbyLeft`), the right
	pane (`LobbyRight`), and the `LobbyBottomButtonsGraphic` button strip. The
	bottom strip shows the Kongregate variant for members and the sponsored
	variant for guests, and wires logout, level-editor entry, more-games,
	options, vault/store, and credits to their Flash-equivalent actions.
**/
class LobbyPage extends Page {
	private static inline var TEMP_MOD_LOGOUT_CONFIRM:String = "You're currently a temporary moderator. Logging out will automatically demote you back to a member. Do you really want to proceed?";
	private static inline var TEMP_MOD_EDITOR_CONFIRM:String = "You're currently a temporary moderator. Entering the level editor will log you out, which will automatically demote you back to a member. Do you really want to proceed?";
	private static inline var TEMP_MOD_LOGGED_OUT_MESSAGE:String = "You are now logged out. If you haven't already done so, please notify a member of the staff team that you've ended your moderation session.";

	public static var createStorePopup:Void->Void = function():Void {
		new StorePopup();
	};
	public static var createLevelEditorPage:Bool->Page = function(isMod:Bool):Page {
		return new LevelEditor(null, isMod);
	};
	public static var logoutPostFactory:LobbyLogoutPostFactory = defaultLogoutPost;

	private var background:Null<PR2MovieClip>;
	private var left:Null<LobbyLeft>;
	private var right:Null<LobbyRight>;
	private var bottom:Null<PR2MovieClip>;
	private var bindings:Array<Binding> = [];
	private var hoverCleanups:Array<Void->Void> = [];
	private var hover:Null<HoverPopup>;

	public function new(?userName:String, ?server:ServerInfo) {
		super();
		// Allow direct construction (e.g. ?screen=lobby) to seed the session.
		if (userName != null) {
			LobbySession.userName = userName;
		}
		if (server != null) {
			LobbySession.server = server;
		}
	}

	override public function initialize():Void {
		AudioManager.enterLobby();
		if (AppStage.stage != null) {
			AppStage.stage.quality = StageQuality.HIGH;
		}
		background = PR2MovieClip.fromLinkage("LobbyGraphic", {maxNestedDepth: 8});
		addChild(background);

		left = new LobbyLeft();
		addChild(left);

		right = new LobbyRight();
		addChild(right);

		bottom = PR2MovieClip.fromLinkage("LobbyBottomButtonsGraphic", {maxNestedDepth: 8});
		bottom.gotoAndStop(LobbySession.isMember() ? "kongregateSite" : "sponsoredSite");
		bind(bottom, "logoutButton", function():Void clickLogout());
		bind(bottom, "levelEditorButton", function():Void clickLevelEditor());
		bind(bottom, "moreGamesButton", clickKong);
		bind(bottom, "optionsButton", clickOptions);
		bind(bottom, "vaultButton", clickStore);
		bind(bottom, "creditsButton", clickCredits);
		bindHover(bottom, "moreGamesButton", hoverKong, hoverOutKong);
		addChild(bottom);

		reportState('lobby:${LobbySession.userName}');
	}

	override public function remove():Void {
		AudioManager.leaveMenu();
		hoverOutKong();
		for (cleanup in hoverCleanups) {
			cleanup();
		}
		hoverCleanups = [];
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		if (left != null) {
			left.remove();
			left = null;
		}
		if (right != null) {
			right.remove();
			right = null;
		}
		if (bottom != null) {
			bottom.dispose();
			bottom = null;
		}
		if (background != null) {
			background.dispose();
			background = null;
		}
		super.remove();
	}

	private function bind(art:PR2MovieClip, name:String, handler:Void->Void):Void {
		var binding = LobbyArt.bind(DisplayUtil.findByName(art, name), handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	private function bindHover(art:PR2MovieClip, name:String, over:DisplayObject->Void, out:Void->Void):Void {
		var target = DisplayUtil.findByName(art, name);
		if (target == null) return;
		var onOver = function(_:MouseEvent):Void over(target);
		var onOut = function(_:MouseEvent):Void out();
		target.addEventListener(MouseEvent.MOUSE_OVER, onOver);
		target.addEventListener(MouseEvent.MOUSE_OUT, onOut);
		hoverCleanups.push(function():Void {
			target.removeEventListener(MouseEvent.MOUSE_OVER, onOver);
			target.removeEventListener(MouseEvent.MOUSE_OUT, onOut);
		});
	}

	public function hasKongHoverForTests():Bool {
		return hover != null;
	}

	private function clickLogout(confirmed:Bool = false):Void {
		if (needsTempModDemotionWarning() && !confirmed) {
			new ConfirmPopup(function():Void clickLogout(true), TEMP_MOD_LOGOUT_CONFIRM);
			return;
		}
		logOutSession(needsTempModDemotionWarning());
		if (pageHolder != null) {
			pageHolder.changePage(new LoginPage());
		}
	}

	private function clickLevelEditor(confirmed:Bool = false):Void {
		if (needsTempModDemotionWarning() && !confirmed) {
			new ConfirmPopup(function():Void clickLevelEditor(true), TEMP_MOD_EDITOR_CONFIRM);
			return;
		}
		var isMod = !LobbySession.isTempMod && !LobbySession.isTrialMod && LobbySession.group >= 2;
		if (needsTempModDemotionWarning()) {
			logOutSession(true);
		} else {
			LobbySocket.close();
		}
		if (pageHolder != null) {
			pageHolder.changePage(createLevelEditorPage(isMod));
		}
	}

	private function needsTempModDemotionWarning():Bool {
		return LobbySession.isTempMod && (LobbySession.server == null || LobbySession.server.guildId == 0);
	}

	private function logOutSession(showTempModMessage:Bool):Void {
		if (showTempModMessage) {
			new MessagePopup(TEMP_MOD_LOGGED_OUT_MESSAGE);
		}
		if (!LobbySession.remember) {
			logoutPostFactory(ServerConfig.logoutUrl(), new Map<String, String>());
		}
		LobbySession.clear();
		LobbySocket.close();
	}

	private static function defaultLogoutPost(url:String, fields:Map<String, String>):Void {
		FormPostClient.post(url, fields, function(_:String):Void {}, function(_:String):Void {});
	}

	private function clickKong():Void {
		#if js
		Browser.window.open("http://www.kongregate.com/games/jiggmin/platform-racing-2/?gamereferral=platformracing2", "_blank");
		#end
	}

	private function hoverKong(target:DisplayObject):Void {
		hoverOutKong();
		hover = new HoverPopup("Kong Hat", "Players from Kongregate automatically get a hat that doubles guild points won in each race!", target);
	}

	private function hoverOutKong():Void {
		if (hover != null) {
			hover.remove();
			hover = null;
		}
	}

	private function clickOptions():Void {
		LobbyPopups.lastRequest = "options";
		new pr2.lobby.dialogs.OptionsPopup();
		reportAction("options");
	}

	private function clickStore():Void {
		createStorePopup();
		reportAction("store");
	}

	private function clickCredits():Void {
		LobbyPopups.lastRequest = "credits";
		new pr2.lobby.dialogs.CreditsPopup();
		reportAction("credits");
	}

	private function reportAction(action:String):Void {
		#if js
		Browser.document.body.setAttribute("data-pr2-lobby-action", action);
		#end
	}

	private function reportState(state:String):Void {
		#if js
		Browser.document.body.setAttribute("data-pr2-page", state);
		#end
	}
}
