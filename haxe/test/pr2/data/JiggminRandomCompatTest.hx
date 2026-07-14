package pr2.data;

import com.jiggmin.data.Random;
import pr2.crypto.ByteArrayCompat;
import pr2.util.FlashRandom;

class JiggminRandomCompatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testSeedAndPublicSequence();
		if (pr2.DeterministicTestMode.finishSmokeSuite("JiggminRandomCompatTest")) return;
		testNextBytes();
		testRangeErrors();
		testFlashRandomWrapper();
		trace('JiggminRandomCompatTest passed $assertions assertions');
	}

	private static function testSeedAndPublicSequence():Void {
		var random = new Random(1);
		assertEquals(1, random.seed, "seed getter preserves constructor seed");
		assertEquals(534011718, random.nextInt(), "nextInt first sample");
		assertEquals(1, random.nextMax(10), "nextMax uses exclusive max");
		assertEquals(-1, random.nextMinMax(-5, 5), "nextMinMax applies min offset");
		assertClose(0.7716041220219825, random.nextNumber(), "nextNumber sample");

		var negative = new Random(-7);
		assertEquals(-7, negative.seed, "negative seed preserved");
		assertEquals(822959691, negative.nextInt(), "negative seed sequence");
		assertEquals(0, negative.nextMax(0), "zero max returns zero");
		assertEquals(3, negative.nextMinMax(3, 3), "equal min/max returns min");
	}

	private static function testNextBytes():Void {
		var random = new Random(1);
		var bytes = new ByteArrayCompat();
		bytes.writeByte(0x11);
		random.nextBytes(bytes, 4);
		assertEquals("1146d08682", bytes.toHex(), "nextBytes appends internal sample low bytes");
		random.nextBytes(bytes, -1);
		assertEquals("1146d08682", bytes.toHex(), "negative byte length writes nothing");
	}

	private static function testRangeErrors():Void {
		assertThrows(function():Void new Random(1).nextMax(-1), 'Argument "maxValue" must be positive.', "negative max error");
		assertThrows(function():Void new Random(1).nextMinMax(2, 1),
			'Argument "minValue" must be less than or equal to "maxValue".', "min greater than max error");
		assertThrows(function():Void new Random(1).nextBytes(null, 1), 'Argument "buffer" cannot be null.', "null byte buffer error");
	}

	private static function testFlashRandomWrapper():Void {
		var random = new FlashRandom(1);
		assertEquals(0, random.nextMinMax(0, 4), "FlashRandom wrapper preserves first gameplay sample");
		assertEquals(0, random.nextMinMax(0, 4), "FlashRandom wrapper preserves second gameplay sample");
		assertEquals(1, random.nextMinMax(0, 4), "FlashRandom wrapper preserves third gameplay sample");
		assertEquals(3, random.nextMinMax(0, 4), "FlashRandom wrapper preserves fourth gameplay sample");
	}

	private static function assertThrows(fn:Void->Void, expected:String, message:String):Void {
		assertions++;
		try {
			fn();
		} catch (error:Dynamic) {
			if (Std.string(error) == expected) {
				return;
			}
			throw '$message: expected $expected, got $error';
		}
		throw '$message: expected throw';
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
