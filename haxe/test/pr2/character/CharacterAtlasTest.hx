package pr2.character;

import sys.io.File;

class CharacterAtlasTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testParsesPartSetAtlas();
		testLayeredChannelsCoverEveryExportedPart();
		trace('CharacterAtlasTest passed $assertions assertions');
	}

	private static function testParsesPartSetAtlas():Void {
		var atlas = CharacterAtlas.parse(
			File.getContent("assets/character/atlases/part-sets/001/atlas@4x.json"),
			"assets/character/atlases/part-sets/001/atlas@4x.json"
		);
		var headStatic = atlas.getFrame("head/static");

		assertEquals(1, atlas.page, "page");
		assertEquals(1, atlas.pages, "pages");
		assertEquals("assets/character/atlases/part-sets/001/atlas@4x.webp", atlas.assetImagePath, "asset image path");
		assertNotNull(headStatic, "head/static frame");
		assertEquals(1, headStatic.id, "head/static id");
		assertEquals("head", headStatic.kind, "head/static kind");
		assertEquals("static", headStatic.channel, "head/static channel");
		assertEquals(4, headStatic.scale, "head/static scale");
		assertEquals("head/static", atlas.getFrameName("head", "static", 1), "frame name by kind/channel/id");
		assertEquals(null, atlas.getFrameName("head", "static", 999), "missing frame name by kind/channel/id");
	}

	private static function testLayeredChannelsCoverEveryExportedPart():Void {
		for (atlas in loadCharacterAtlases()) {
			var parts = new Map<String, Map<String, Bool>>();
			for (name in atlas.frames.keys()) {
				var frame = atlas.frames.get(name);
				var key = frame.kind + ":" + frame.id;
				var channels = parts.get(key);
				if (channels == null) {
					channels = new Map();
					parts.set(key, channels);
				}
				channels.set(frame.channel, true);
			}
			for (key in parts.keys()) {
				var channels = parts.get(key);
				assertEquals(true, channels.exists("static"), '$key static coverage');
				assertEquals(true, channels.exists("primary"), '$key primary coverage');
				assertEquals(true, channels.exists("secondary"), '$key secondary coverage');
			}
		}
	}

	private static function loadCharacterAtlases():Array<CharacterAtlas> {
		var atlases:Array<CharacterAtlas> = [];
		for (path in jsonPaths("assets/character/atlases")) {
			atlases.push(CharacterAtlas.parse(File.getContent(path), path));
		}
		return atlases;
	}

	private static function jsonPaths(path:String):Array<String> {
		var paths:Array<String> = [];
		if (!sys.FileSystem.exists(path)) {
			return paths;
		}
		for (name in sys.FileSystem.readDirectory(path)) {
			var child = path + "/" + name;
			if (sys.FileSystem.isDirectory(child)) {
				paths = paths.concat(jsonPaths(child));
			} else if (StringTools.endsWith(name, ".json")) {
				paths.push(child);
			}
		}
		return paths;
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
