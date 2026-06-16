package pr2.harness;

import pr2.level.LevelFixtureParser;
import sys.io.File;

class FixtureLevelRendererTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testFlatFixtureRendererCreatesGridAndBlocks();
		trace('FixtureLevelRendererTest passed $assertions assertions');
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
