package pr2.lobby;

import pr2.page.MobileLobbyPage;

class MobileLobbyLayoutTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		pr2.DeterministicTestMode.runTest("MobileLobbyLayoutTest.testNarrowPhone", testNarrowPhone);
		if (pr2.DeterministicTestMode.finishSmokeSuite("MobileLobbyLayoutTest")) return;
		pr2.DeterministicTestMode.runTest("MobileLobbyLayoutTest.testWidePhone", testWidePhone);
		pr2.DeterministicTestMode.runTest("MobileLobbyLayoutTest.testTablet", testTablet);
		trace('MobileLobbyLayoutTest passed $assertions assertions');
	}

	private static function testNarrowPhone():Void {
		var layout = MobileLobbyPage.layoutMetricsForTests(550, 400, true);
		assertAtLeast(44, layout.headerButtonHeight, "header navigation touch height");
		assertEquals(16, layout.inset, "narrow screens keep usable side margins");
		assertEquals(518, layout.contentWidth, "narrow content fits within viewport");
		assertAtLeast(100, layout.contentHeight, "narrow play content remains reachable");
	}

	private static function testWidePhone():Void {
		var layout = MobileLobbyPage.layoutMetricsForTests(844, 390, true);
		assertEquals(756, layout.contentWidth, "wide phone respects landscape side margins");
		assertEquals(76, layout.contentY, "content clears the game header");
		assertEquals(284, layout.contentHeight, "approved landscape panel height");
		assertAtLeast(140, layout.contentHeight, "wide phone retains useful listing height");
	}

	private static function testTablet():Void {
		var layout = MobileLobbyPage.layoutMetricsForTests(1024, 768, false);
		assertEquals(936, layout.contentWidth, "tablet expands content without scaling controls");
		assertEquals(76, layout.contentY, "non-play pane starts below header");
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
