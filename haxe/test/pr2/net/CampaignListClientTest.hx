package pr2.net;

import haxe.Json;
import haxe.crypto.Md5;

class CampaignListClientTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testParsesCampaignListAndValidatesHash();
		testRejectsMissingLevels();
		trace('CampaignListClientTest passed $assertions assertions');
	}

	private static function testParsesCampaignListAndValidatesHash():Void {
		var levelsJson = Json.stringify([
			{
				level_id: "50815",
				version: "7",
				title: "Newbieland 2",
				user_name: "Jiggmin",
				min_level: "0",
				rating: "4.5",
				play_count: "12345"
			},
			{
				level_id: 123,
				version: 2,
				title: "Second Course",
				user_name: "Tester",
				min_level: 1,
				rating: 3,
				play_count: 9
			}
		]);
		var body = signedList(levelsJson);
		var result = CampaignListClient.parse(body);

		assertEquals(true, result.hashValid, "valid campaign hash accepted");
		assertEquals(2, result.levels.length, "level count");
		assertEquals(50815, result.levels[0].levelId, "level id");
		assertEquals(7, result.levels[0].version, "version");
		assertEquals("Newbieland 2", result.levels[0].title, "title");
		assertEquals("Jiggmin", result.levels[0].userName, "user name");
		assertEquals(0, result.levels[0].minLevel, "min level");
		assertEquals(4.5, result.levels[0].rating, "rating");
		assertEquals(12345, result.levels[0].playCount, "play count");
		assertEquals('id=50815 v=7 "Newbieland 2" by Jiggmin', result.levels[0].describe(), "description");
		assertEquals(123, result.levels[1].levelId, "numeric level id");
	}

	private static function testRejectsMissingLevels():Void {
		var failed = false;
		try {
			CampaignListClient.parse('{"hash":"bad"}');
		} catch (error:Dynamic) {
			failed = true;
		}
		assertEquals(true, failed, "missing levels rejected");
	}

	private static function signedList(levelsJson:String):String {
		var hash = Md5.encode(levelsJson + ServerConfig.LEVEL_LIST_SALT);
		return '{"levels":' + levelsJson + ',"hash":"' + hash + '"}';
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
