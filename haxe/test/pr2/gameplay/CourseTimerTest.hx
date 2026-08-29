package pr2.gameplay;

import openfl.events.Event;
import pr2.runtime.FrameClock;
import pr2.runtime.FrameRateDiagnostics;
import pr2.runtime.FrameRateSettings;

class CourseTimerTest {
	private static var assertions:Int = 0;
	private static var nowMs:Float = 0;

	public static function main():Void {
		pr2.DeterministicTestMode.runTest("CourseTimerTest.testCountdownModeUsesServerClockAndAddTime", testCountdownModeUsesServerClockAndAddTime);
		if (pr2.DeterministicTestMode.finishSmokeSuite("CourseTimerTest")) return;
		pr2.DeterministicTestMode.runTest("CourseTimerTest.testRacingModeCountsUpAndAddTimeMovesStartTime", testRacingModeCountsUpAndAddTimeMovesStartTime);
		pr2.DeterministicTestMode.runTest("CourseTimerTest.testUrgencyPauseAndTimeoutBehavior", testUrgencyPauseAndTimeoutBehavior);
		pr2.DeterministicTestMode.runTest("CourseTimerTest.testTimeoutAndUrgencyPulseMatchAtBothPresentationRates", testTimeoutAndUrgencyPulseMatchAtBothPresentationRates);
		trace('CourseTimerTest passed $assertions assertions');
	}

	private static function testTimeoutAndUrgencyPulseMatchAtBothPresentationRates():Void {
		var baseline = runTimeoutCadence(false);
		var smooth = runTimeoutCadence(true);
		assertEquals(1, baseline.calls, "30 FPS timeout fires once");
		assertEquals(1, smooth.calls, "60 FPS timeout fires once");
		assertEquals(15, baseline.simulationFrames, "30 FPS timeout boundary observes fifteen authoritative pulse frames");
		assertEquals(15, smooth.simulationFrames, "60 FPS timeout boundary observes the same authoritative pulse frames");
		assertEquals(15, baseline.stageFrames, "30 FPS timeout boundary is reached after fifteen display frames");
		assertEquals(30, smooth.stageFrames, "60 FPS timeout follows wall time across thirty display frames");
		assertFloatEquals(baseline.scale, smooth.scale, 0.001,
			"urgency pulse advances only on authoritative frames at either presentation rate");
	}

	private static function runTimeoutCadence(smooth:Bool):{
		calls:Int,
		stageFrames:Int,
		simulationFrames:Int,
		scale:Float
	} {
		nowMs = 0;
		var calls = 0;
		var timer = new CourseTimer({now: now, onOutOfTime: function():Void calls++});
		timer.setTime(1);
		timer.init();
		var clock = new FrameClock(FrameRateSettings.fromQuery(smooth ? "?smooth60=1" : null, true),
			new FrameRateDiagnostics(function():Float return 0));
		@:privateAccess FrameClock.setCurrentForTests(clock);
		var millisecondsPerFrame = 1000 / (smooth ? 60 : 30);
		while (calls == 0) {
			clock.advanceFrame();
			nowMs = clock.stageFrameNumber * millisecondsPerFrame;
			timer.dispatchEvent(new Event(Event.ENTER_FRAME));
			timer.tickForTests();
		}
		var result = {
			calls: calls,
			stageFrames: clock.stageFrameNumber,
			simulationFrames: clock.simulationFrameNumber,
			scale: timer.debugHolderScale()
		};
		timer.remove();
		@:privateAccess FrameClock.setCurrentForTests(null);
		return result;
	}

	private static function testCountdownModeUsesServerClockAndAddTime():Void {
		nowMs = 100000;
		var timer = new CourseTimer({now: now, onOutOfTime: function():Void {}});
		assertEquals(true, timer.getChildAt(0).scale9Grid != null, "timer background preserves the SquareBG scale grid");
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
