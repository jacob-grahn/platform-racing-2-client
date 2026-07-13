package pr2.level;

import pr2.level.WorldLevel.LevelBlock;
import sys.io.File;

class WorldLevelParserTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testFlatFixture();
		testValidationRejectsBadBlockTypes();
		testValidationRejectsOutOfBoundsPositions();
		trace('WorldLevelParserTest passed $assertions assertions');
	}

	private static function testFlatFixture():Void {
		var fixture = WorldLevelParser.parse(File.getContent("assets/fixtures/flat-level.json"));

		assertEquals("flat-level", fixture.id, "fixture id");
		assertEquals(18, fixture.widthTiles, "fixture width");
		assertEquals(12, fixture.heightTiles, "fixture height");
		assertEquals(30, fixture.tileSize, "fixture PR2 tile size");
		assertEquals(1, fixture.gravity, "fixture gravity multiplier");
		assertEquals(55, fixture.stats.speed, "fixture speed default");
		assertEquals(1.2, fixture.stats.acceleration, "fixture acceleration default");
		assertEquals(12, fixture.stats.jump, "fixture jump default");
		assertEquals(2, fixture.playerStart.x, "fixture start x");
		assertEquals(8, fixture.playerStart.y, "fixture start y");
		assertEquals(16, fixture.finish.x, "fixture finish x");
		assertEquals(8, fixture.finish.y, "fixture finish y");
		assertEquals(20, fixture.blocks.length, "fixture block count");

		assertBlock(fixture.blockAt(2, 9), Start, "start block", false);
		assertBlock(fixture.blockAt(16, 9), Finish, "finish block");
		assertBlock(fixture.blockAt(0, 10), Basic, "ground block");
		assertEquals(null, fixture.blockAt(0, 0), "empty tile lookup");
		assertBlock(WorldLevelParser.parse(minimalFixture('"type":"crumble"')).blockAt(1, 2), Crumble, "crumble block");
		assertBlock(WorldLevelParser.parse(minimalFixture('"type":"item","options":"4"')).blockAt(1, 2), Item, "item block");
		assertBlock(WorldLevelParser.parse(minimalFixture('"type":"infinite_item","options":"4"')).blockAt(1, 2), InfiniteItem, "infinite item block");
		assertBlock(WorldLevelParser.parse(minimalFixture('"type":"vanish"')).blockAt(1, 2), Vanish, "vanish block");
		var teleport = WorldLevelParser.parse(minimalFixture('"type":"teleport","options":"255"')).blockAt(1, 2);
		assertBlock(teleport, Teleport, "teleport block");
		assertEquals("255", teleport.options, "teleport options");
	}

	private static function testValidationRejectsBadBlockTypes():Void {
		assertThrows(function() {
			WorldLevelParser.parse(minimalFixture('"type":"mystery"'));
		}, "unknown block types are rejected");
	}

	private static function testValidationRejectsOutOfBoundsPositions():Void {
		assertThrows(function() {
			WorldLevelParser.parse(minimalFixture('"type":"basic","x":99'));
		}, "out-of-bounds blocks are rejected");
		assertThrows(function() {
			WorldLevelParser.parse(minimalFixture('"type":"basic"', '"playerStart":{"x":99,"y":1},'));
		}, "out-of-bounds starts are rejected");
	}

	private static function minimalFixture(blockFields:String, ?overrideStart:String):String {
		var start = overrideStart == null ? '"playerStart":{"x":1,"y":1},' : overrideStart;
		return '{'
			+ '"id":"test",'
			+ '"name":"Test",'
			+ '"widthTiles":4,'
			+ '"heightTiles":4,'
			+ '"tileSize":30,'
			+ '"gravity":1,'
			+ '"stats":{"speed":55,"acceleration":1.2,"jump":12},'
			+ start
			+ '"finish":{"x":2,"y":1},'
			+ '"blocks":[{"x":1,"y":2,' + blockFields + '}]'
			+ '}';
	}

	private static function assertBlock(block:Null<LevelBlock>, expected:BlockType, message:String, solid:Bool = true):Void {
		assertNotNull(block, message);
		assertEquals(expected, block.type, message + " type");
		assertEquals(solid, block.type.isSolid(), message + " solid");
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) {
			throw message;
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertThrows(action:Void->Void, message:String):Void {
		assertions++;
		try {
			action();
		} catch (_:Dynamic) {
			return;
		}
		throw message;
	}
}
