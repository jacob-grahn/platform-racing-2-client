package pr2.page;

import pr2.net.CampaignLevelInfo;

class CampaignTestScreenTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testParsesCampaignQueryValues();
		testSelectsRequestedLevelFromCampaignPage();
		trace('CampaignTestScreenTest passed $assertions assertions');
	}

	private static function testParsesCampaignQueryValues():Void {
		assertEquals(1, CampaignTestScreen.parsePage(null), "null page defaults");
		assertEquals(1, CampaignTestScreen.parsePage("0"), "zero page defaults");
		assertEquals(6, CampaignTestScreen.parsePage(" 6 "), "valid page parses");
		assertEquals(null, CampaignTestScreen.parseRequestedLevelId(null), "null level omitted");
		assertEquals(null, CampaignTestScreen.parseRequestedLevelId("bad"), "bad level omitted");
		assertEquals(null, CampaignTestScreen.parseRequestedLevelId("-5"), "negative level omitted");
		assertEquals(50815, CampaignTestScreen.parseRequestedLevelId(" 50815 "), "valid level parses");
	}

	private static function testSelectsRequestedLevelFromCampaignPage():Void {
		var levels = [
			level(50815, 7, "Newbieland 2"),
			level(123, 2, "Second Course")
		];

		assertEquals(null, CampaignTestScreen.selectLevel([], 1), "empty page has no level");
		assertEquals(50815, CampaignTestScreen.selectLevel(levels, null).levelId, "missing request selects first");
		assertEquals(123, CampaignTestScreen.selectLevel(levels, 123).levelId, "matching request selects level");
		assertEquals(50815, CampaignTestScreen.selectLevel(levels, 999).levelId, "missing request falls back");
	}

	private static function level(levelId:Int, version:Int, title:String):CampaignLevelInfo {
		return new CampaignLevelInfo(levelId, version, title, "Tester", 0, 0, 0);
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
