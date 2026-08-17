package pr2.gameplay;

import pr2.gameplay.RotationMath.RotatedPoint;

class RotationMathTest {
	private static var assertions = 0;

	public static function main():Void {
		assertPoint(12, -8, RotationMath.rotatePoint(12.9, -8.9, 0), "unrotated values truncate toward zero");
		if (pr2.DeterministicTestMode.finishSmokeSuite("RotationMathTest")) return;
		assertPoint(-8, -12, RotationMath.rotatePoint(12.9, -8.9, 90), "right-angle values truncate after rotation");
		assertPoint(8, 12, RotationMath.rotatePoint(12.9, -8.9, -90), "negative right angle matches AS3");
		assertPoint(-12, 8, RotationMath.rotatePoint(12.9, -8.9, 180), "half turn matches AS3");
		assertPoint(-8, -12, RotationMath.rotatePoint(12.9, -8.9, 450), "rotation normalizes once like AS3");
		assertPoint(12, -8, RotationMath.rotatePoint(12.9, -8.9, 810), "out-of-range rotation preserves AS3 single-wrap quirk");
		assertPoint(1, 0, RotationMath.rotatePoint(4294967297.0, Math.NaN, 0), "AS3 int coercion wraps overflow and clears NaN");
		testCoordinateFrameMatrix();
		testTypedEffectPackets();
		assertEquals(-90, RotationMath.normalizeDisplayRotation(270), "positive display rotation wraps");
		assertEquals(90, RotationMath.normalizeDisplayRotation(-270), "negative display rotation wraps");
		trace('RotationMathTest passed $assertions assertions');
	}

	private static function testCoordinateFrameMatrix():Void {
		var canonical = new CoordinateFrames.CanonicalPoint(75, 165);
		var rotations = [0, 90, 180, -90];
		for (senderRotation in rotations) {
			var sender = CoordinateFrames.gravityFromCanonical(canonical, senderRotation);
			assertCoordinates(75, 165, CoordinateFrames.canonicalFromGravity(sender, senderRotation),
				'$senderRotation-degree gravity frame round-trips through canonical space');
			var encodedMine = RotationMath.rotatePoint(canonical.x, canonical.y, senderRotation);
			var decodedMine = CoordinateFrames.canonicalFromMinePacket(
				new CoordinateFrames.EffectPacketPoint(encodedMine.x, encodedMine.y), senderRotation);
			assertCoordinates(75, 165, decodedMine, '$senderRotation-degree mine packet restores its canonical tile centre');
			for (receiverRotation in rotations) {
				var expected = CoordinateFrames.gravityFromCanonical(canonical, receiverRotation);
				var received = CoordinateFrames.gravityBetween(sender, senderRotation, receiverRotation);
				assertCoordinates(expected.x, expected.y, received,
					'$senderRotation-degree sender maps into $receiverRotation-degree receiver gravity frame');
			}
		}
	}

	private static function testTypedEffectPackets():Void {
		var laser = EffectPackets.laser(["Laser", "-165", "75", "left", "90", "7"]);
		assertCoordinates(-165, 75, laser.position, "laser packet preserves sender gravity coordinates");
		assertEquals("left", laser.direction, "laser packet preserves direction");
		assertEquals(90, laser.senderRotation, "laser packet exposes sender rotation");
		assertEquals(7, laser.shooterId, "laser packet exposes shooter id");
		var ice = EffectPackets.iceWave(["IceWave", "-165", "75", "30", "90", "8"]);
		assertCoordinates(-165, 75, ice.position, "ice-wave packet preserves sender gravity coordinates");
		assertEquals(30, ice.angle, "ice-wave packet preserves angle");
		assertEquals(90, ice.senderRotation, "ice-wave packet exposes sender rotation");
		assertEquals(8, ice.shooterId, "ice-wave packet exposes shooter id");
		var mine = EffectPackets.mine(["Mine", "165", "-75", "90"]);
		assertCoordinates(165, -75, mine.position, "mine packet preserves its Flash-specific coordinates");
		assertEquals(90, mine.senderRotation, "mine packet exposes sender rotation");
	}

	private static function assertPoint(expectedX:Int, expectedY:Int, actual:RotatedPoint, message:String):Void {
		assertEquals(expectedX, actual.x, '$message x');
		assertEquals(expectedY, actual.y, '$message y');
	}

	private static function assertCoordinates(expectedX:Int, expectedY:Int, actual:Dynamic, message:String):Void {
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
