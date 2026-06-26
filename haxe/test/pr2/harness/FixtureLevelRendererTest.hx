package pr2.harness;

import pr2.level.BlockType;
import pr2.level.FixtureLevel;
import pr2.level.FixtureLevel.LevelBlock;
import pr2.level.FixtureLevel.StatDefaults;
import pr2.level.FixtureLevel.TilePosition;
import pr2.level.LevelFixtureParser;
import sys.io.File;

class FixtureLevelRendererTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testFlatFixtureRendererCreatesGridAndBlocks();
		testSyncsVanishBlockAlpha();
		testSyncsDepletedItemBlockColor();
		testRemovedBlockAssets();
		trace('FixtureLevelRendererTest passed $assertions assertions');
	}

	private static function testSyncsDepletedItemBlockColor():Void {
		var level = new FixtureLevel("item", "Item", 5, 5, 30, 1, new StatDefaults(50, 1, 3), new TilePosition(2, 3),
			new TilePosition(0, 0), [new LevelBlock(2, 1, BlockType.Item, "3"), new LevelBlock(2, 4, BlockType.Solid)]);
		var player = new LocalPlayerController(level);
		var renderer = new FixtureLevelRenderer(level, false);
		for (_ in 0...40) {
			player.step(new LocalPlayerInput(false, false, true));
			if (player.debugState().itemId == 3) break;
		}

		renderer.syncBlockVisuals(player);
		var transform = renderer.getChildAt(1).transform.colorTransform;
		assertEquals(0.5, transform.redMultiplier, "renderer applies depleted item red multiplier");
		assertEquals(0.5, transform.greenMultiplier, "renderer applies depleted item green multiplier");
		assertEquals(0.5, transform.blueMultiplier, "renderer applies depleted item blue multiplier");
	}

	private static function testRemovedBlockAssets():Void {
		assertEquals("assets/blocks/brick.png", FixtureLevelRenderer.blockAssetPath(BlockType.Brick), "brick asset path");
		assertEquals("assets/blocks/mine_block.png", FixtureLevelRenderer.blockAssetPath(BlockType.Mine), "mine asset path");
		assertEquals("assets/blocks/crumble.png", FixtureLevelRenderer.blockAssetPath(BlockType.Crumble), "crumble asset path");
	}

	private static function testSyncsVanishBlockAlpha():Void {
		var level = new FixtureLevel("vanish", "Vanish", 5, 5, 30, 1, new StatDefaults(50, 1, 3), new TilePosition(2, 2),
			new TilePosition(0, 0), [new LevelBlock(2, 3, BlockType.Vanish)]);
		var player = new LocalPlayerController(level);
		var renderer = new FixtureLevelRenderer(level, false);

		player.step(new LocalPlayerInput());
		renderer.syncBlockVisuals(player);
		assertEquals(0.9, renderer.getChildAt(1).alpha, "renderer applies vanish fade alpha");
	}

	private static function testFlatFixtureRendererCreatesGridAndBlocks():Void {
		var fixture = LevelFixtureParser.parse(File.getContent("assets/fixtures/flat-level.json"));
		var renderer = new FixtureLevelRenderer(fixture, false);

		assertEquals(fixture.blocks.length + 1, renderer.numChildren, "renderer child count");
		assertEquals(2 * fixture.tileSize, renderer.getChildAt(1).x, "start block x");
		assertEquals(9 * fixture.tileSize, renderer.getChildAt(1).y, "start block y");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

}
