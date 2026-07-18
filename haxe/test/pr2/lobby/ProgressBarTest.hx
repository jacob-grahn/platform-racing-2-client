package pr2.lobby;

import openfl.events.Event;
import openfl.filters.DropShadowFilter;
import pr2.lobby.dialogs.ProgressBar;

/** Deterministic behavior coverage for the native shared progress control. */
class ProgressBarTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var bar = new ProgressBar(200, 0.25);
		assertEquals(2, bar.numChildren, "XFL layer order keeps border below fill");
		var border = bar.getChildAt(0);
		var fill = bar.getChildAt(1);
		// OpenFL expands Flash's 0.05 hairline by one pixel on each edge.
		assertEquals(202.0, border.width, "XFL 200px border keeps its rendered hairline bounds");
		assertEquals(11.0, border.height, "XFL 9px border keeps its rendered hairline bounds");
		assertEquals(2.0, fill.x, "XFL fill registration keeps its 2px left inset");
		assertEquals(2.0, fill.y, "XFL fill registration keeps its 2px top inset");
		assertEquals(1, bar.filters.length, "progress graphic keeps its single authored shadow");
		var shadow = Std.downcast(bar.filters[0], DropShadowFilter);
		assertEquals(2.0, shadow.distance, "progress shadow distance matches Flash");
		assertEquals(45.0, shadow.angle, "progress shadow angle matches Flash");
		assertEquals(2.0, shadow.blurX, "progress shadow blur x matches Flash");
		assertEquals(2.0, shadow.blurY, "progress shadow blur y matches Flash");
		assertEquals(true, bar.hasEventListener(Event.ENTER_FRAME), "progress interpolation listener is active");
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
		assertEquals(false, bar.hasEventListener(Event.ENTER_FRAME), "progress removal tears down interpolation listener");
		trace('ProgressBarTest passed $assertions assertions');
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
