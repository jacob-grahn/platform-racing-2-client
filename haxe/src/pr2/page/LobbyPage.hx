package pr2.page;

#if js
import js.Browser;
#end
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyLeft;
import pr2.lobby.LobbyPopups;
import pr2.lobby.LobbyRight;
import pr2.lobby.LobbySession;
import pr2.net.LobbySocket;
import pr2.net.ServerInfo;
import pr2.runtime.PR2MovieClip;
import pr2.audio.AudioManager;
import pr2.lobby.store.StorePopup;

/**
	Port of Flash `lobby.Lobby`: the post-login lobby shell.

	Lays out the `LobbyGraphic` background, the left pane (`LobbyLeft`), the right
	pane (`LobbyRight`), and the `LobbyBottomButtonsGraphic` button strip. The
	bottom strip shows the Kongregate variant for members and the sponsored
	variant for guests, and wires logout, level-editor entry, more-games,
	options, vault/store, and credits to their Flash-equivalent actions.
**/
class LobbyPage extends Page {
	public static var createStorePopup:Void->Void = function():Void {
		new StorePopup();
	};
	public static var createLevelEditorPage:Bool->Page = function(isMod:Bool):Page {
		return new LevelEditor(null, isMod);
	};

	private var background:Null<PR2MovieClip>;
	private var left:Null<LobbyLeft>;
	private var right:Null<LobbyRight>;
	private var bottom:Null<PR2MovieClip>;
	private var bindings:Array<Binding> = [];

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
		background = PR2MovieClip.fromLinkage("LobbyGraphic", {maxNestedDepth: 8});
		addChild(background);

		left = new LobbyLeft();
		addChild(left);

		right = new LobbyRight();
		addChild(right);

		bottom = PR2MovieClip.fromLinkage("LobbyBottomButtonsGraphic", {maxNestedDepth: 8});
		bottom.gotoAndStop(LobbySession.isMember() ? "kongregateSite" : "sponsoredSite");
		bind(bottom, "logoutButton", clickLogout);
		bind(bottom, "levelEditorButton", clickLevelEditor);
		bind(bottom, "moreGamesButton", clickKong);
		bind(bottom, "optionsButton", clickOptions);
		bind(bottom, "vaultButton", clickStore);
		bind(bottom, "creditsButton", clickCredits);
		addChild(bottom);

		reportState('lobby:${LobbySession.userName}');
	}

	override public function remove():Void {
		AudioManager.leaveMenu();
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
		var binding = LobbyArt.bind(LobbyArt.findByName(art, name), handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	private function clickLogout():Void {
		LobbySession.clear();
		LobbySocket.close();
		if (pageHolder != null) {
			pageHolder.changePage(new LoginPage());
		}
	}

	private function clickLevelEditor():Void {
		var isMod = !LobbySession.isTempMod && !LobbySession.isTrialMod && LobbySession.group >= 2;
		if (pageHolder != null) {
			pageHolder.changePage(createLevelEditorPage(isMod));
		}
		LobbySocket.close();
	}

	private function clickKong():Void {
		#if js
		Browser.window.open("http://www.kongregate.com/games/jiggmin/platform-racing-2/?gamereferral=platformracing2", "_blank");
		#end
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
