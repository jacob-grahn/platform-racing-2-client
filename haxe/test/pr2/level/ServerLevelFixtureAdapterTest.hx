package pr2.level;

import pr2.harness.LocalPlayerController;
import pr2.level.ServerLevel.DecodedBlock;

class ServerLevelFixtureAdapterTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testConvertsServerCoordinatesToFixtureTiles();
		testPreservesBlockOptions();
		testBlockTypesMatchInitialCollisionBehavior();
		trace('ServerLevelFixtureAdapterTest passed $assertions assertions');
	}

	private static function testConvertsServerCoordinatesToFixtureTiles():Void {
		var level = new ServerLevel(0xFFFFFF, [
			new DecodedBlock(ObjectCodes.BLOCK_START1, 10020, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10050, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_FINISH, 10110, 10050)
		]);
		var converted = ServerLevelFixtureAdapter.convert(level, 1, "50815", "Campaign");
		var fixture = converted.fixture;

		assertEquals("50815", fixture.id, "fixture id");
		assertEquals("Campaign", fixture.name, "fixture name");
		assertEquals(30, fixture.tileSize, "fixture tile size");
		assertEquals(4, fixture.playerStart.x, "start tile x includes padding");
		assertEquals(3, fixture.playerStart.y, "start tile is air above start block");
		assertEquals(7, fixture.finish.x, "finish tile x");
		assertEquals(3, fixture.finish.y, "finish tile is air above finish block");
		assertEquals(3, fixture.blocks.length, "block count preserved");

		var playerStartWorldX = converted.fixturePixelToWorldX(fixture.playerStart.x * fixture.tileSize);
		var playerFeetWorldY = converted.fixturePixelToWorldY((fixture.playerStart.y + 1) * fixture.tileSize);
		assertEquals(10020.0, playerStartWorldX, "start world x round trip");
		assertEquals(10050.0, playerFeetWorldY, "start feet world y round trip");

		var player = new LocalPlayerController(fixture);
		assertEquals(10035.0, converted.fixturePixelToWorldX(player.x), "player spawns centered on start block");
		assertEquals(10050.0, converted.fixturePixelToWorldY(player.y), "player feet spawn on top of start block");
	}

	private static function testPreservesBlockOptions():Void {
		var level = new ServerLevel(0xFFFFFF, [
			new DecodedBlock(ObjectCodes.BLOCK_START1, 10020, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_TELEPORT, 10050, 10050, "255")
		]);
		var fixture = ServerLevelFixtureAdapter.convert(level, 1).fixture;
		var teleport = fixture.blockAt(5, 4);

		assertEquals(BlockType.Teleport, teleport.type, "teleport type preserved");
		assertEquals("255", teleport.options, "teleport options preserved");
	}

	private static function testBlockTypesMatchInitialCollisionBehavior():Void {
		assertEquals(BlockType.Start, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_START4), "start code");
		assertEquals(BlockType.Finish, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_FINISH), "finish code");
		assertEquals(BlockType.Basic, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_BASIC3), "basic code");
		assertEquals(BlockType.Ice, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_ICE), "ice code");
		assertEquals(BlockType.ArrowDown, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_ARROW_DOWN), "arrow down code");
		assertEquals(BlockType.ArrowUp, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_ARROW_UP), "arrow up code");
		assertEquals(BlockType.ArrowLeft, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_ARROW_LEFT), "arrow left code");
		assertEquals(BlockType.ArrowRight, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_ARROW_RIGHT), "arrow right code");
		assertEquals(BlockType.Mine, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_MINE), "mine code");
		assertEquals(BlockType.Item, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_ITEM), "item code");
		assertEquals(BlockType.InfiniteItem, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_ITEM_INF), "infinite item code");
		assertEquals(BlockType.Crumble, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_CRUMBLE), "crumble code");
		assertEquals(BlockType.Vanish, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_VANISH), "vanish code");
		assertEquals(BlockType.Move, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_MOVE), "move code");
		assertEquals(BlockType.Water, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_WATER), "water code");
		assertEquals(false, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_WATER).isSolid(), "water inactive collision");
		assertEquals(BlockType.RotateRight, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_ROTATE_RIGHT), "rotate right code");
		assertEquals(BlockType.RotateLeft, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_ROTATE_LEFT), "rotate left code");
		assertEquals(BlockType.Push, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_PUSH), "push code");
		assertEquals(BlockType.Safety, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_SAFETY), "safety code");
		assertEquals(false, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_SAFETY).isSolid(), "safety inactive collision");
		assertEquals(BlockType.Teleport, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_TELEPORT), "teleport code");
		assertEquals(BlockType.CustomStats, ServerLevelFixtureAdapter.blockType(ObjectCodes.BLOCK_CUSTOM_STATS), "custom stats code");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
