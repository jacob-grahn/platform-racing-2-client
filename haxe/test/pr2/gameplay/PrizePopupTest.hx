package pr2.gameplay;

import pr2.lobby.dialogs.Popup;
import pr2.gameplay.PrizePopupView.PrizePartSymbol;
import pr2.util.TestDisplayUtil as DisplayUtil;

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
		if (pr2.DeterministicTestMode.finishSmokeSuite("PrizePopupTest")) return;
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
		assertEquals("assets/svg/effects/prize_bg_01.svg", PrizePopupView.BG_ASSET,
			"prize popup uses exact authored XFL background");
		assertEquals("assets/svg/effects/prize_flavor_bg_01.svg", PrizePopupView.FLAVOR_BG_ASSET,
			"prize popup uses exact authored flavor background");
		assertEquals("hat", popup.targetName, "hat type selects hat clip");
		assertEquals("--- Propeller Hat! ---", popup.titleText, "finished title decoration");
		assertEquals("You won a:", popup.bodyText, "finished body line");
		assertEquals(false, popup.flavorVisible, "no flavor without a description");
		var hat = Std.downcast(DisplayUtil.findByName(popup, "hat"), PrizePartSymbol);
		assertNear(184.15, hat.x, 0.001, "hat preview preserves authored x");
		assertNear(-10.75, hat.y, 0.001, "hat preview preserves authored y");
		assertEquals(5, hat.currentFrame, "hat preview selects the awarded source frame");
		assertEquals(true, DisplayUtil.findByName(hat, "colorMC").width > 0,
			"hat preview renders its exact primary vector channel");
		popup.remove();
	}

	private static function testUniversalAndWinner():Void {
		var universal = new PrizePopup("head", 3, "Eye Patch", "", true, false);
		assertEquals("head", universal.targetName, "head type selects head clip");
		assertEquals("Anyone who finishes this race wins an:", universal.bodyText, "universal body line");
		var head = Std.downcast(DisplayUtil.findByName(universal, "head"), PrizePartSymbol);
		assertEquals(3, head.currentFrame, "head preview is stopped on the awarded head");
		for (i in 1...5) {
			assertEquals(false, DisplayUtil.findByName(head, "hat" + i).visible, 'head preview hides hat $i after selecting its frame');
		}
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

		var epic = new PrizePopup("eBody", 3, "Epic Cape", "", false, true);
		assertEquals(true, epic.flavorVisible, "finished epic upgrade shows the authored guide copy");
		assertEquals("body", epic.targetName, "epic body uses the body source channels");
		var epicBody = Std.downcast(DisplayUtil.findByName(epic, "body"), PrizePartSymbol);
		assertEquals(true, DisplayUtil.findByName(epicBody, "colorMC2").width > 0,
			"epic upgrade exposes its exact secondary channel to EpicFlash");
		epic.remove();
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

	private static function assertNear(expected:Float, actual:Float, tolerance:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > tolerance) throw '$message: expected $expected +/- $tolerance, got $actual';
	}
}
