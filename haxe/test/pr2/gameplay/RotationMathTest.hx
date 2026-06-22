package pr2.gameplay;

import pr2.gameplay.RotationMath.RotatedPoint;

class RotationMathTest {
	private static var assertions = 0;

	public static function main():Void {
		assertPoint(12, -8, RotationMath.rotatePoint(12.9, -8.9, 0), "unrotated values truncate toward zero");
		assertPoint(-8, -12, RotationMath.rotatePoint(12.9, -8.9, 90), "right-angle values truncate after rotation");
		assertPoint(8, 12, RotationMath.rotatePoint(12.9, -8.9, -90), "negative right angle matches AS3");
		assertPoint(-12, 8, RotationMath.rotatePoint(12.9, -8.9, 180), "half turn matches AS3");
		assertPoint(-8, -12, RotationMath.rotatePoint(12.9, -8.9, 450), "rotation normalizes once like AS3");
		assertPoint(12, -8, RotationMath.rotatePoint(12.9, -8.9, 810), "out-of-range rotation preserves AS3 single-wrap quirk");
		assertPoint(1, 0, RotationMath.rotatePoint(4294967297.0, Math.NaN, 0), "AS3 int coercion wraps overflow and clears NaN");
		assertEquals(-90, RotationMath.normalizeDisplayRotation(270), "positive display rotation wraps");
		assertEquals(90, RotationMath.normalizeDisplayRotation(-270), "negative display rotation wraps");
		trace('RotationMathTest passed $assertions assertions');
	}

	private static function assertPoint(expectedX:Int, expectedY:Int, actual:RotatedPoint, message:String):Void {
		assertEquals(expectedX, actual.x, '$message x');
		assertEquals(expectedY, actual.y, '$message y');
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
