package pr2.net;

import haxe.crypto.Md5;

class LevelDataClientTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testParsesAndVerifiesHash();
		testAndInsideValueRoundTrips();
		testHashMismatchReported();
		testEditorLoadRejectsBadOrEmptyPayloads();
		trace('LevelDataClientTest passed $assertions assertions');
	}

	private static function testParsesAndVerifiesHash():Void {
		var levelId = 42;
		var version = 3;
		var levelData = "level_id=42&version=3&title=Newbieland 2&gravity=2.5&max_time=120"
			+ "&items=Sword`Mine`Laser Gun&gameMode=race&data=m3`e0c8b8`1;2;13";
		var data = LevelDataClient.parse(signed(levelData, version, levelId), levelId, version);

		assertEquals(true, data.hashValid, "valid hash accepted");
		assertEquals(42, data.levelId, "level id");
		assertEquals("Newbieland 2", data.title, "title");
		assertEquals(2.5, data.gravity, "gravity");
		assertEquals(120, data.maxTime, "max time");
		assertEquals("race", data.gameMode, "game mode");
		assertEquals(3, data.items.length, "item count");
		assertEquals("Laser Gun", data.items[2], "item with space preserved");
		assertEquals("m3", data.readMode(), "read mode");
		assertEquals("m3`e0c8b8`1;2;13", data.data, "raw data preserved for the block decoder");
	}

	private static function testAndInsideValueRoundTrips():Void {
		// "Newbieland" and a note ending in "and" both contain the literal
		// "and" that validateSaveString splits on; they must survive intact.
		var levelData = "title=Newbieland&note=salt and pepper&data=m1`0`a";
		var validated = LevelDataClient.validateSaveString(levelData);
		assertEquals(levelData, validated, "literal 'and' inside values is restored");
	}

	private static function testHashMismatchReported():Void {
		var levelData = "level_id=7&version=1&title=Test&data=m3`0`";
		var tampered = levelData + Md5.encode("garbage");
		var data = LevelDataClient.parse(tampered, 7, 1);
		assertEquals(false, data.hashValid, "bad hash flagged but still parsed");
		assertEquals("Test", data.title, "fields still readable on hash mismatch");
	}

	private static function testEditorLoadRejectsBadOrEmptyPayloads():Void {
		var levelId = 8;
		var version = 2;
		var levelData = "level_id=8&version=2&title=Editor Load&has_pass=1&min_level=7&data=m4`abcdef````````````";
		var data = LevelDataClient.parseEditorLoad(signed(levelData, version, levelId), levelId, version);
		assertEquals(true, data.hashValid, "editor load requires a valid hash");
		assertEquals(levelData, data.saveString, "editor load preserves validated level vars");
		assertEquals("Editor Load", data.title, "editor load parses level title");

		assertThrows("did not download correctly", function():Void {
			LevelDataClient.parseEditorLoad(levelData + Md5.encode("garbage"), levelId, version);
		}, "editor load rejects hash mismatches");
		assertThrows("did not load", function():Void {
			LevelDataClient.parseEditorLoad(signed("", version, levelId), levelId, version);
		}, "editor load rejects empty level data");
	}

	private static function signed(levelData:String, version:Int, levelId:Int):String {
		return levelData + Md5.encode(Std.string(version) + Std.string(levelId) + levelData + ServerConfig.LEVEL_SALT_2);
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertThrows(part:String, fn:Void->Void, message:String):Void {
		assertions++;
		try {
			fn();
		} catch (error:Dynamic) {
			if (Std.string(error).indexOf(part) >= 0) {
				return;
			}
			throw '$message: wrong error ${Std.string(error)}';
		}
		throw '$message: expected an error containing $part';
	}
}
