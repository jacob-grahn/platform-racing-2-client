package pr2.lobby;

import openfl.display.InteractiveObject;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IOErrorEvent;
import openfl.events.MouseEvent;
import openfl.net.URLRequest;
import openfl.net.URLVariables;
import pr2.lobby.dialogs.ChooseLevelModModePopup;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.LevelInfoPopup;
import pr2.lobby.dialogs.LevelReportPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.SendMessagePopup;
import pr2.net.ServerConfig;
import pr2.net.SuperLoader;
import pr2.util.DisplayUtil;

/**
	Locks the first ported LevelInfoPopup boundary: level links open the authored
	shell, preserve the loading state, and no longer mutate `LobbyPopups.lastRequest`.
**/
class LevelInfoPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testLinkRouteOpensAuthoredShell();
		testLoadFailureFadesPopup();
		testFlashDefaultsBeforeData();
		testApplyReturnDataPopulatesAuthoredFields();
		testRatingHoverShowsFlashCover();
		testLevelInfoHoverPopups();
		testActionButtonVisibilityShareAndTooltips();
		testPlayRoutesThroughLobbyLookup();
		testMemberReportFlow();
		testModeratorLevelModerationFlow();
		testSingletonFadeOut();
		closeAll();
		restoreHooks();
		trace('LevelInfoPopupTest passed $assertions assertions');
	}

	private static function testLinkRouteOpensAuthoredShell():Void {
		closeAll();
		ServerConfig.setHost("http://example.test");
		var fake = new FakeTransport();
		SuperLoader.transportFactory = function():Dynamic return fake;
		SuperLoader.nextRand = function():Int return 123;
		LobbySession.token = "level-token";
		LobbyPopups.lastRequest = "sentinel";
		LobbyPopups.showLevel("12345");
		var popup = Std.downcast(Popup.getOpen()[Popup.getOpen().length - 1], LevelInfoPopup);
		assertNotNull(popup, "showLevel opens LevelInfoPopup");
		assertEquals(12345, popup.levelId, "level id parsed");
		assertEquals("http://example.test/level_data.php", fake.loaded.url, "constructor requests level info endpoint");
		var vars:URLVariables = cast fake.loaded.data;
		assertEquals("12345", Std.string(Reflect.field(vars, "level_id")), "level info request includes level id");
		assertEquals("123", Std.string(Reflect.field(vars, "rand")), "level info request gets SuperLoader rand");
		assertEquals("level-token", Std.string(Reflect.field(vars, "token")), "level info request gets session token");
		assertEquals("sentinel", LobbyPopups.lastRequest, "level route is no longer record-only");
		assertEquals(true, DisplayUtil.findByName(popup, "loading").visible, "loading graphic remains visible");
		assertEquals(false, DisplayUtil.findByName(popup, "levelInfo").visible, "data panel stays hidden until data returns");
		fake.data = '{"success":true,"title":"Loaded","version":2,"play_count":3,"min_rank":4,"user_name":"Loader","user_group":"1","rating":2.5,"time":1605484800,"song":"0","gameMode":"race"}';
		fake.emit(new Event(Event.COMPLETE));
		assertEquals(false, DisplayUtil.findByName(popup, "loading").visible, "loading graphic hides after constructor data");
		assertEquals(true, DisplayUtil.findByName(popup, "levelInfo").visible, "constructor data shows panel");
		assertEquals("Loaded", popup.title, "constructor data applies");
		popup.remove();
	}

	private static function testLoadFailureFadesPopup():Void {
		closeAll();
		var fake = new FakeTransport();
		SuperLoader.transportFactory = function():Dynamic return fake;
		SuperLoader.showMessage = function(_:String):Void {};
		var popup = new LevelInfoPopup(8);
		fake.emit(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "timeout"));
		assertEquals(true, popup.fadeOutStarted, "load failure starts Flash close/fade behavior");
		popup.remove();
	}

	private static function testFlashDefaultsBeforeData():Void {
		closeAll();
		LevelInfoPopup.autoLoadOnCreate = false;
		var popup = new LevelInfoPopup(9);
		assertEquals(false, popup.live, "default live");
		assertEquals(true, popup.hasPass, "default has pass");
		assertEquals(0, popup.userId, "default user id");
		assertEquals(0, popup.time, "default time");
		assertEquals(1.0, popup.gravity, "default gravity");
		assertEquals(120, popup.maxTime, "default max time");
		assertEquals("Laser Gun`Mine`Lightning`Teleport`Super Jump`Jet Pack`Speed Burst`Sword`Ice Wave", popup.items, "default items");
		assertEquals("", popup.song, "default raw song before data");
		assertEquals("Race", popup.gameMode, "default display mode");
		assertEquals(5, popup.cowboyChance, "default cowboy chance");
		assertEquals("", popup.badHats, "default bad hats");
		popup.remove();
	}

	private static function testApplyReturnDataPopulatesAuthoredFields():Void {
		closeAll();
		LevelInfoPopup.autoLoadOnCreate = false;
		LobbySession.group = 0;
		var popup = new LevelInfoPopup(77);
		popup.applyReturnData({
			live: true,
			has_pass: false,
			user_id: 456,
			title: "Hat Factory",
			note: "Find the hidden hat.",
			version: 12345,
			play_count: 987654,
			min_rank: 15,
			user_name: "Jiggmin",
			user_group: "2,1",
			rating: 3.75,
			time: 1605484800,
			gravity: 0.85,
			max_time: 300,
			items: "Laser Gun`Mine",
			song: "2",
			gameMode: "hat",
			cowboyChance: 25,
			badHats: "2,14"
		});
		assertEquals(true, popup.live, "live flag stored");
		assertEquals(false, popup.hasPass, "password flag stored");
		assertEquals(456, popup.userId, "user id stored");
		assertEquals(0.85, popup.gravity, "gravity stored");
		assertEquals(300, popup.maxTime, "max time stored");
		assertEquals("Laser Gun`Mine", popup.items, "items string stored");
		assertEquals(25, popup.cowboyChance, "cowboy chance stored");
		assertEquals("2,14", popup.badHats, "bad hats string stored");
		assertEquals(false, DisplayUtil.findByName(popup, "loading").visible, "loading graphic hides after data");
		assertEquals(true, DisplayUtil.findByName(popup, "levelInfo").visible, "data panel shows after data");
		assertEquals("Hat Factory", LobbyArt.text(popup, "title").text, "title populates");
		assertEquals("Find the hidden hat.", LobbyArt.text(popup, "note").text, "note populates");
		assertEquals("12,345", LobbyArt.text(popup, "version").text, "version is comma-formatted");
		assertEquals("987,654", LobbyArt.text(popup, "plays").text, "plays is comma-formatted");
		assertEquals("15", LobbyArt.text(popup, "minRank").text, "min rank populates");
		assertEquals("15/Nov/2020", LobbyArt.text(popup, "updated").text, "updated uses Flash short date");
		assertEquals("Hat Attack", popup.gameMode, "game mode is normalized");
		assertEquals("Code - Stefano Maccarelli", popup.song, "song id is named");
		assertEquals(0.75, DisplayUtil.findByName(popup, "bar").scaleX, "rating star bar scales");
		assertEquals(false, DisplayUtil.findByName(popup, "share_bt").visible, "guests do not see share button");
		popup.remove();
	}

	private static function testRatingHoverShowsFlashCover():Void {
		closeAll();
		LevelInfoPopup.autoLoadOnCreate = false;
		var popup = new LevelInfoPopup(79);
		popup.applyReturnData({
			title: "Star Hover",
			version: 1,
			play_count: 0,
			min_rank: 0,
			user_name: "Player",
			user_group: "0",
			rating: 4.25,
			time: 1605484800,
			song: "0",
			gameMode: "race"
		});
		var rating = DisplayUtil.findByName(popup, "rating");
		var cover = DisplayUtil.findByName(Std.downcast(rating, openfl.display.DisplayObjectContainer), "cover");
		assertEquals(false, cover.visible, "rating cover starts hidden");
		rating.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals(true, cover.visible, "rating hover shows Flash cover");
		rating.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals(false, cover.visible, "rating mouseout hides Flash cover");
		popup.remove();
	}

	private static function testLevelInfoHoverPopups():Void {
		closeAll();
		LevelInfoPopup.autoLoadOnCreate = false;
		var popup = new LevelInfoPopup(80);
		popup.applyReturnData({
			title: "Hover Matrix",
			version: 1,
			play_count: 0,
			min_rank: 0,
			user_name: "Player",
			user_group: "0",
			rating: 4.25,
			time: 1605484800,
			gravity: 1.25,
			max_time: 125,
			items: "Laser Gun`Mine",
			song: "3",
			gameMode: "hat",
			cowboyChance: 30,
			badHats: "2,14"
		});

		var updated = LobbyArt.text(popup, "updated");
		dispatch(popup, "updated", MouseEvent.MOUSE_OVER);
		assertEquals(true, popup.hasActiveHover("updated"), "updated hover opens");
		assertEquals(0x666666, updated.textColor, "updated hover changes text color");
		dispatch(popup, "updated", MouseEvent.MOUSE_OUT);
		assertEquals(false, popup.hasActiveHover("updated"), "updated hover closes");
		assertEquals(0x000000, updated.textColor, "updated hover restores text color");

		assertHoverOpensAndCloses(popup, "gameMode", "game mode hover");
		assertHoverOpensAndCloses(popup, "song", "song hover");
		assertHoverOpensAndCloses(popup, "cowboyChance", "cowboy chance hover");
		assertHoverOpensAndCloses(popup, "maxTime", "max time hover");
		assertHoverOpensAndCloses(popup, "gravity", "gravity hover");
		assertHoverOpensAndCloses(popup, "items", "items menu hover");
		assertHoverOpensAndCloses(popup, "hatsAllowed", "hats menu hover");

		dispatch(popup, "items", MouseEvent.MOUSE_OVER);
		dispatch(popup, "hatsAllowed", MouseEvent.MOUSE_OVER);
		popup.remove();
		assertEquals(false, popup.hasActiveHover("items"), "remove closes item hover");
		assertEquals(false, popup.hasActiveHover("hatsAllowed"), "remove closes hat hover");
	}

	private static function testActionButtonVisibilityShareAndTooltips():Void {
		closeAll();
		LevelInfoPopup.autoLoadOnCreate = false;
		var scheduled:Void->Void = null;
		LevelInfoPopup.actionDelayFactory = function(callback:Void->Void, delayMs:Int):Null<haxe.Timer> {
			assertEquals(500, delayMs, "action hover uses Flash delay");
			scheduled = callback;
			return null;
		};
		LobbySession.group = 1;
		var popup = new LevelInfoPopup(81);
		popup.applyReturnData({
			title: "Share Target",
			version: 6,
			play_count: 0,
			min_rank: 0,
			user_name: "AuthorName",
			user_group: "0",
			rating: 0,
			time: 1605484800,
			song: "0",
			gameMode: "race"
		});
		assertEquals(true, DisplayUtil.findByName(popup, "share_bt").visible, "members see share button");
		assertEquals(true, DisplayUtil.findByName(popup, "report_bt").visible, "members see report button");
		assertEquals(false, DisplayUtil.findByName(popup, "unpublish_bt").visible, "members do not see moderation button");

		dispatch(popup, "share_bt", MouseEvent.MOUSE_OVER);
		assertEquals(false, popup.hasActiveActionHover(), "action hover waits for delay");
		scheduled();
		assertEquals(true, popup.hasActiveActionHover(), "delayed action hover opens");
		dispatch(popup, "share_bt", MouseEvent.MOUSE_OUT);
		assertEquals(false, popup.hasActiveActionHover(), "action hover closes on mouseout");

		click(popup, "share_bt");
		var message = lastPopup(SendMessagePopup);
		assertEquals("Hey, check out this level! \n\n[level=81]Share Target[/level] by [user]AuthorName[/user]", LobbyArt.text(message, "textBox").text,
			"share preloads Flash PM text");
		message.remove();

		dispatch(popup, "report_bt", MouseEvent.MOUSE_OVER);
		scheduled();
		assertEquals(true, popup.hasActiveActionHover(), "report action hover opens");
		popup.remove();
		assertEquals(false, popup.hasActiveActionHover(), "remove clears action hover");

		closeAll();
		LevelInfoPopup.autoLoadOnCreate = false;
		LobbySession.group = 2;
		popup = new LevelInfoPopup(82);
		popup.applyReturnData({
			title: "Mod Target",
			version: 1,
			play_count: 0,
			min_rank: 0,
			user_name: "AuthorName",
			user_group: "0",
			rating: 0,
			time: 1605484800,
			song: "0",
			gameMode: "race"
		});
		assertEquals(true, DisplayUtil.findByName(popup, "share_bt").visible, "moderators see share button");
		assertEquals(false, DisplayUtil.findByName(popup, "report_bt").visible, "moderators do not see report button");
		assertEquals(true, DisplayUtil.findByName(popup, "unpublish_bt").visible, "moderators see moderation button");
		popup.remove();
	}

	private static function testPlayRoutesThroughLobbyLookup():Void {
		closeAll();
		LevelInfoPopup.autoLoadOnCreate = false;
		var lookups:Array<String> = [];
		LevelInfoPopup.lookupLevelHandler = function(levelId:String):Void lookups.push(levelId);
		var popup = new LevelInfoPopup(83);
		click(popup, "play_bt");
		assertEquals(0, lookups.length, "play button is inert before level data applies");
		popup.applyReturnData({
			live: false,
			has_pass: true,
			title: "Lookup Me",
			version: 7,
			play_count: 0,
			min_rank: 99,
			user_name: "AuthorName",
			user_group: "0",
			rating: 0,
			time: 1605484800,
			song: "0",
			gameMode: "race"
		});
		dispatch(popup, "items", MouseEvent.MOUSE_OVER);
		assertEquals(true, popup.hasActiveHover("items"), "play test opens hover before click");
		click(popup, "play_bt");
		assertEquals("83", lookups.join(","), "play routes through lobby level lookup");
		assertEquals(false, popup.hasActiveHover("items"), "play closes pending hover popups");
		assertEquals(true, popup.fadeOutStarted, "play fades LevelInfoPopup");
		popup.remove();
	}

	private static function assertHoverOpensAndCloses(popup:LevelInfoPopup, targetName:String, message:String):Void {
		dispatch(popup, targetName, MouseEvent.MOUSE_OVER);
		assertEquals(true, popup.hasActiveHover(targetName), message + " opens");
		dispatch(popup, targetName, MouseEvent.MOUSE_OUT);
		assertEquals(false, popup.hasActiveHover(targetName), message + " closes");
	}

	private static function testMemberReportFlow():Void {
		closeAll();
		LevelInfoPopup.autoLoadOnCreate = false;
		LobbySession.group = 1;
		ServerConfig.setHost("http://example.test");
		var uploads:Array<UploadCall> = [];
		LevelReportPopup.uploadFactory = function(url:String, fields:Map<String, String>, label:String):pr2.lobby.dialogs.UploadingPopup {
			var captured = new Map<String, String>();
			for (key in fields.keys()) {
				captured.set(key, fields.get(key));
			}
			uploads.push({url: url, fields: captured, label: label});
			return null;
		};

		var popup = new LevelInfoPopup(88);
		popup.applyReturnData({
			title: "Bad Level",
			version: 42,
			play_count: 0,
			min_rank: 0,
			user_name: "Player",
			user_group: "1",
			rating: 0,
			time: 1605484800,
			song: "0",
			gameMode: "race"
		});
		assertEquals(true, DisplayUtil.findByName(popup, "report_bt").visible, "members see report button");
		assertEquals(false, DisplayUtil.findByName(popup, "unpublish_bt").visible, "members do not see moderation button");
		click(popup, "report_bt");

		var report = lastPopup(LevelReportPopup);
		assertEquals(88, report.levelId, "report popup receives level id");
		assertEquals(42, report.version, "report popup receives version");
		click(report, "report_bt");
		assertNotNull(lastPopup(MessagePopup), "blank report opens Flash error popup");

		var reason = LobbyArt.text(report, "reasonBox");
		reason.text = "Offensive text in the title";
		click(report, "report_bt");
		var confirm = lastPopup(ConfirmPopup);
		click(confirm, "ok_bt");
		assertEquals(true, popup.fadeOutStarted, "confirmed report fades level info");
		assertEquals(true, report.fadeOutStarted, "confirmed report fades report popup");
		assertEquals(1, uploads.length, "confirmed report uploads once");
		assertEquals("http://example.test/level_report.php", uploads[0].url, "report endpoint");
		assertEquals("88", uploads[0].fields.get("level_id"), "report level_id field");
		assertEquals("42", uploads[0].fields.get("version"), "report version field");
		assertEquals("Offensive text in the title", uploads[0].fields.get("reason"), "report reason field");
		assertEquals("Reporting level...", uploads[0].label, "report upload label");

		closeAll();
		restoreHooks();
	}

	private static function testModeratorLevelModerationFlow():Void {
		closeAll();
		LevelInfoPopup.autoLoadOnCreate = false;
		LobbySession.group = 2;
		ServerConfig.setHost("http://example.test");
		var uploads:Array<ModerateUploadCall> = [];
		var captureModerationUpload = function(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
				onError:String->Void):Null<pr2.lobby.dialogs.UploadingPopup> {
			var captured = new Map<String, String>();
			for (key in fields.keys()) {
				captured.set(key, fields.get(key));
			}
			uploads.push({url: url, fields: captured, label: label, onResult: onResult, onError: onError});
			return null;
		};
		ChooseLevelModModePopup.uploadFactory = captureModerationUpload;

		var popup = new LevelInfoPopup(91);
		popup.applyReturnData({
			title: "Moderate Me",
			version: 8,
			play_count: 0,
			min_rank: 0,
			user_name: "Player",
			user_group: "1",
			rating: 0,
			time: 1605484800,
			song: "0",
			gameMode: "race"
		});
		assertEquals(false, DisplayUtil.findByName(popup, "report_bt").visible, "moderators do not see report button");
		assertEquals(true, DisplayUtil.findByName(popup, "unpublish_bt").visible, "moderators see moderation button");
		click(popup, "unpublish_bt");

		var modPopup = lastPopup(ChooseLevelModModePopup);
		assertEquals(91, modPopup.levelId, "moderation popup receives level id");
		click(modPopup, "unpublish_bt");
		var confirm = lastPopup(ConfirmPopup);
		click(confirm, "ok_bt");
		assertEquals(1, uploads.length, "unpublish uploads once after confirmation");
		assertEquals("http://example.test/level_moderate.php", uploads[0].url, "moderation endpoint");
		assertEquals("91", uploads[0].fields.get("level_id"), "moderation level_id field");
		assertEquals("unpublish", uploads[0].fields.get("action"), "moderation action field");
		assertEquals("Unpublishing level...", uploads[0].label, "unpublish upload label");
		uploads[0].onResult({success: true});
		assertEquals(true, popup.fadeOutStarted, "successful moderation fades level info");
		assertEquals(true, modPopup.fadeOutStarted, "successful moderation fades moderation popup");

		closeAll();
		LobbySession.group = 2;
		ChooseLevelModModePopup.uploadFactory = captureModerationUpload;
		var restrictPopup = new ChooseLevelModModePopup(92);
		click(restrictPopup, "restrict_bt");
		click(lastPopup(ConfirmPopup), "ok_bt");
		assertEquals(2, uploads.length, "restrict uploads once after confirmation");
		assertEquals("92", uploads[1].fields.get("level_id"), "restrict level_id field");
		assertEquals("restrict", uploads[1].fields.get("action"), "restrict action field");
		assertEquals("Restricting level...", uploads[1].label, "restrict upload label");
		uploads[1].onResult({success: false, error: "Moderation failed."});
		var responseError = lastPopup(MessagePopup);
		assertNotNull(responseError, "failed moderation response shows error message");
		assertEquals(true, LobbyArt.text(responseError, "textBox").htmlText.indexOf("Error: Moderation failed.") >= 0,
			"failed moderation response includes server error");
		responseError.remove();
		uploads[1].onError("Transport failed.");
		var transportError = lastPopup(MessagePopup);
		assertNotNull(transportError, "failed moderation upload shows error message");
		assertEquals(true, LobbyArt.text(transportError, "textBox").htmlText.indexOf("Error: Transport failed.") >= 0,
			"failed moderation upload includes transport error");

		closeAll();
		restoreHooks();
	}

	private static function testSingletonFadeOut():Void {
		closeAll();
		LevelInfoPopup.autoLoadOnCreate = false;
		var first = new LevelInfoPopup(1);
		var second = new LevelInfoPopup(2);
		assertEquals(true, first.fadeOutStarted, "opening another level info popup fades the previous instance");
		assertEquals(second, LevelInfoPopup.instance, "new popup becomes singleton instance");
		second.remove();
		first.remove();
	}

	private static function closeAll():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
		LobbySession.group = 0;
		restoreHooks();
	}

	private static function restoreHooks():Void {
		LevelReportPopup.uploadFactory = LevelReportPopup.defaultUpload;
		ChooseLevelModModePopup.uploadFactory = ChooseLevelModModePopup.defaultUpload;
		LevelInfoPopup.autoLoadOnCreate = true;
		LevelInfoPopup.actionDelayFactory = function(callback:Void->Void, delayMs:Int):Null<haxe.Timer> return haxe.Timer.delay(callback, delayMs);
		LevelInfoPopup.lookupLevelHandler = null;
		SuperLoader.resetHooks();
		LobbySession.token = "";
		ServerConfig.resetHost();
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) throw message;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function click(container:openfl.display.DisplayObjectContainer, name:String):Void {
		var button = Std.downcast(DisplayUtil.findByName(container, name), InteractiveObject);
		if (button == null) {
			throw 'missing button $name';
		}
		button.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	}

	private static function dispatch(container:openfl.display.DisplayObjectContainer, name:String, type:String):Void {
		var target = DisplayUtil.findByName(container, name);
		if (target == null) {
			throw 'missing hover target $name';
		}
		target.dispatchEvent(new MouseEvent(type));
	}

	private static function lastPopup<T:Popup>(type:Class<T>):T {
		for (i in 0...Popup.getOpen().length) {
			var popup = Popup.getOpen()[Popup.getOpen().length - 1 - i];
			var typed = Std.downcast(popup, type);
			if (typed != null) {
				return typed;
			}
		}
		throw 'expected open ${Type.getClassName(type)}';
	}
}

private class FakeTransport extends EventDispatcher {
	public var data:Dynamic = null;
	public var dataFormat:Dynamic = null;
	public var loaded:URLRequest = null;
	public var closed:Bool = false;

	public function new() {
		super();
	}

	public function load(request:URLRequest):Void {
		loaded = request;
	}

	public function close():Void {
		closed = true;
	}

	public function emit(event:Event):Void {
		dispatchEvent(event);
	}
}

private typedef UploadCall = {
	var url:String;
	var fields:Map<String, String>;
	var label:String;
}

private typedef ModerateUploadCall = {
	var url:String;
	var fields:Map<String, String>;
	var label:String;
	var onResult:Dynamic->Void;
	var onError:String->Void;
}
