package pr2.level;

import pr2.harness.LocalPlayerController;
import pr2.level.ServerLevel.DecodedBlock;

class ServerLevelWorldAdapterTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testPreservesServerWorldTiles();
		testPreservesNegativeWorldTiles();
		testRotationUsesWorldOrigin();
		testPreservesBlockOptions();
		testOverlappingStartMarkerUsesRuntimeCollisionBlock();
		testOverlappingRuntimeBlocksUseLastLoadedBlock();
		testBlockTypesMatchInitialCollisionBehavior();
		trace('ServerLevelWorldAdapterTest passed $assertions assertions');
	}

	private static function testPreservesServerWorldTiles():Void {
		var level = new ServerLevel(0xFFFFFF, [
			new DecodedBlock(ObjectCodes.BLOCK_START1, 10020, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10050, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_FINISH, 10110, 10050)
		]);
		var world = ServerLevelWorldAdapter.convert(level, 1, "50815", "Campaign");

		assertEquals("50815", world.id, "world id");
		assertEquals("Campaign", world.name, "world name");
		assertEquals(30, world.tileSize, "world tile size");
		assertEquals(334, world.playerStart.x, "start keeps authored world tile x");
		assertEquals(334, world.playerStart.y, "start tile is world air above start block");
		assertEquals(337, world.finish.x, "finish keeps authored world tile x");
		assertEquals(334, world.finish.y, "finish is world air above finish block");
		assertEquals(330, world.minTileX, "world bounds retain left padding");
		assertEquals(2, world.blocks.length, "spawn marker omitted from runtime blocks");

		var player = new LocalPlayerController(world);
		assertEquals(10035.0, player.x, "player spawns centered in world coordinates");
		assertEquals(10050.0, player.y, "player feet spawn in world coordinates");
	}

	private static function testPreservesNegativeWorldTiles():Void {
		var level = new ServerLevel(0xFFFFFF, [
			new DecodedBlock(ObjectCodes.BLOCK_START1, -60, -30),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, -30, -30)
		]);
		var world = ServerLevelWorldAdapter.convert(level, 1);
		assertEquals(-2, world.playerStart.x, "negative start x is preserved");
		assertEquals(-2, world.playerStart.y, "negative start air tile is preserved");
		assertEquals(BlockType.Basic, world.blockAt(-1, -1).type, "negative collision tile is addressable");
		assertEquals(true, world.containsTile(-2, -2), "negative tile lies inside explicit world bounds");
		var player = new LocalPlayerController(world);
		assertEquals(-45.0, player.x, "player can spawn at a negative world x");
		assertEquals(-30.0, player.y, "player can spawn at a negative world y");
	}

	private static function testRotationUsesWorldOrigin():Void {
		var level = new ServerLevel(0xFFFFFF, [
			new DecodedBlock(ObjectCodes.BLOCK_START1, 10020, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050)
		]);
		var player = new LocalPlayerController(ServerLevelWorldAdapter.convert(level, 1));
		@:privateAccess player.rotateDirection = 1;
		@:privateAccess player.finishRotation();
		assertEquals(-10050.0, player.x, "right rotation transforms authored world y about zero");
		assertEquals(10035.0, player.y, "right rotation transforms authored world x about zero");
		assertEquals(90, player.courseRotation, "right rotation commits one world quarter turn");
	}

	private static function testPreservesBlockOptions():Void {
		var level = new ServerLevel(0xFFFFFF, [
			new DecodedBlock(ObjectCodes.BLOCK_START1, 10020, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_TELEPORT, 10050, 10050, "255")
		]);
		var world = ServerLevelWorldAdapter.convert(level, 1);
		var teleport = world.blockAt(335, 335);

		assertEquals(BlockType.Teleport, teleport.type, "teleport type preserved");
		assertEquals("255", teleport.options, "teleport options preserved");
	}

	private static function testOverlappingStartMarkerUsesRuntimeCollisionBlock():Void {
		var level = new ServerLevel(0xFFFFFF, [
			new DecodedBlock(ObjectCodes.BLOCK_START1, 10020, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_TELEPORT, 10020, 10050, "255")
		]);
		var world = ServerLevelWorldAdapter.convert(level, 1);
		var block = world.blockAt(334, 335);

		assertEquals(BlockType.Teleport, block.type, "spawn marker skipped before collision lookup");
		assertEquals("255", block.options, "overlapping runtime block preserves options");
	}

	private static function testOverlappingRuntimeBlocksUseLastLoadedBlock():Void {
		var level = new ServerLevel(0xFFFFFF, [
			new DecodedBlock(ObjectCodes.BLOCK_START1, 10020, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10050, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_MINE, 10050, 10050)
		]);
		var world = ServerLevelWorldAdapter.convert(level, 1);
		var block = world.blockAt(335, 335);

		assertEquals(BlockType.Mine, block.type, "later runtime block overwrites earlier block");
	}

	private static function testBlockTypesMatchInitialCollisionBehavior():Void {
		assertEquals(BlockType.Start, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_START4), "start code");
		assertEquals(false, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_START4).isSolid(), "start excluded from collision");
		assertEquals(BlockType.Finish, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_FINISH), "finish code");
		assertEquals(BlockType.Basic, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_BASIC3), "basic code");
		assertEquals(BlockType.Ice, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_ICE), "ice code");
		assertEquals(BlockType.ArrowDown, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_ARROW_DOWN), "arrow down code");
		assertEquals(BlockType.ArrowUp, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_ARROW_UP), "arrow up code");
		assertEquals(BlockType.ArrowLeft, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_ARROW_LEFT), "arrow left code");
		assertEquals(BlockType.ArrowRight, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_ARROW_RIGHT), "arrow right code");
		assertEquals(BlockType.Mine, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_MINE), "mine code");
		assertEquals(BlockType.Item, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_ITEM), "item code");
		assertEquals(BlockType.InfiniteItem, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_ITEM_INF), "infinite item code");
		assertEquals(BlockType.Crumble, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_CRUMBLE), "crumble code");
		assertEquals(BlockType.Vanish, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_VANISH), "vanish code");
		assertEquals(BlockType.Move, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_MOVE), "move code");
		assertEquals(BlockType.Water, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_WATER), "water code");
		assertEquals(false, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_WATER).isSolid(), "water inactive collision");
		assertEquals(BlockType.RotateRight, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_ROTATE_RIGHT), "rotate right code");
		assertEquals(BlockType.RotateLeft, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_ROTATE_LEFT), "rotate left code");
		assertEquals(BlockType.Push, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_PUSH), "push code");
		assertEquals(BlockType.Safety, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_SAFETY), "safety code");
		assertEquals(false, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_SAFETY).isSolid(), "safety inactive collision");
		assertEquals(BlockType.Teleport, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_TELEPORT), "teleport code");
		assertEquals(BlockType.CustomStats, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_CUSTOM_STATS), "custom stats code");
		assertEquals(BlockType.Brick, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_BRICK), "brick code");
		assertEquals(BlockType.Happy, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_HAPPY), "happy code");
		assertEquals(BlockType.Sad, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_SAD), "sad code");
		assertEquals(BlockType.Heart, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_HEART), "heart code");
		assertEquals(BlockType.Time, ServerLevelWorldAdapter.blockType(ObjectCodes.BLOCK_TIME), "time code");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
