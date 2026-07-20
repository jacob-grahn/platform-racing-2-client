package pr2.effects;

import openfl.events.Event;
import pr2.effects.ShotEffect.ShotEffectContext;
import pr2.effects.ShotEffect.ShotEffectPlayer;
import pr2.level.ObjectCodes;
import pr2.level.Level;
import pr2.level.Level.LevelBlock;

class ShotEffectTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testMovementCollisionOrderingAndLife();
		if (pr2.DeterministicTestMode.finishSmokeSuite("ShotEffectTest")) return;
		testPlayerHitFilteringAndRecoil();
		testInactiveBlocksAndFrameCleanup();
		trace('ShotEffectTest passed $assertions assertions');
	}

	private static function testMovementCollisionOrderingAndLife():Void {
		var block = LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 30, 0);
		var level = Level.fromDecoded(0xffffff, [block]);
		var shot = new TestShotEffect(0, 15, 0, 0, 7, "laser");
		shot.life = 2;
		shot.step(level, 0);
		assertEquals(5, Std.int(shot.posX), "shot moves by default speed before collision");
		assertEquals(5, Std.int(shot.velX), "shot velocity follows angle and speed");
		assertEquals(0, shot.blockHits, "shot has not reached the block on first frame");
		assertEquals(1, Std.int(shot.life), "shot decrements life after movement and collision checks");

		shot.setSpeed(25);
		shot.step(level, 0);
		assertEquals(1, shot.blockHits, "shot checks block collision after positioning");
		assertEquals(25, Std.int(shot.lastDamageX), "block damage receives horizontal velocity");
		assertEquals(1, shot.hitAnythingCount, "block hit invokes shared hit hook");
		assertEquals(null, shot.parent, "life expiry removes the shot after collision checks");
		assertEquals(false, shot.hasEventListener(Event.ENTER_FRAME), "life expiry clears frame listener");
	}

	private static function testPlayerHitFilteringAndRecoil():Void {
		var level = Level.fromDecoded(0xffffff, []);
		var recoil:Array<String> = [];
		var players:Array<ShotEffectPlayer> = [
			{tempId: 7, x: 10, y: 20, removed: false, local: true, onHit: function(vx:Float, vy:Float):Void recoil.push('${Math.round(vx)},${Math.round(vy)}')},
			{tempId: 8, x: 10, y: 20, removed: true, local: true, onHit: function(vx:Float, vy:Float):Void recoil.push('removed')},
			{tempId: 9, x: 10, y: 20, removed: false, local: true, onHit: function(vx:Float, vy:Float):Void recoil.push('${Math.round(vx)},${Math.round(vy)}')}
		];
		var shot = new TestShotEffect(0, 15, 180, 0, 7, "laser");
		shot.scaleX = 1;
		shot.step(level, 0, players);
		assertEquals(0, shot.playerHits, "shooter id and right-facing hit box skip players on the other side");

		shot.scaleX = -1;
		shot.posX = 0;
		shot.posY = 15;
		shot.setAngle(180);
		shot.step(level, 0, players);
		assertEquals(1, shot.playerHits, "left-facing hit box finds a non-shooter active player");
		assertEquals("-5,0", recoil[0], "local player receives Flash recoil velocity");
		assertEquals(15, Std.int(shot.x), "player hit snaps shot x to player minus velocity");
		assertEquals(1, shot.hitAnythingCount, "player hit invokes shared hit hook");
	}

	private static function testInactiveBlocksAndFrameCleanup():Void {
		var level = Level.fromDecoded(0xffffff, [LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_WATER, 0, 0)]);
		var shot = new TestShotEffect(0, 15, 0, 0, -1, "ice");
		shot.checkCollisionsForTests(level, 0);
		assertEquals(0, shot.blockHits, "inactive blocks are ignored by default");
		shot.hitInactiveBlocks = true;
		shot.checkCollisionsForTests(level, 0);
		assertEquals(1, shot.blockHits, "inactive-block opt-in lets shots hit inactive blocks");

		var calls = 0;
		var driven = new TestShotEffect(0, 15, 0, 0, -1, "laser", 0, function():ShotEffectContext {
			calls++;
			return {level: Level.fromDecoded(0xffffff, []), courseRotation: 0};
		});
		assertEquals(true, driven.hasEventListener(Event.ENTER_FRAME), "shot activates enter-frame listener");
		assertEquals(1, calls, "constructor uses the provided context for Flash's immediate collision check");
		driven.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(2, calls, "enter-frame uses the provided context");
		driven.remove();
		assertEquals(false, driven.hasEventListener(Event.ENTER_FRAME), "remove clears shot enter-frame listener");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}

private class TestShotEffect extends ShotEffect {
	public var blockHits(default, null):Int = 0;
	public var playerHits(default, null):Int = 0;
	public var hitAnythingCount(default, null):Int = 0;
	public var lastDamageX(default, null):Float = 0;

	override function onBlockDamage(block:LevelBlock, damageX:Float):Void {
		blockHits++;
		lastDamageX = damageX;
	}

	override function hitPlayer(player:ShotEffectPlayer):Void {
		playerHits++;
		super.hitPlayer(player);
	}

	override function hitAnything():Void {
		hitAnythingCount++;
	}

	public function checkCollisionsForTests(level:Level, courseRotation:Int):Void {
		checkCollisions(level, courseRotation);
	}
}
