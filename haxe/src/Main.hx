package;

import com.jiggmin.data.SWFStats;
import haxe.Timer;
import haxe.Json;
#if js
import js.Browser;
#end
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.geom.Point;
import pr2.Constants;
import pr2.app.FatalErrorReporter;
import pr2.app.QueryParams;
import pr2.app.Screen;
import pr2.app.SiteMode;
import pr2.audio.BrowserAudioUnlock;
import pr2.audio.AudioManager;
import pr2.net.ServerConfig;
import pr2.net.CommAuth;
import pr2.net.SavedAccounts;
import pr2.net.CampaignLevelInfo;
import pr2.net.LevelListClient.LevelListResult;
import pr2.lobby.tabs.ListingTab;
import pr2.lobby.tabs.SearchTab;
import pr2.page.CampaignTestScreen;
import pr2.page.CustomizeCharacterScreen;
import pr2.page.IntroPage;
import pr2.page.LoginPage;
import pr2.page.MobileLobbyPage;
import pr2.page.PageHolder;
import pr2.page.SymbolPreview;
import pr2.page.PopupPreview;
import pr2.ui.GpNotification;
import pr2.ui.MuteButton;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

/**
	Application entry point. Boots into a screen selected by the `?screen=`
	query flag (default `intro`), which lets development and the OpenFL test
	harness jump straight to any screen.
**/
class Main extends Sprite {
	private static inline var OFFLINE_LIST_DELAY_MS:Int = 20;

	private var swfStats:Null<SWFStats>;

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
		pr2.app.AppStage.stage = stage;
		swfStats = new SWFStats();
		FatalErrorReporter.installGlobalHandlers();
		GpNotification.init(stage);
		BrowserAudioUnlock.install();
		AudioManager.install(this);

		try {
			var query = currentQuery();
			// pr2hub.com sends no CORS headers; `?apiHost=/api` points level
			// fetches at a same-origin dev proxy (tools/dev_proxy.py). On
			// sys targets, PR2_API_HOST can provide the same local override.
			ServerConfig.applyLocalOverrides();
			ServerConfig.setHost(QueryParams.get(query, "apiHost"));
			SavedAccounts.init();
			CommAuth.init();
			var siteMode = resolveSiteMode(query);
			var screen = Screen.fromQuery(query);
			addChild(buildScreen(screen, query, siteMode));
			addGlobalChrome(screen, query);
			signalAppReady(screen);
			#if pr2_leak_probe
			installLeakProbe();
			#end
		} catch (error:Dynamic) {
			reportFatalError(error);
		}
	}

	// Screen-independent boot signal for the OpenFL driver/harness. Once `Main`
	// is running past the OpenFL preloader and the initial screen is on the
	// display list, automated sequences can safely dispatch input; clicks/keys
	// sent earlier hit the preloader, not the game, and are silently dropped.
	// Sequences gate their first step on this attribute instead of guessing a
	// fixed preload time (see tools/openfl_driver.py).
	private function signalAppReady(screen:Screen):Void {
		#if js
		Browser.document.body.setAttribute("data-pr2-screen", screen);
		Browser.document.body.setAttribute("data-pr2-app-ready", "1");
		// Expose the live stage so automated harnesses can hit-test the display
		// list for authored buttons whose on-stage position is hard to predict
		// from the symbol registration point (e.g. the in-race Quit button).
		untyped Browser.window.__pr2Stage = stage;
		untyped Browser.window.__pr2DisplayBoundsForTests = function(name:String, index:Int = 0):String {
			return displayBoundsForTests(name, index);
		};
		#end
	}

	private function displayBoundsForTests(name:String, index:Int):String {
		var matches:Array<DisplayObject> = [];
		collectNamedDisplayObjects(stage, name, matches);
		if (index < 0 || index >= matches.length) {
			return Json.stringify({ok: false, count: matches.length});
		}
		var target = matches[index];
		var bounds = target.getBounds(target);
		var center = StringTools.endsWith(name, "Entry")
			? target.localToGlobal(new Point(15, 15))
			: target.localToGlobal(new Point(bounds.left + bounds.width / 2, bounds.top + bounds.height / 2));
		return Json.stringify({
			ok: true,
			count: matches.length,
			x: center.x - (StringTools.endsWith(name, "Entry") ? 15 : bounds.width / 2),
			y: center.y - (StringTools.endsWith(name, "Entry") ? 15 : bounds.height / 2),
			width: StringTools.endsWith(name, "Entry") ? 30 : bounds.width,
			height: StringTools.endsWith(name, "Entry") ? 30 : bounds.height
		});
	}

	private function collectNamedDisplayObjects(node:DisplayObject, name:String, matches:Array<DisplayObject>):Void {
		if (node == null || !node.visible) {
			return;
		}
		if (node.name == name) {
			matches.push(node);
		}
		var container = Std.downcast(node, DisplayObjectContainer);
		if (container == null) {
			return;
		}
		for (i in 0...container.numChildren) {
			collectNamedDisplayObjects(container.getChildAt(i), name, matches);
		}
	}

	// Leak/perf probe (only compiled in with `-Dpr2_leak_probe`): exposes a global
	// to inject server frames (e.g. chat) from the CDP profiler in tools/, so a
	// long idle chat session can be driven without a live server.
	#if pr2_leak_probe
	private function installLeakProbe():Void {
		#if js
		untyped Browser.window.__pr2InjectFrame = function(frame:String):Void {
			pr2.net.CommandHandler.commandHandler.handleServerFrame(frame);
		};
		#end
	}
	#end

	// The mute toggle lives at the document root in the Flash original
	// (`Main.muteButton`), so it stays on screen across every page. It is added
	// on top of the active screen at the Flash coordinates (x=504, y=380). The
	// pure dev tooling screens (symbol preview / customize / popup preview) are
	// not part of the real game chrome and would corrupt visual diffs, so they
	// skip it.
	private function addGlobalChrome(screen:Screen, query:Null<String>):Void {
		if (screen == Lobby && mobileLobbyRequested(query)) {
			return;
		}
		switch (screen) {
			case Login | Lobby | Intro | Campaign:
				var muteButton = new MuteButton();
				muteButton.x = 504;
				muteButton.y = 380;
				addChild(muteButton);
			default:
		}
	}

	private function reportFatalError(error:Dynamic):Void {
		FatalErrorReporter.report(error);
	}

	private function currentQuery():Null<String> {
		#if js
		return Browser.location.search;
		#else
		return null;
		#end
	}

	private function resolveSiteMode(query:Null<String>):String {
		var siteModeOverride = QueryParams.get(query, "siteMode");
		if (siteModeOverride != null && siteModeOverride != "") {
			return SiteMode.fromDomain(siteModeOverride);
		}
		#if js
		return SiteMode.fromUrl(Browser.location.href);
		#else
		return SiteMode.KONGREGATE;
		#end
	}

	private function buildScreen(screen:Screen, query:Null<String>, siteMode:String):DisplayObject {
		return switch (screen) {
			case Campaign: new CampaignTestScreen(
				QueryParams.get(query, "page"),
				campaignLevelQuery(query),
				campaignLevelVersionQuery(query),
				QueryParams.get(query, "localLevel")
			);
			case Login: new PageHolder(new LoginPage(siteMode), true);
			case Lobby: buildLobby(query);
			case Intro: new PageHolder(new IntroPage(siteMode, QueryParams.get(query, "intro")), true);
			case Symbol: new SymbolPreview(
				QueryParams.get(query, "symbol"),
				parseScale(QueryParams.get(query, "scale")),
				parseColor(QueryParams.get(query, "bg"))
			);
			case CustomizeCharacter: new CustomizeCharacterScreen();
			case PopupPreview: new PopupPreview(QueryParams.get(query, "popup"));
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
		if (QueryParams.get(query, "offlineLists") == "1") {
			installOfflineLobbyListFixtures();
		}
		pr2.lobby.LobbySession.begin(userName, guest ? 0 : 1);
		var mobile = mobileLobbyRequested(query);
		var holder = new PageHolder(mobile ? new MobileLobbyPage(userName) : new pr2.page.LobbyPage(userName), true);
		#if js
		// Runtime parity sequences rebuild the lobby in-place to verify that the
		// static TabsHolder selection memory survives a real page teardown.
		untyped Browser.window.__pr2RebuildLobby = function():Void {
			holder.changePage(mobile ? new MobileLobbyPage(userName) : new pr2.page.LobbyPage(userName));
		};
		#end
		return holder;
	}

	private static function mobileLobbyRequested(query:Null<String>):Bool {
		var value = QueryParams.get(query, "mobile");
		return value == "1" || value == "true" || value == "lobby"
			#if pr2_mobile_ui
				|| true
			#end
		;
	}

	private function installOfflineLobbyListFixtures():Void {
		ListingTab.fetchFactory = function(mode:String, page:Int, onResult:LevelListResult->Void, onError:String->Void) {
			return delayedOfflineLevelResult(offlineLevels(mode, page), onResult);
		};
		ListingTab.fetchFavoritesFactory = function(userId:Int, page:Int, token:String, onResult:LevelListResult->Void, onError:String->Void) {
			return delayedOfflineLevelResult(offlineLevels("favorites", page), onResult);
		};
		SearchTab.searchFactory = function(params:Map<String, String>, onResult:LevelListResult->Void, onError:String->Void) {
			return delayedOfflineLevelResult(offlineLevels("search", 1), onResult);
		};
	}

	private static function delayedOfflineLevelResult(levels:Array<CampaignLevelInfo>, onResult:LevelListResult->Void):AsyncRemovable {
		var cancelled = false;
		var timer = Timer.delay(function():Void {
			if (!cancelled) {
				onResult(new LevelListResult(levels, true));
			}
		}, OFFLINE_LIST_DELAY_MS);
		return {
			remove: function():Void {
				cancelled = true;
				timer.stop();
			}
		};
	}

	private static function offlineLevels(mode:String, page:Int):Array<CampaignLevelInfo> {
		var label = mode == null || mode == "" ? "Level" : mode;
		return [
			new CampaignLevelInfo(1000 + page * 10, 1, '$label Test 1', "Tester", 0, 4.2, 120),
			new CampaignLevelInfo(1001 + page * 10, 1, '$label Test 2', "Jiggmin", 3, 3.8, 98),
			new CampaignLevelInfo(1002 + page * 10, 1, '$label Test 3', "Guest", 0, 5.0, 42)
		];
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

	private function campaignLevelVersionQuery(query:Null<String>):Null<Int> {
		var version = QueryParams.get(query, "version");
		if (version == null) {
			return null;
		}
		var parsed = Std.parseInt(StringTools.trim(version));
		return parsed == null || parsed < 1 ? null : parsed;
	}
}
