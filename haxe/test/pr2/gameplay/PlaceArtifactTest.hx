package pr2.gameplay;

import openfl.events.Event;
import pr2.gameplay.SpecialEvent.PlaceArtifactRequest;

class PlaceArtifactTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testInitialTimeSelection();
		testVariableMonthLengths();
		testTextValidationAndSetTime();
		testPlaceNowDisablesDateControls();
		trace('PlaceArtifactTest passed $assertions assertions');
	}

	private static function testInitialTimeSelection():Void {
		var popup = popupAt(new Date(2026, 5, 7, 0, 4, 0));
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
}
