package pr2.effects;

import pr2.level.ObjectCodes;
import pr2.level.ServerLevel;
import pr2.level.ServerLevel.DecodedBlock;

class SlashTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testRightSlashAnimationProbesSoundAndRemoval();
		testLeftSlashShooterFilteringAndScale();
		trace('SlashTest passed $assertions assertions');
	}

	private static function testRightSlashAnimationProbesSoundAndRemoval():Void {
		var blocks = [
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 0, -30),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 0, 0),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 30, -30),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 30, 0),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 60, -30),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 60, 0)
		];
		var hits:Array<String> = [];
		var playerHits:Array<String> = [];
		var sounds:Array<String> = [];
		var slash = new Slash(0, 0, "right", 7, {
			level: new ServerLevel(0xffffff, blocks),
			courseRotation: 0,
			player: {
				tempId: 9,
				x: 58,
				y: 70,
				removed: false,
				hit: function(vx:Float, vy:Float):Void playerHits.push('$vx,$vy')
			},
			onBlockDamage: function(block, reach):Void hits.push('${block.x},${block.y}:$reach'),
			playSound: function(x:Float, y:Float):Void sounds.push('$x,$y')
		});

		assertEquals("SlashAnimation", slash.animation.symbol.linkageClassName, "slash uses authored animation");
		assertEquals(6, hits.length, "slash probes Flash's six block hit points");
		assertEquals("30,0:29", hits[5], "slash passes reach as block damage force");
		assertEquals("29,-9", playerHits[0], "slash hits local player with Flash recoil");
		assertEquals("0,0", sounds[0], "slash plays swish at start position");
		assertEquals(250, slash.scheduledRemoveMsForTests(), "slash schedules six Flash frames at 24fps");
		assertEquals(true, slash.hasScheduledRemoveForTests(), "slash owns its removal timer");

		slash.remove();
		assertEquals(false, slash.hasScheduledRemoveForTests(), "slash removal clears scheduled timer");
		assertEquals(0, slash.numChildren, "slash removal disposes authored animation");
	}

	private static function testLeftSlashShooterFilteringAndScale():Void {
		var playerHits = 0;
		var slash = new Slash(100, 20, "left", 7, {
			level: new ServerLevel(0xffffff, []),
			courseRotation: 0,
			player: {
				tempId: 7,
				x: 42,
				y: 90,
				removed: false,
				hit: function(_, _):Void playerHits++
			},
			playSound: function(_, _):Void {}
		});
		assertEquals(-1.0, slash.scaleX, "left slash mirrors the authored animation");
		assertEquals(-29, slash.reach, "left slash reverses reach");
		assertEquals(0, playerHits, "slash ignores the shooter");
		slash.remove();
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
