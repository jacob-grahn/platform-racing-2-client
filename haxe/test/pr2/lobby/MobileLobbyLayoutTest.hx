package pr2.lobby;

import pr2.page.MobileLobbyPage;

class MobileLobbyLayoutTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testNarrowPhone();
		testWidePhone();
		testTablet();
		trace('MobileLobbyLayoutTest passed $assertions assertions');
	}

	private static function testNarrowPhone():Void {
		var layout = MobileLobbyPage.layoutMetricsForTests(550, 400, true);
		assertAtLeast(44, layout.primaryButtonHeight, "primary navigation touch height");
		assertAtLeast(44, layout.secondaryButtonHeight, "secondary navigation touch height");
		assertAtLeast(100, layout.primaryButtonWidth, "narrow primary navigation width");
		assertAtLeast(100, layout.contentHeight, "narrow play content remains reachable");
	}

	private static function testWidePhone():Void {
		var layout = MobileLobbyPage.layoutMetricsForTests(844, 390, true);
		assertEquals(211, layout.primaryButtonWidth, "wide phone divides primary navigation evenly");
		assertEquals(112, layout.contentY, "play content clears both navigation levels");
		assertAtLeast(140, layout.contentHeight, "wide phone retains useful listing height");
	}

	private static function testTablet():Void {
		var layout = MobileLobbyPage.layoutMetricsForTests(1024, 768, false);
		assertEquals(256, layout.primaryButtonWidth, "tablet primary navigation width");
		assertEquals(58, layout.contentY, "non-play pane starts below header");
		assertAtLeast(600, layout.contentHeight, "tablet single-pane content uses the screen");
	}

	private static function assertAtLeast(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (actual < expected) throw '$message: expected at least $expected, got $actual';
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
