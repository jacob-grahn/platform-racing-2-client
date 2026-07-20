package pr2.level;

import pr2.gameplay.player.LocalPlayerController;
import pr2.level.Level.LevelBlock;

class LevelTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testDecodedWorldCoordinates();
		if (pr2.DeterministicTestMode.finishSmokeSuite("LevelTest")) return;
		testNegativeWorldCoordinates();
		testRotationUsesWorldOrigin();
		testOptionsAndOverlappingMarkers();
		testOverlappingRuntimeBlocksUseLastLoadedBlock();
		testBlockTypeMapping();
		trace('LevelTest passed $assertions assertions');
	}

	private static function testDecodedWorldCoordinates():Void {
		var world = decoded([
			block(ObjectCodes.BLOCK_START1, 10020, 10050),
			block(ObjectCodes.BLOCK_BASIC1, 10050, 10050),
			block(ObjectCodes.BLOCK_FINISH, 10110, 10050)
		]);
		world.configureRuntime("50815", "Campaign", 1);

		assertEquals("50815", world.id, "world id");
		assertEquals("Campaign", world.name, "world name");
		assertEquals(30, world.tileSize, "world tile size");
		assertEquals(334, world.playerStart.x, "start keeps authored world tile x");
		assertEquals(334, world.playerStart.y, "start tile is world air above start block");
		assertEquals(337, world.finish.x, "finish keeps authored world tile x");
		assertEquals(334, world.finish.y, "finish is world air above finish block");
		assertEquals(330, world.minTileX, "world bounds retain left padding");
		assertEquals(3, world.blocks.length, "spawn marker remains in the authoritative collection");
		assertEquals(null, world.blockAt(334, 335), "spawn marker is excluded from collision lookup");

		var player = new LocalPlayerController(world);
		assertEquals(10035.0, player.x, "player spawns centered in world coordinates");
		assertEquals(10050.0, player.y, "player feet spawn in world coordinates");
	}

	private static function testNegativeWorldCoordinates():Void {
		var world = decoded([
			block(ObjectCodes.BLOCK_START1, -60, -30),
			block(ObjectCodes.BLOCK_BASIC1, -30, -30)
		]);
		assertEquals(-2, world.playerStart.x, "negative start x is preserved");
		assertEquals(-2, world.playerStart.y, "negative start air tile is preserved");
		assertEquals(BlockType.Basic, world.blockAt(-1, -1).type, "negative collision tile is addressable");
		assertEquals(true, world.containsTile(-2, -2), "negative tile lies inside explicit world bounds");
	}

	private static function testRotationUsesWorldOrigin():Void {
		var world = decoded([
			block(ObjectCodes.BLOCK_START1, 10020, 10050),
			block(ObjectCodes.BLOCK_BASIC1, 10020, 10050)
		]);
		var player = new LocalPlayerController(world);
		@:privateAccess player.rotateDirection = 1;
		@:privateAccess player.finishRotation();
		assertEquals(-10050.0, player.x, "right rotation transforms authored world y about zero");
		assertEquals(10035.0, player.y, "right rotation transforms authored world x about zero");
		assertEquals(90, player.courseRotation, "right rotation commits one world quarter turn");
	}

	private static function testOptionsAndOverlappingMarkers():Void {
		var teleport = block(ObjectCodes.BLOCK_TELEPORT, 10020, 10050, "255");
		var world = decoded([block(ObjectCodes.BLOCK_START1, 10020, 10050), teleport]);
		var collision = world.blockAt(334, 335);
		assertEquals(teleport, collision, "spawn marker is skipped during collision lookup");
		assertEquals(BlockType.Teleport, collision.type, "teleport type is derived from its exact code");
		assertEquals("255", collision.options, "block options remain on the authoritative object");
	}

	private static function testOverlappingRuntimeBlocksUseLastLoadedBlock():Void {
		var world = decoded([
			block(ObjectCodes.BLOCK_BASIC1, 10050, 10050),
			block(ObjectCodes.BLOCK_MINE, 10050, 10050)
		]);
		assertEquals(BlockType.Mine, world.blockAt(335, 335).type, "later runtime block wins collision lookup");
	}

	private static function testBlockTypeMapping():Void {
		var mappings = [
			{code: ObjectCodes.BLOCK_START4, type: BlockType.Start},
			{code: ObjectCodes.BLOCK_FINISH, type: BlockType.Finish},
			{code: ObjectCodes.BLOCK_BASIC3, type: BlockType.Basic},
			{code: ObjectCodes.BLOCK_ICE, type: BlockType.Ice},
			{code: ObjectCodes.BLOCK_MINE, type: BlockType.Mine},
			{code: ObjectCodes.BLOCK_ITEM, type: BlockType.Item},
			{code: ObjectCodes.BLOCK_CRUMBLE, type: BlockType.Crumble},
			{code: ObjectCodes.BLOCK_VANISH, type: BlockType.Vanish},
			{code: ObjectCodes.BLOCK_MOVE, type: BlockType.Move},
			{code: ObjectCodes.BLOCK_WATER, type: BlockType.Water},
			{code: ObjectCodes.BLOCK_PUSH, type: BlockType.Push},
			{code: ObjectCodes.BLOCK_SAFETY, type: BlockType.Safety},
			{code: ObjectCodes.BLOCK_TELEPORT, type: BlockType.Teleport},
			{code: ObjectCodes.BLOCK_BRICK, type: BlockType.Brick},
			{code: ObjectCodes.BLOCK_HEART, type: BlockType.Heart}
		];
		for (mapping in mappings) {
			assertEquals(mapping.type, LevelBlock.typeForCode(mapping.code), 'block type for ${mapping.code}');
		}
		assertEquals(false, LevelBlock.typeForCode(ObjectCodes.BLOCK_START4).isSolid(), "start excluded from collision");
		assertEquals(false, LevelBlock.typeForCode(ObjectCodes.BLOCK_WATER).isSolid(), "water excluded from solid collision");
		assertEquals(false, LevelBlock.typeForCode(ObjectCodes.BLOCK_SAFETY).isSolid(), "safety excluded from solid collision");
	}

	private static function decoded(blocks:Array<LevelBlock>):Level return Level.fromDecoded(0xFFFFFF, blocks);

	private static function block(code:Int, worldX:Int, worldY:Int, options:String = ""):LevelBlock {
		return LevelBlock.fromWorldPixels(code, worldX, worldY, options);
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
