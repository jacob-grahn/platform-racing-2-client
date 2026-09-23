package pr2.page;

#if js
import js.Browser;
#end
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.StageQuality;
import openfl.events.MouseEvent;
import pr2.app.AppStage;
import pr2.app.ScreenFactory;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyLeft;
import pr2.lobby.LobbyBottomButtonsView;
import pr2.lobby.LobbyBackgroundView;
import pr2.lobby.LobbyPopups;
import pr2.lobby.LobbyRight;
import pr2.lobby.LobbySession;
import pr2.net.FormPostClient;
import pr2.net.LobbySocket;
import pr2.net.ServerInfo;
import pr2.net.ServerConfig;
import pr2.audio.AudioManager;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.HoverPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.store.StorePopup;
import pr2.levelEditor.LevelEditor;
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
	public static var createStorePopup:Void->Void = function():Void { new StorePopup(); };
	public static var createLevelEditorPage(get, set):Bool->Page;
	private static function get_createLevelEditorPage():Bool->Page return pr2.lobby.LobbyActions.createLevelEditorPage;
	private static function set_createLevelEditorPage(value:Bool->Page):Bool->Page return pr2.lobby.LobbyActions.createLevelEditorPage = value;
	public static var createLoginPage(get, set):Void->Page;
	private static function get_createLoginPage():Void->Page return pr2.lobby.LobbyActions.createLoginPage;
	private static function set_createLoginPage(value:Void->Page):Void->Page return pr2.lobby.LobbyActions.createLoginPage = value;
	public static var logoutPostFactory(get, set):LobbyLogoutPostFactory;
	private static function get_logoutPostFactory():LobbyLogoutPostFactory return pr2.lobby.LobbyActions.logoutPostFactory;
	private static function set_logoutPostFactory(value:LobbyLogoutPostFactory):LobbyLogoutPostFactory return pr2.lobby.LobbyActions.logoutPostFactory = value;
	private var actions:pr2.lobby.LobbyActions;

	private var background:Null<LobbyBackgroundView>;
	private var left:Null<LobbyLeft>;
	private var right:Null<LobbyRight>;
	private var bottom:Null<LobbyBottomButtonsView>;
	private var bindings:Array<Binding> = [];
	private var hoverCleanups:Array<Void->Void> = [];
	private var hover:Null<HoverPopup>;

	public function new(?userName:String, ?server:ServerInfo) {
		super();
		actions = new pr2.lobby.LobbyActions(function(page) { if (pageHolder != null) pageHolder.changePage(page); },
			function(message, proceed) { new ConfirmPopup(proceed, message); }, function(message) { new MessagePopup(message); });
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
		background = new LobbyBackgroundView();
		addChild(background);

		left = new LobbyLeft();
		addChild(left);

		right = new LobbyRight();
		addChild(right);

		bottom = new LobbyBottomButtonsView(LobbySession.isMember());
		bind(bottom, "logoutButton", function():Void clickLogout());
		bind(bottom, "levelEditorButton", function():Void clickLevelEditor());
		bind(bottom, "moreGamesButton", clickKong);
		bind(bottom, "optionsButton", clickOptions);
		bind(bottom, "vaultButton", clickStore);
		bind(bottom, "creditsButton", clickCredits);
		bindHover(bottom, "moreGamesButton", hoverKong, hoverOutKong);
		addChild(bottom);
		installBrowserHarness();

		reportState('lobby:${LobbySession.userName}');
	}

	override public function remove():Void {
		actions.remove();
		clearBrowserHarness();
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

	private function bind(art:DisplayObjectContainer, name:String, handler:Void->Void):Void {
		var binding = LobbyArt.bind(DisplayUtil.directChildByName(art, name), handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	private function bindHover(art:DisplayObjectContainer, name:String, over:DisplayObject->Void, out:Void->Void):Void {
		var target = DisplayUtil.directChildByName(art, name);
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

	private function clickLogout(confirmed:Bool = false):Void actions.logout(confirmed);
	private function clickLevelEditor(confirmed:Bool = false):Void actions.editor(confirmed);

	private function installBrowserHarness():Void {
		#if js
		var self = this;
		untyped Browser.window.__pr2OpenLevelEditorForTests = function():Void {
			self.clickLevelEditor();
		};
		#end
	}

	private function clearBrowserHarness():Void {
		#if js
		untyped Browser.window.__pr2OpenLevelEditorForTests = null;
		#end
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
		ScreenFactory.credits();
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
