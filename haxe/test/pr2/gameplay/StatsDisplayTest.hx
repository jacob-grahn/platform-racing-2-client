package pr2.gameplay;

class StatsDisplayTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testStatsAndHoverContent();
		if (pr2.DeterministicTestMode.finishSmokeSuite("StatsDisplayTest")) return;
		trace('StatsDisplayTest passed $assertions assertions');
	}

	private static function testStatsAndHoverContent():Void {
		var display = new StatsDisplay();
		assertEquals("assets/svg/effects/stats_display_01.svg", StatsDisplay.BACKGROUND_ASSET,
			"stats display uses the exact authored XFL background and dividers");
		assertEquals(true, display.exactBackground.width > 0,
			"authored stats display art renders");
		assertNear(2.4, field(display, "speedBox").x, 0.001, "speed field preserves authored x");
		assertNear(15.5, field(display, "speedBox").width, 0.001, "speed field preserves authored width");
		assertNear(15.7, field(display, "accelBox").width, 0.001, "acceleration field preserves authored width");
		assertNear(15.3, field(display, "jumpBox").width, 0.001, "jump field preserves authored width");
		assertEquals("Speed: 0\nAcceleration: 0\nJumping: 0", display.hoverContent(), "default stats render zeroes");

		display.setStats(42, 17, 88);
		assertEquals("42", display.statText(field(display, "speedBox")), "speed box text set");
		assertEquals("17", display.statText(field(display, "accelBox")), "accel box text set");
		assertEquals("88", display.statText(field(display, "jumpBox")), "jump box text set");
		assertEquals("Speed: 42\nAcceleration: 17\nJumping: 88", display.hoverContent(), "hover content mirrors Flash StatsDisplay");

		display.remove();
	}

	private static function field(display:StatsDisplay, name:String):Null<openfl.text.TextField> {
		return pr2.lobby.LobbyArt.text(display, name);
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
