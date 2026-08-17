package pr2.effects;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.level.ObjectCodes;
import pr2.level.Level;
import pr2.level.Level.LevelBlock;

class SlashTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		pr2.DeterministicTestMode.runTest("SlashTest.testRightSlashAnimationProbesSoundAndRemoval", testRightSlashAnimationProbesSoundAndRemoval);
		pr2.DeterministicTestMode.runTest("SlashTest.testExactMineFrames", testExactMineFrames);
		pr2.DeterministicTestMode.runTest("SlashTest.testExactMinePieceFrames", testExactMinePieceFrames);
		pr2.DeterministicTestMode.runTest("SlashTest.testExactBlockPieceFrames", testExactBlockPieceFrames);
		if (pr2.DeterministicTestMode.finishSmokeSuite("SlashTest")) return;
		pr2.DeterministicTestMode.runTest("SlashTest.testLeftSlashShooterFilteringAndScale", testLeftSlashShooterFilteringAndScale);
		pr2.DeterministicTestMode.runTest("SlashTest.testRotatedRemoteSlashUsesSenderFrame", testRotatedRemoteSlashUsesSenderFrame);
		trace('SlashTest passed $assertions assertions');
	}

	private static function testExactBlockPieceFrames():Void {
		var brick = new BlockPiece("BrickPieceGraphic", BlockPiece.GRAVITY, BlockPiece.FRICTION, BlockPiece.FADE_RATE, 10, 10, 10, 0, 0,
			function():Float return 0);
		assertEquals(1, brick.selectedFrame, "brick piece random selection reaches authored frame one");
		assertEquals("assets/svg/effects/brick_piece_01.svg", brick.visual.name, "brick piece uses the exact composed XFL frame");
		brick.remove();
		var crumble = new BlockPiece("CrumblePieceGraphic", BlockPiece.GRAVITY, BlockPiece.FRICTION, BlockPiece.FADE_RATE, 10, 10, 10, 0, 0,
			function():Float return 0);
		assertEquals("assets/svg/effects/crumble_piece_01.svg", crumble.visual.name, "crumble piece uses the exact composed XFL frame");
		crumble.remove();
	}

	private static function testExactMinePieceFrames():Void {
		var piece = new BlockPiece("MinePieceGraphic", BlockPiece.GRAVITY, BlockPiece.FRICTION, BlockPiece.FADE_RATE, 10, 10, 10, 0, 0,
			function():Float return 0.999);
		assertEquals(6, piece.selectedFrame, "mine piece random selection reaches authored frame six");
		assertEquals("assets/svg/effects/mine_piece_06.svg", piece.visual.name, "mine piece uses the exact composed XFL frame without a manual transform");
		piece.remove();
	}

	private static function testExactMineFrames():Void {
		var animation = new NativeEffectAnimation("mine", MineExplosion.LIFETIME_FRAMES);
		assertEquals("assets/effects/mine.lottie.json", animation.timeline.sourcePath, "mine explosion uses semantic Lottie data");
		assertEquals(1, animation.currentFrame, "mine explosion starts on authored frame one");
		for (_ in 1...MineExplosion.LIFETIME_FRAMES) animation.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(14, animation.currentFrame, "mine explosion reaches its authored stop frame");
		animation.dispose();
	}

	private static function testRightSlashAnimationProbesSoundAndRemoval():Void {
		var blocks = [
			LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 0, -30),
			LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 0, 0),
			LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 30, -30),
			LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 30, 0),
			LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 60, -30),
			LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 60, 0)
		];
		var hits:Array<String> = [];
		var playerHits:Array<String> = [];
		var sounds:Array<String> = [];
		var slash = new Slash(0, 0, "right", 7, {
			level: Level.fromDecoded(0xffffff, blocks),
			courseRotation: 0,
			player: {
				tempId: 9,
				x: 58,
				y: 70,
				removed: false,
				hit: function(vx:Float, vy:Float):Void playerHits.push('$vx,$vy')
			},
			onBlockDamage: function(block, reach):Void hits.push('${block.worldX},${block.worldY}:$reach'),
			playSound: function(x:Float, y:Float):Void sounds.push('$x,$y')
		});

		assertEquals(Slash.LIFETIME_FRAMES, slash.animation.totalFrames, "slash uses the six-frame native animation");
		assertEquals("assets/effects/slash.lottie.json", slash.animation.timeline.sourcePath, "slash uses semantic Lottie data");
		assertEquals(1, slash.animation.currentFrame, "slash starts on authored frame one");
		assertEquals(6, hits.length, "slash probes Flash's six block hit points");
		assertEquals("30,0:29", hits[5], "slash passes reach as block damage force");
		assertEquals("29,-9", playerHits[0], "slash hits local player with Flash recoil");
		assertEquals("0,0", sounds[0], "slash plays swish at start position");
		assertEquals(250, slash.scheduledRemoveMsForTests(), "slash schedules six Flash frames at 24fps");
		assertEquals(true, slash.hasScheduledRemoveForTests(), "slash owns its removal timer");

		var holder = new Sprite();
		holder.addChild(slash);
		for (_ in 0...5) slash.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(slash, holder.getChildAt(0), "slash remains visible for its first five authored frames");
		slash.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(false, slash.hasScheduledRemoveForTests(), "slash removal clears scheduled timer");
		assertEquals(0, slash.numChildren, "slash removal disposes authored animation");
		assertEquals(0, holder.numChildren, "slash removes after its sixth rendered frame");
	}

	private static function testLeftSlashShooterFilteringAndScale():Void {
		var playerHits = 0;
		var slash = new Slash(100, 20, "left", 7, {
			level: Level.fromDecoded(0xffffff, []),
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

	private static function testRotatedRemoteSlashUsesSenderFrame():Void {
		var hits:Array<String> = [];
		var slash = new Slash(15, 0, "right", 7, {
			level: Level.fromDecoded(0xffffff, [LevelBlock.fromWorldPixels(ObjectCodes.BLOCK_BASIC1, 0, -60)]),
			courseRotation: 0,
			senderRotation: 90,
			onBlockDamage: function(block, _):Void hits.push('${block.worldX},${block.worldY}'),
			playSound: function(_, _):Void {}
		});
		assertEquals(0.0, slash.x, "remote slash origin is reprojected into the receiver frame");
		assertEquals(-15.0, slash.y, "remote slash keeps the sender's canonical origin");
		assertEquals(-90.0, slash.rotation, "remote slash artwork follows the sender-to-receiver rotation");
		assertEquals("0,-60", hits[0], "remote slash probes blocks in the sender's gravity frame");
		slash.remove();
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
