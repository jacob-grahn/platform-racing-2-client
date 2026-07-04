package pr2.gameplay;

import openfl.events.Event;

class CourseTimerTest {
	private static var assertions:Int = 0;
	private static var nowMs:Float = 0;

	public static function main():Void {
		testCountdownModeUsesServerClockAndAddTime();
		testRacingModeCountsUpAndAddTimeMovesStartTime();
		testUrgencyPauseAndTimeoutBehavior();
		trace('CourseTimerTest passed $assertions assertions');
	}

	private static function testCountdownModeUsesServerClockAndAddTime():Void {
		nowMs = 100000;
		var timer = new CourseTimer({now: now, onOutOfTime: function():Void {}});
		timer.setTime(120);
		assertEquals(120, timer.getMS(), "getMS exposes configured countdown seconds");
		timer.init();
		assertEquals("2:00", timer.debugText(), "init displays full countdown time");
		assertEquals(0, timer.debugTextColor(), "two minutes renders black");
		nowMs += 1000;
		timer.tickForTests();
		assertEquals("1:59", timer.debugText(), "tick uses server-clock elapsed seconds");
		timer.pause();
		nowMs += 5000;
		timer.addTime(10);
		assertEquals("2:04", timer.debugText(), "addTime extends countdown by seconds");
		assertEquals(false, timer.debugPaused(), "addTime resumes a paused timer");
		timer.remove();
	}

	private static function testRacingModeCountsUpAndAddTimeMovesStartTime():Void {
		nowMs = 500000;
		var timer = new CourseTimer({now: now});
		timer.setTime(0);
		assertEquals(true, timer.debugRacing(), "zero max time enters racing mode");
		timer.init();
		assertEquals("0:00", timer.debugText(), "racing mode starts at zero");
		nowMs += 65000;
		timer.tickForTests();
		assertEquals("1:05", timer.debugText(), "racing mode displays elapsed time");
		timer.addTime(5);
		assertEquals("1:10", timer.debugText(), "racing addTime advances elapsed display");
		assertEquals(0, timer.debugTextColor(), "racing mode leaves authored text color alone");
		timer.remove();
	}

	private static function testUrgencyPauseAndTimeoutBehavior():Void {
		var calls = 0;
		nowMs = 200000;
		var timer = new CourseTimer({now: now, onOutOfTime: function():Void calls++});
		timer.setTime(31);
		timer.init();
		assertEquals("0:31", timer.debugText(), "starts above urgency threshold");
		assertEquals(0, timer.debugTextColor(), "above thirty seconds is black");
		nowMs += 2000;
		timer.tickForTests();
		assertEquals("0:29", timer.debugText(), "under thirty seconds displays remaining time");
		assertEquals(0xFF0000, timer.debugTextColor(), "under thirty seconds turns red");
		nowMs += 20000;
		timer.tickForTests();
		assertEquals("0:09", timer.debugText(), "under ten seconds displays remaining time");
		assertFloatEquals(3, timer.debugHolderScale(), 0.001, "under ten seconds starts pulse");
		for (_ in 0...12) {
			timer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertFloatEquals(1, timer.debugHolderScale(), 0.001, "pulse decays back to normal scale");
		timer.pause();
		assertEquals(true, timer.debugPaused(), "pause marks the timer paused");
		nowMs += 10000;
		timer.tickForTests();
		assertEquals(1, calls, "timeout callback fires when time reaches zero");
		assertEquals(true, timer.debugPaused(), "timeout pauses the interval");
		assertEquals("0:00", timer.debugText(), "timeout display is clamped at zero");
		timer.remove();
		assertEquals(true, timer.isRemoved(), "remove tears down the removable timer");
	}

	private static function now():Float {
		return nowMs;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertFloatEquals(expected:Float, actual:Float, tolerance:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > tolerance) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
