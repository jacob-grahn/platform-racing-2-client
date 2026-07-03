package pr2.lobby;

import openfl.display.InteractiveObject;
import openfl.events.MouseEvent;
import pr2.lobby.dialogs.ChooseLevelModModePopup;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.LevelInfoPopup;
import pr2.lobby.dialogs.LevelReportPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.net.ServerConfig;
import pr2.util.DisplayUtil;

/**
	Locks the first ported LevelInfoPopup boundary: level links open the authored
	shell, preserve the loading state, and no longer mutate `LobbyPopups.lastRequest`.
**/
class LevelInfoPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testLinkRouteOpensAuthoredShell();
		testApplyReturnDataPopulatesAuthoredFields();
		testRatingHoverShowsFlashCover();
		testMemberReportFlow();
		testModeratorLevelModerationFlow();
		testSingletonFadeOut();
		closeAll();
		restoreHooks();
		trace('LevelInfoPopupTest passed $assertions assertions');
	}

	private static function testLinkRouteOpensAuthoredShell():Void {
		closeAll();
		LobbyPopups.lastRequest = "sentinel";
		LobbyPopups.showLevel("12345");
		var popup = Std.downcast(Popup.getOpen()[Popup.getOpen().length - 1], LevelInfoPopup);
		assertNotNull(popup, "showLevel opens LevelInfoPopup");
		assertEquals(12345, popup.levelId, "level id parsed");
		assertEquals("sentinel", LobbyPopups.lastRequest, "level route is no longer record-only");
		assertEquals(true, DisplayUtil.findByName(popup, "loading").visible, "loading graphic remains visible");
		assertEquals(false, DisplayUtil.findByName(popup, "levelInfo").visible, "data panel stays hidden until data port lands");
		popup.remove();
	}

	private static function testApplyReturnDataPopulatesAuthoredFields():Void {
		closeAll();
		LobbySession.group = 0;
		var popup = new LevelInfoPopup(77);
		popup.applyReturnData({
			title: "Hat Factory",
			note: "Find the hidden hat.",
			version: 12345,
			play_count: 987654,
			min_rank: 15,
			user_name: "Jiggmin",
			user_group: "2,1",
			rating: 3.75,
			time: 1605484800,
			song: "2",
			gameMode: "hat"
		});
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
		popup.remove();
	}

	private static function testRatingHoverShowsFlashCover():Void {
		closeAll();
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

	private static function testMemberReportFlow():Void {
		closeAll();
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
		uploads[1].onError("Moderation failed.");
		assertNotNull(lastPopup(MessagePopup), "failed moderation upload shows error message");

		closeAll();
		restoreHooks();
	}

	private static function testSingletonFadeOut():Void {
		closeAll();
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
