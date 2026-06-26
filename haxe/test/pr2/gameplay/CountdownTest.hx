package pr2.gameplay;

import openfl.display.Sprite;

class CountdownTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testCountdownSequence();
		trace('CountdownTest passed $assertions assertions');
	}

	private static function testCountdownSequence():Void {
		var finishCalls = 0;
		var parent = new Sprite();
		var countdown = new Countdown(function():Void finishCalls++);
		parent.addChild(countdown);

		assertEquals(0, countdown.counts, "no counts before playing");
		assertEquals(false, countdown.finished, "not finished before playing");

		// Drive the authored 62-frame timeline to completion. Frame scripts at
		// 9/24/39 tick "count" and 54 fires "finish"; 62 self-removes.
		var guard = 0;
		while (countdown.parent != null && guard < 200) {
			countdown.advance();
			guard++;
		}

		assertEquals(3, countdown.counts, "three ready counts (3-2-1)");
		assertEquals(true, countdown.finished, "finish reached");
		assertEquals(1, finishCalls, "onFinish invoked exactly once");
		assertEquals(true, countdown.parent == null, "countdown self-removes after the last frame");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
