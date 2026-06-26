package pr2.gameplay;

import pr2.lobby.dialogs.Popup;

/**
	Covers the prize announcement the way Flash `gameplay.PrizePopup` assembled
	it: target clip selection by type, the "You won" / "Anyone who finishes" /
	"The winner" body lines with `a`/`an`/`a pair of`, the title decoration, the
	flavor description, and the exp/cancel detail lines.
**/
class PrizePopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testAOrAn();
		testWonPart();
		testUniversalAndWinner();
		testFeet();
		testFlavor();
		testExp();
		testCancel();
		closeAll();
		trace('PrizePopupTest passed $assertions assertions');
	}

	private static function testAOrAn():Void {
		assertEquals("an", PrizePopup.aOrAnFor("Apple"), "vowel start takes an");
		assertEquals("an", PrizePopup.aOrAnFor("Igloo Hat"), "I start takes an");
		assertEquals("a", PrizePopup.aOrAnFor("Top Hat"), "consonant start takes a");
		assertEquals("a", PrizePopup.aOrAnFor(""), "empty falls back to a");
	}

	private static function testWonPart():Void {
		var popup = new PrizePopup("hat", 5, "Propeller Hat", "", false, true);
		assertEquals("hat", popup.targetName, "hat type selects hat clip");
		assertEquals("--- Propeller Hat! ---", popup.titleText, "finished title decoration");
		assertEquals("You won a:", popup.bodyText, "finished body line");
		assertEquals(false, popup.flavorVisible, "no flavor without a description");
		popup.remove();
	}

	private static function testUniversalAndWinner():Void {
		var universal = new PrizePopup("head", 3, "Eye Patch", "", true, false);
		assertEquals("head", universal.targetName, "head type selects head clip");
		assertEquals("Anyone who finishes this race wins an:", universal.bodyText, "universal body line");
		universal.remove();

		var winner = new PrizePopup("body", 3, "Cape", "", false, false);
		assertEquals("body", winner.targetName, "body type selects body clip");
		assertEquals("The winner of this race will earn a:", winner.bodyText, "winner body line");
		winner.remove();
	}

	private static function testFeet():Void {
		var popup = new PrizePopup("feet", 2, "Boots", "", false, true);
		assertEquals("foot", popup.targetName, "feet type selects foot clip");
		assertEquals("You won a pair of:", popup.bodyText, "feet use 'a pair of'");
		popup.remove();
	}

	private static function testFlavor():Void {
		var popup = new PrizePopup("hat", 5, "Propeller Hat", "Spins when you jump", false, true);
		assertEquals(true, popup.flavorVisible, "description shows the flavor box");
		assertEquals("Spins when you jump", popup.flavorText, "flavor text mirrors the description");
		popup.remove();
	}

	private static function testExp():Void {
		var popup = new PrizePopup("exp", 1000, "Experience", "", false, true);
		assertEquals("exp", popup.targetName, "exp type selects exp clip");
		assertEquals("You already have this prize, so here are 1,000 experience points instead!", popup.detailText,
			"exp detail formats the points with commas");
		popup.remove();
	}

	private static function testCancel():Void {
		var popup = new PrizePopup("cancel", 0, "Top Hat", "Bob", false, true);
		assertEquals("exp", popup.targetName, "cancel reuses the exp clip");
		assertEquals("-- Top Hat --", popup.titleText, "cancel title decoration");
		assertEquals("Bob cancelled the prize for finishing this race.", popup.detailText, "cancel detail line");
		popup.remove();
	}

	private static function closeAll():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
