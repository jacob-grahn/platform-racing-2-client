package pr2.character;

import sys.io.File;

class CharacterAtlasTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testParsesHatPrimaryAtlas();
		trace('CharacterAtlasTest passed $assertions assertions');
	}

	private static function testParsesHatPrimaryAtlas():Void {
		var atlas = CharacterAtlas.parse(
			File.getContent("vector-art/atlases/character/hat/primary@4x.json"),
			"assets/character/atlases/hat/primary@4x.json"
		);
		var exp = atlas.getFrame("002_exp");

		assertEquals("hat", atlas.kind, "kind");
		assertEquals("primary", atlas.channel, "channel");
		assertEquals(1, atlas.page, "page");
		assertEquals(1, atlas.pages, "pages");
		assertEquals("assets/character/atlases/hat/primary@4x.png", atlas.assetImagePath, "asset image path");
		assertNotNull(exp, "002_exp frame");
		assertEquals(2, exp.id, "002_exp id");
		assertEquals(4, exp.scale, "002_exp scale");
		assertEquals(437, exp.frame.x, "002_exp frame x");
		assertEquals(482, exp.frame.height, "002_exp frame height");
		assertEquals(false, exp.sourceTrim.empty, "002_exp sourceTrim empty");
		assertEquals(-356, exp.sourceTrim.x, "002_exp sourceTrim x");
		assertEquals(-351, exp.sourceTrim.y, "002_exp sourceTrim y");
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) {
			throw '$message: expected non-null value';
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
