package pr2.data;

import com.jiggmin.data.SWFStats;

class SWFStatsTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testAverageStartsAfterThirtySamples();
		testFrameRateDriftResetsBeforeFullWindow();
		testFastThirtySampleAverageResetsFrameRate();
		testNormalAverageDoesNotResetFrameRate();
		trace('SWFStatsTest passed $assertions assertions');
	}

	private static function testAverageStartsAfterThirtySamples():Void {
		var harness = new WatchdogHarness();
		for (_ in 0...29) {
			harness.advanceAndReset(1000);
		}
		assertEquals(29, harness.stats.sampleCountForTests(), "sample count before full window");
		assertTrue(Math.isNaN(harness.stats.averageLagForTests()), "partial window average matches Flash NaN");
		assertEquals(0, harness.setRates.length, "partial window does not reset healthy frame rate");

		harness.advanceAndReset(1000);
		assertEquals(30, harness.stats.sampleCountForTests(), "sample count at full window");
		assertClose(1000, harness.stats.averageLagForTests(), "full window average");
		assertEquals(0, harness.setRates.length, "normal full window does not reset healthy frame rate");

		harness.advanceAndReset(1100);
		assertEquals(30, harness.stats.sampleCountForTests(), "sample window caps at keep count");
		assertClose(1003.3333333333334, harness.stats.averageLagForTests(), "rolling sample window shifts oldest value");
	}

	private static function testFrameRateDriftResetsBeforeFullWindow():Void {
		var harness = new WatchdogHarness();
		harness.frameRate = 30;

		harness.advanceAndReset(1000);

		assertEquals(27, harness.frameRate, "drifted frame rate reset");
		assertEquals(1, harness.setRates.length, "drift reset count");
		assertEquals(27, harness.setRates[0], "drift reset target");
		assertTrue(Math.isNaN(harness.stats.averageLagForTests()), "drift reset does not require full window");
	}

	private static function testFastThirtySampleAverageResetsFrameRate():Void {
		var harness = new WatchdogHarness();
		for (_ in 0...30) {
			harness.advanceAndReset(850);
		}

		assertClose(850, harness.stats.averageLagForTests(), "fast average");
		assertEquals(1, harness.setRates.length, "fast average reset count");
		assertEquals(27, harness.setRates[0], "fast average reset target");
	}

	private static function testNormalAverageDoesNotResetFrameRate():Void {
		var harness = new WatchdogHarness();
		for (_ in 0...30) {
			harness.advanceAndReset(1000);
		}

		assertClose(1000, harness.stats.averageLagForTests(), "normal average");
		assertEquals(0, harness.setRates.length, "normal average reset count");
	}

	private static function assertTrue(value:Bool, message:String):Void {
		assertions++;
		if (!value) throw '$message: expected true';
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000000000001) throw '$message: expected $expected, got $actual';
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}

private class WatchdogHarness {
	public var now:Float = 0;
	public var frameRate:Float = 27;
	public var setRates:Array<Float> = [];
	public var stats:SWFStats;

	public function new() {
		stats = new SWFStats(false, getNow, getFrameRate, setFrameRate);
	}

	public function advanceAndReset(delta:Float):Void {
		now += delta;
		stats.resetStats();
	}

	private function getNow():Float {
		return now;
	}

	private function getFrameRate():Float {
		return frameRate;
	}

	private function setFrameRate(value:Float):Void {
		setRates.push(value);
		frameRate = value;
	}
}
