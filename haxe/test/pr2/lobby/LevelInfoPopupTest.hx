package pr2.lobby;

import openfl.display.InteractiveObject;
import openfl.events.MouseEvent;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.LevelInfoPopup;
import pr2.lobby.dialogs.LevelReportPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.net.ServerConfig;

/**
	Locks the first ported LevelInfoPopup boundary: level links open the authored
	shell, preserve the loading state, and no longer mutate `LobbyPopups.lastRequest`.
**/
class LevelInfoPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testLinkRouteOpensAuthoredShell();
		testApplyReturnDataPopulatesAuthoredFields();
		testMemberReportFlow();
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
		assertEquals(true, LobbyArt.findByName(popup, "loading").visible, "loading graphic remains visible");
		assertEquals(false, LobbyArt.findByName(popup, "levelInfo").visible, "data panel stays hidden until data port lands");
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
		assertEquals(false, LobbyArt.findByName(popup, "loading").visible, "loading graphic hides after data");
		assertEquals(true, LobbyArt.findByName(popup, "levelInfo").visible, "data panel shows after data");
		assertEquals("Hat Factory", LobbyArt.text(popup, "title").text, "title populates");
		assertEquals("Find the hidden hat.", LobbyArt.text(popup, "note").text, "note populates");
		assertEquals("12,345", LobbyArt.text(popup, "version").text, "version is comma-formatted");
		assertEquals("987,654", LobbyArt.text(popup, "plays").text, "plays is comma-formatted");
		assertEquals("15", LobbyArt.text(popup, "minRank").text, "min rank populates");
		assertEquals("15/Nov/2020", LobbyArt.text(popup, "updated").text, "updated uses Flash short date");
		assertEquals("Hat Attack", popup.gameMode, "game mode is normalized");
		assertEquals("Code - Stefano Maccarelli", popup.song, "song id is named");
		assertEquals(0.75, LobbyArt.findByName(popup, "bar").scaleX, "rating star bar scales");
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
		assertEquals(true, LobbyArt.findByName(popup, "report_bt").visible, "members see report button");
		assertEquals(false, LobbyArt.findByName(popup, "unpublish_bt").visible, "members do not see moderation button");
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
		var button = Std.downcast(LobbyArt.findByName(container, name), InteractiveObject);
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
