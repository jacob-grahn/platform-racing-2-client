package pr2.lobby;

import openfl.display.Sprite;
import pr2.lobby.dialogs.HatsMenu;

class HatsMenuTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testBlankAndNullAllowAllHats();
		if (pr2.DeterministicTestMode.finishSmokeSuite("HatsMenuTest")) return;
		testCommaDelimitedBadHats();
		testHatAttackForcesArtifactUnavailable();
		trace('HatsMenuTest passed $assertions assertions');
	}

	private static function testBlankAndNullAllowAllHats():Void {
		var blankMenu = new HatsMenu("", "Race", new Sprite());
		for (hatId in 2...17) {
			assertEquals(true, blankMenu.isHatAllowed(hatId), 'blank allows hat $hatId');
			assertEquals(false, blankMenu.isHatEnabled(hatId), 'blank disables hat $hatId');
		}
		blankMenu.remove();

		var nullMenu = new HatsMenu(null, "Race", new Sprite());
		assertEquals(true, nullMenu.isHatAllowed(14), "null allows artifact outside Hat Attack");
		nullMenu.remove();
	}

	private static function testCommaDelimitedBadHats():Void {
		var menu = new HatsMenu("0,1,2,7,9,16,17,bad,14.5", "Race", new Sprite());
		assertEquals(false, menu.isHatAllowed(2), "valid bad hat disables exp");
		assertEquals(false, menu.isHatAllowed(7), "valid bad hat disables santa");
		assertEquals(false, menu.isHatAllowed(9), "valid bad hat disables top");
		assertEquals(false, menu.isHatAllowed(16), "valid bad hat disables cheese");
		assertEquals(false, menu.isHatAllowed(14), "Flash numeric coercion disables artifact from 14.5");
		assertEquals(true, menu.isHatAllowed(3), "unmentioned hat remains allowed");
		assertEquals(false, menu.isHatAllowed(1), "hat one is not represented in the menu");
		menu.remove();
	}

	private static function testHatAttackForcesArtifactUnavailable():Void {
		var menu = new HatsMenu("", "Hat Attack", new Sprite());
		assertEquals(false, menu.isHatAllowed(14), "Hat Attack disables artifact even without bad hats");
		assertEquals(true, menu.isHatAllowed(13), "Hat Attack leaves neighboring hats alone");
		assertEquals(true, menu.isHatAllowed(15), "Hat Attack leaves neighboring hats alone");
		menu.remove();

		menu = new HatsMenu("2", "hat", new Sprite());
		assertEquals(true, menu.isHatAllowed(14), "only Flash Hat Attack label forces artifact unavailable");
		menu.remove();
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
