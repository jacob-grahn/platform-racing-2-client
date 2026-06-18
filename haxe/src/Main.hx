package;

#if js
import js.Browser;
#end
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import pr2.Constants;
import pr2.app.QueryParams;
import pr2.app.Screen;
import pr2.net.ServerConfig;
import pr2.harness.GameplayHarness;
import pr2.page.CampaignTestScreen;
import pr2.page.IntroPage;
import pr2.page.LoginPage;
import pr2.page.PageHolder;
import pr2.page.SymbolPreview;

/**
	Application entry point. Boots into a screen selected by the `?screen=`
	query flag (default `intro`), which lets development and the OpenFL test
	harness jump straight to any screen.
**/
class Main extends Sprite {
	public function new() {
		super();

		if (stage != null) {
			init();
		} else {
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?event:Event):Void {
		removeEventListener(Event.ADDED_TO_STAGE, init);

		stage.frameRate = Constants.FRAME_RATE;
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;

		try {
			var query = currentQuery();
			// pr2hub.com sends no CORS headers; `?apiHost=/api` points level
			// fetches at a same-origin dev proxy (tools/dev_proxy.py). On
			// sys targets, PR2_API_HOST can provide the same local override.
			ServerConfig.applyLocalOverrides();
			ServerConfig.setHost(QueryParams.get(query, "apiHost"));
			addChild(buildScreen(Screen.fromQuery(query), query));
		} catch (error:Dynamic) {
			reportFatalError(error);
		}
	}

	private function reportFatalError(error:Dynamic):Void {
		var message = Std.string(error);
		trace("Fatal error: " + message);
		#if js
		Browser.console.error(error);
		Browser.document.body.setAttribute("data-pr2-error", message);
		#end
	}

	private function currentQuery():Null<String> {
		#if js
		return Browser.location.search;
		#else
		return null;
		#end
	}

	private function buildScreen(screen:Screen, query:Null<String>):DisplayObject {
		return switch (screen) {
			case Harness: new GameplayHarness();
			case Campaign: new CampaignTestScreen(
				QueryParams.get(query, "page"),
				campaignLevelQuery(query)
			);
			case Login: new PageHolder(new LoginPage());
			case Lobby: buildLobby(query);
			case Intro: new PageHolder(new IntroPage(null, QueryParams.get(query, "intro")));
			case Symbol: new SymbolPreview(
				QueryParams.get(query, "symbol"),
				parseScale(QueryParams.get(query, "scale")),
				parseColor(QueryParams.get(query, "bg"))
			);
		};
	}

	// Boots straight into the lobby for development/automated coverage. `?guest=1`
	// shows the guest lobby; otherwise a member session is seeded so the
	// member-only tabs (PMs/Account/Favorites) appear. `?user=` sets the name.
	private function buildLobby(query:Null<String>):DisplayObject {
		var guest = QueryParams.get(query, "guest") == "1";
		var userName = QueryParams.get(query, "user");
		if (userName == null) {
			userName = guest ? "Guest" : "Tester";
		}
		pr2.lobby.LobbySession.begin(userName, guest ? 0 : 1);
		return new PageHolder(new pr2.page.LobbyPage(userName));
	}

	private function parseScale(value:Null<String>):Float {
		if (value == null) {
			return 4;
		}
		var parsed = Std.parseFloat(value);
		return Math.isNaN(parsed) || parsed <= 0 ? 4 : parsed;
	}

	private function parseColor(value:Null<String>):Int {
		if (value == null) {
			return 0xFFFFFF;
		}
		var parsed = Std.parseInt("0x" + StringTools.replace(value, "#", ""));
		return parsed == null ? 0xFFFFFF : parsed;
	}

	private function campaignLevelQuery(query:Null<String>):Null<String> {
		var levelId = QueryParams.get(query, "levelId");
		return levelId != null ? levelId : QueryParams.get(query, "level");
	}
}
