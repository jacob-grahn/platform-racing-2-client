package pr2.effects;

import openfl.events.Event;
import pr2.gameplay.EffectBackground;
import pr2.effects.PhysicsEffect.PhysicsEffectContext;
import pr2.level.ObjectCodes;
import pr2.level.Level;
import pr2.level.Level.LevelBlock;

class PhysicsEffectTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testGravityLandingWallAndPlayerProbe();
		if (pr2.DeterministicTestMode.finishSmokeSuite("PhysicsEffectTest")) return;
		testRotatedCollisionAndInactiveOptIn();
		testEnterFrameDriverAndRemovalCleanup();
		trace('PhysicsEffectTest passed $assertions assertions');
	}

	private static function testGravityLandingWallAndPlayerProbe():Void {
		var level = Level.fromDecoded(0xffffff, [
			LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 0, 0),
			LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 30, -30)
		]);
		var effect = new TestPhysicsEffect(15, -20, 0);
		effect.deactivate();
		effect.setVelocity(0, 0);

		effect.step(level, 0);
		assertEquals(-19, Std.int(effect.posY), "gravity advances vertical position before landing");
		assertEquals(false, effect.isGrounded(), "effect remains airborne before floor contact");

		effect.posX = 15;
		effect.posY = -1;
		effect.setVelocity(0, 1);
		effect.step(level, 0);
		assertEquals(0, Std.int(effect.posY), "effect snaps to active block top");
		assertEquals(0, Std.int(effect.velY), "landing clears falling velocity");
		assertEquals(true, effect.isGrounded(), "landing marks effect grounded");

		effect.posX = 29;
		effect.posY = 0;
		effect.setVelocity(1, 0);
		effect.step(level, 0);
		assertEquals(29, Std.int(effect.posX), "wall probe snaps effect beside the hit block");
		assertEquals(1, effect.wallTouches, "wall collision invokes the hook");

		effect.x = 10;
		effect.y = 10;
		effect.step(level, 0, 10, 20, false, false);
		assertEquals(1, effect.playerTouches, "standing local-player hit box invokes the hook");
		effect.step(level, 0, 10, 50, true, false);
		assertEquals(1, effect.playerTouches, "crouched local-player hit box uses Flash's shorter height");
	}

	private static function testRotatedCollisionAndInactiveOptIn():Void {
		var rotatedLevel = Level.fromDecoded(0xffffff, [LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, -30, -30)]);
		var rotated = new TestPhysicsEffect(-1, -15, 90);
		rotated.deactivate();
		rotated.setVelocity(1, 0);
		rotated.step(rotatedLevel, 0);
		assertEquals(1, rotated.wallTouches, "rotated wall probe finds the active block");
		assertEquals(-90, Std.int(rotated.rotation), "display rotation follows course rotation minus effect rotation");

		var inactiveLevel = Level.fromDecoded(0xffffff, [LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_WATER, 0, 0)]);
		var inactive = new TestPhysicsEffect(15, -1, 0);
		inactive.deactivate();
		inactive.setVelocity(0, 1);
		inactive.step(inactiveLevel, 0);
		assertEquals(false, inactive.isGrounded(), "inactive blocks are ignored by default");
		inactive.posX = 15;
		inactive.posY = -1;
		inactive.setVelocity(0, 1);
		inactive.hitInactiveBlocks = true;
		inactive.step(inactiveLevel, 0);
		assertEquals(true, inactive.isGrounded(), "inactive-block opt-in lets effects collide with inactive blocks");
	}

	private static function testEnterFrameDriverAndRemovalCleanup():Void {
		var level = Level.fromDecoded(0xffffff, [LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 0, 0)]);
		var contextCalls = 0;
		var effect = new TestPhysicsEffect(15, -1, 0, function():PhysicsEffectContext {
			contextCalls++;
			return {
				level: level,
				courseRotation: 0
			};
		});
		assertEquals(true, effect.hasEventListener(Event.ENTER_FRAME), "PhysicsEffect activates its frame listener");
		effect.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, contextCalls, "enter-frame driver advances with the provided context");
		assertEquals(true, effect.isGrounded(), "enter-frame step applies physics");

		effect.remove();
		assertEquals(false, effect.hasEventListener(Event.ENTER_FRAME), "remove clears the enter-frame listener");
		assertEquals(null, EffectBackground.instance, "standalone physics test leaves no effect background singleton");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}

private class TestPhysicsEffect extends PhysicsEffect {
	public var wallTouches(default, null):Int = 0;
	public var playerTouches(default, null):Int = 0;

	public function new(startX:Int, startY:Int, startRot:Int, ?contextProvider:Void->PhysicsEffectContext) {
		super(startX, startY, startRot, contextProvider);
	}

	override function onTouchWall():Void {
		wallTouches++;
	}

	override function onTouchLocalPlayer():Void {
		playerTouches++;
	}
}
