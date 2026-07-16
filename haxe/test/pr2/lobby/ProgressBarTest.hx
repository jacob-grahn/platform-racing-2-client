package pr2.lobby;

import pr2.lobby.dialogs.ProgressBar;

/** Deterministic behavior coverage for the native shared progress control. */
class ProgressBarTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var bar = new ProgressBar(200, 0.25);
		assertEquals(0.0, bar.displayedWidthForTests(), "bar begins empty");
		bar.setProgress(1);
		assertEquals(196.0, bar.targetWidthForTests(), "full progress uses the authored 2px inset on each side");

		bar.setProgress(0.5);
		assertEquals(98.0, bar.targetWidthForTests(), "half progress targets half the usable width");
		bar.tickForTests();
		assertEquals(24.5, bar.displayedWidthForTests(), "bar keeps Flash's frame interpolation");

		bar.setProgress(2);
		assertEquals(196.0, bar.targetWidthForTests(), "progress clamps above one");
		bar.setProgress(-1);
		assertEquals(0.0, bar.targetWidthForTests(), "progress clamps below zero");
		bar.remove();
		trace('ProgressBarTest passed $assertions assertions');
	}

	private static function assertEquals(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.0001) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
