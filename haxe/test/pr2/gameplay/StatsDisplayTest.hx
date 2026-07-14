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
}
