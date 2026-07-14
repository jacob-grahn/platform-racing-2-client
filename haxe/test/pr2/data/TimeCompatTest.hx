package pr2.data;

import com.jiggmin.data.Time;

class TimeCompatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testServerTimeOffset();
		if (pr2.DeterministicTestMode.finishSmokeSuite("TimeCompatTest")) return;
		testDayCalculation();
		trace('TimeCompatTest passed $assertions assertions');
	}

	private static function testServerTimeOffset():Void {
		var now = 100000.0;
		var time = new Time(function():Float return now);
		time.setTime(500);
		assertEquals(500000.0, time.getMS(), "setTime seeds server milliseconds");
		assertEquals(500.0, time.getTimestamp(), "setTime seeds server timestamp");
		now += 2500;
		assertEquals(502500.0, time.getMS(), "local elapsed time advances server milliseconds");
		assertEquals(502.5, time.getTimestamp(), "local elapsed time advances server timestamp");
	}

	private static function testDayCalculation():Void {
		var now = 0.0;
		var time = new Time(function():Float return now);
		time.setTime(0);
		assertEquals(0.0, time.getDay(), "zero day");
		time.setTime(86400);
		assertEquals(1.0, time.getDay(), "one day");
		time.setTime(129600);
		assertEquals(1.5, time.getDay(), "Flash preserves half days after minute rounding");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
