package pr2.character;

import sys.io.File;

class CharacterAtlasTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testParsesHatPrimaryAtlas();
		testLayeredChannelsCoverEveryExportedPart();
		testParsesRenderMode();
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
		assertEquals("002_exp", atlas.getFrameNameById(2), "frame name by id");
		assertEquals(null, atlas.getFrameNameById(999), "missing frame name by id");
	}

	private static function testParsesRenderMode():Void {
		assertEquals(CharacterRenderMode.Layered, CharacterRenderMode.parse(null), "null render mode defaults to layered");
		assertEquals(CharacterRenderMode.Layered, CharacterRenderMode.parse("layered"), "layered render mode");
		assertEquals(CharacterRenderMode.Composite, CharacterRenderMode.parse(" composite "), "composite render mode");
		assertEquals(CharacterRenderMode.Composite, CharacterRenderMode.parse("debug"), "debug render mode alias");
		assertEquals("composite", CharacterRenderMode.Composite.toLabel(), "render mode label");
	}

	private static function testLayeredChannelsCoverEveryExportedPart():Void {
		for (kind in ["hat", "head", "body", "feet"]) {
			var staticAtlases = loadAtlases(kind, "static");
			var primaryAtlases = loadAtlases(kind, "primary");
			var secondaryAtlases = loadAtlases(kind, "secondary");
			for (id in 1...51) {
				var exported = hasFrame(staticAtlases, id);
				assertEquals(exported, hasFrame(primaryAtlases, id), '$kind $id primary coverage');
				assertEquals(exported, hasFrame(secondaryAtlases, id), '$kind $id secondary coverage');
			}
		}
	}

	private static function loadAtlases(kind:String, channel:String):Array<CharacterAtlas> {
		var base = 'vector-art/atlases/character/$kind/$channel@4x';
		var paths = [base + "-p01.json", base + "-p02.json", base + ".json"];
		var atlases:Array<CharacterAtlas> = [];
		for (path in paths) {
			if (sys.FileSystem.exists(path)) {
				atlases.push(CharacterAtlas.parse(File.getContent(path), path));
			}
		}
		return atlases;
	}

	private static function hasFrame(atlases:Array<CharacterAtlas>, id:Int):Bool {
		for (atlas in atlases) {
			if (atlas.getFrameNameById(id) != null) {
				return true;
			}
		}
		return false;
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
