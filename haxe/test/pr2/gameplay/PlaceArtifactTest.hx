package pr2.gameplay;

import openfl.display.InteractiveObject;
import openfl.events.Event;
import openfl.events.MouseEvent;
import pr2.gameplay.SpecialEvent.PlaceArtifactRequest;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.Popup;
import pr2.util.TestDisplayUtil as DisplayUtil;

class PlaceArtifactTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testInitialTimeSelection();
		if (pr2.DeterministicTestMode.finishSmokeSuite("PlaceArtifactTest")) return;
		testVariableMonthLengths();
		testTextValidationAndSetTime();
		testPlaceNowDisablesDateControls();
		testPlaceConfirmationUploadsFields();
		testScheduledResponsePromptsOverrideUpload();
		closeAll();
		trace('PlaceArtifactTest passed $assertions assertions');
	}

	private static function testInitialTimeSelection():Void {
		var popup = popupAt(new Date(2026, 5, 7, 0, 4, 0));
		assertEquals("assets/svg/effects/place_artifact_01.svg", PlaceArtifact.BACKGROUND_ASSET,
			"artifact popup uses exact authored XFL background and copy");
		@:privateAccess assertEquals(true, popup.art.exactBackground.width > 200,
			"authored artifact popup art renders");
		assertNear(-37.5, popup.monthSel.x, 0.001, "month selector preserves authored x");
		assertNear(-109.5, popup.daySel.x, 0.001, "day selector preserves authored x");
		assertNear(44.5, popup.yearSel.x, 0.001, "year selector preserves authored x");
		assertNear(-62.5, popup.hourBox.x, 0.001, "hour input preserves authored x");
		assertEquals("0-9", popup.hourBox.restrict, "hour input preserves numeric restriction");
		assertEquals("Place Now", popup.nowCheck.label, "checkbox preserves authored label");
		assertEquals(5, popup.monthSel.selectedIndex, "initial month selected from current date");
		assertEquals(6, popup.daySel.selectedIndex, "initial day selected from current date");
		assertEquals("12", popup.hourBox.text, "midnight displays as 12");
		assertEquals("04", popup.minBox.text, "initial minute is zero padded");
		assertEquals(0, popup.meridSel.selectedIndex, "midnight selects AM");
		popup.remove();
	}

	private static function testVariableMonthLengths():Void {
		var popup = popupAt(new Date(2026, 0, 31, 13, 5, 0));
		popup.monthSel.selectedIndex = 1;
		popup.yearSel.selectedIndex = 0;
		popup.populateOptions();
		assertEquals(28, popup.daySel.length, "non-leap February has 28 days");

		popup.yearSel.removeAll();
		popup.yearSel.addItem({label: 2028, data: 2028});
		popup.yearSel.selectedIndex = 0;
		popup.populateOptions();
		assertEquals(29, popup.daySel.length, "leap February has 29 days");

		popup.monthSel.selectedIndex = 8;
		popup.populateOptions();
		assertEquals(30, popup.daySel.length, "September has 30 days");
		popup.monthSel.selectedIndex = 11;
		popup.populateOptions();
		assertEquals(31, popup.daySel.length, "December has 31 days");
		popup.remove();
	}

	private static function testTextValidationAndSetTime():Void {
		var popup = popupAt(new Date(2026, 5, 7, 13, 5, 0));
		popup.hourBox.text = "99";
		popup.minBox.text = "-2";
		popup.validateText();
		assertEquals("12", popup.hourBox.text, "hour clamps high to 12");
		assertEquals("00", popup.minBox.text, "minute clamps low to 00");

		popup.monthSel.selectedIndex = 5;
		popup.daySel.selectedIndex = 6;
		popup.yearSel.selectedIndex = 0;
		popup.hourBox.text = "1";
		popup.minBox.text = "05";
		popup.meridSel.selectedIndex = 1;
		var selected = popup.selectedSetTime(0);
		assertEquals(Std.int(new Date(2026, 5, 7, 13, 5, 0).getTime() / 1000), selected, "PM input converts to scheduled timestamp");
		assertEquals(0, popup.selectedSetTime(selected + 1), "past selected time becomes immediate placement");
		popup.remove();
	}

	private static function testPlaceNowDisablesDateControls():Void {
		var popup = popupAt(new Date(2026, 5, 7, 13, 5, 0));
		popup.nowCheck.selected = true;
		popup.checkNowBox(new Event(Event.CHANGE));
		assertEquals(false, popup.monthSel.enabled, "now checkbox disables month");
		assertEquals(false, popup.daySel.enabled, "now checkbox disables day");
		assertEquals(false, popup.yearSel.enabled, "now checkbox disables year");
		assertEquals(false, popup.hourBox.enabled, "now checkbox disables hour");
		assertEquals(false, popup.minBox.enabled, "now checkbox disables minute");
		assertEquals(false, popup.meridSel.enabled, "now checkbox disables meridian");
		assertEquals(0, popup.selectedSetTime(0), "now checkbox forces immediate placement");
		popup.remove();
	}

	private static function testPlaceConfirmationUploadsFields():Void {
		closeAll();
		var uploads:Array<UploadCall> = [];
		PlaceArtifact.uploadFactory = fakeUpload(uploads, [{success: true}]);
		PlaceArtifact.nowSeconds = function():Int return Std.int(new Date(2026, 5, 7, 12, 0, 0).getTime() / 1000);
		var popup = popupAt(new Date(2026, 5, 7, 13, 5, 0));
		popup.clickPlace();
		var confirm = lastConfirm();
		assertContains(confirmText(confirm), "Are you sure you want to place the artifact on ", "scheduled placement asks for confirmation");
		clickOk(confirm);

		assertEquals(1, uploads.length, "confirmation starts one upload");
		assertEquals("https://pr2hub.com/place_artifact.php", uploads[0].url, "artifact endpoint matches Flash");
		assertEquals("42", uploads[0].fields.get("level_id"), "level id posts");
		assertEquals("10", uploads[0].fields.get("x"), "x coordinate posts");
		assertEquals("20", uploads[0].fields.get("y"), "y coordinate posts");
		assertEquals("0", uploads[0].fields.get("rot"), "rotation posts");
		assertEquals(Std.string(Std.int(new Date(2026, 5, 7, 13, 5, 0).getTime() / 1000)), uploads[0].fields.get("set_time"), "future set time posts");
		assertEquals("0", uploads[0].fields.get("override_sched"), "first upload does not override scheduled placements");
		assertEquals(true, popup.fadeOutStarted, "successful upload closes artifact popup");
		restoreHooks();
		closeAll();
	}

	private static function testScheduledResponsePromptsOverrideUpload():Void {
		closeAll();
		var uploads:Array<UploadCall> = [];
		PlaceArtifact.uploadFactory = fakeUpload(uploads, [{success: false, status: "scheduled"}, {success: true}]);
		PlaceArtifact.nowSeconds = function():Int return Std.int(new Date(2026, 5, 7, 12, 0, 0).getTime() / 1000);
		var popup = popupAt(new Date(2026, 5, 7, 13, 5, 0));
		popup.clickPlace();
		clickOk(lastConfirm());
		assertEquals(1, uploads.length, "scheduled conflict posts once before override prompt");
		var overrideConfirm = lastConfirm();
		assertContains(confirmText(overrideConfirm), "There is already a scheduled artifact placement.", "scheduled response opens override confirmation");
		clickOk(overrideConfirm);
		assertEquals(2, uploads.length, "override confirmation reposts");
		assertEquals("1", uploads[1].fields.get("override_sched"), "override repost sets override flag");
		assertEquals(true, popup.fadeOutStarted, "successful override closes artifact popup");
		restoreHooks();
		closeAll();
	}

	private static function popupAt(date:Date):PlaceArtifact {
		if (PlaceArtifact.instance != null) {
			PlaceArtifact.instance.remove();
		}
		var popup = new PlaceArtifact(request());
		popup.populateOptions(true, date);
		return popup;
	}

	private static function request():PlaceArtifactRequest {
		return {levelId: 42, x: 10, y: 20, rot: 0};
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertContains(haystack:String, needle:String, message:String):Void {
		assertions++;
		if (haystack.indexOf(needle) < 0) {
			throw '$message: expected "$haystack" to contain "$needle"';
		}
	}

	private static function assertNear(expected:Float, actual:Float, tolerance:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > tolerance) throw '$message: expected $expected +/- $tolerance, got $actual';
	}

	private static function lastConfirm():ConfirmPopup {
		for (i in 0...Popup.getOpen().length) {
			var popup = Popup.getOpen()[Popup.getOpen().length - 1 - i];
			var confirm = Std.downcast(popup, ConfirmPopup);
			if (confirm != null) {
				return confirm;
			}
		}
		throw "expected open confirmation";
	}

	private static function confirmText(confirm:ConfirmPopup):String {
		var text = LobbyArt.text(confirm, "textBox");
		return text == null ? "" : text.htmlText;
	}

	private static function clickOk(confirm:ConfirmPopup):Void {
		var ok = Std.downcast(DisplayUtil.findByName(confirm, "ok_bt"), InteractiveObject);
		ok.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	}

	private static function fakeUpload(uploads:Array<UploadCall>, results:Array<Dynamic>):Dynamic {
		return function(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void):pr2.lobby.dialogs.UploadingPopup {
			var captured = new Map<String, String>();
			for (key in fields.keys()) {
				captured.set(key, fields.get(key));
			}
			uploads.push({url: url, fields: captured, label: label});
			onResult(results.length > 0 ? results.shift() : {success: true});
			return null;
		}
	}

	private static function restoreHooks():Void {
		PlaceArtifact.uploadFactory = PlaceArtifact.defaultUpload;
		PlaceArtifact.nowSeconds = function():Int return Std.int(Date.now().getTime() / 1000);
	}

	private static function closeAll():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
		restoreHooks();
	}
}

private typedef UploadCall = {
	var url:String;
	var fields:Map<String, String>;
	var label:String;
}
