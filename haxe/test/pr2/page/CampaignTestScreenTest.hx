package pr2.page;

import pr2.net.CampaignLevelInfo;

class CampaignTestScreenTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testParsesCampaignQueryValues();
		testSelectsRequestedLevelFromCampaignPage();
		testDebugTextHiddenByDefault();
		testDebugChatCommandTogglesOverlay();
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

	private static function testDebugTextHiddenByDefault():Void {
		var screen = new CampaignTestScreen();
		assertEquals(false, screen.isDebugTextVisible(), "campaign debug text starts hidden");
		screen.remove();
	}

	private static function testDebugChatCommandTogglesOverlay():Void {
		assertEquals(true, CampaignTestScreen.isDebugChatCommand("/debug"), "debug command recognized");
		assertEquals(true, CampaignTestScreen.isDebugChatCommand("  /DeBuG  "), "debug command ignores case and edge whitespace");
		assertEquals(false, CampaignTestScreen.isDebugChatCommand("/debug now"), "debug command rejects extra text");
		assertEquals(false, CampaignTestScreen.isDebugChatCommand("hello"), "normal chat is not a debug command");

		var screen = new CampaignTestScreen();
		assertEquals(false, screen.handleRaceChatLine("hello"), "normal chat is not handled by debug route");
		assertEquals(false, screen.isDebugTextVisible(), "normal chat leaves debug text hidden");
		assertEquals(true, screen.handleRaceChatLine("/debug"), "debug chat route handles command");
		assertEquals(true, screen.isDebugTextVisible(), "debug command shows debug text");
		assertEquals(true, screen.handleRaceChatLine(" /debug "), "debug chat route handles trimmed command");
		assertEquals(false, screen.isDebugTextVisible(), "second debug command hides debug text");
		screen.remove();
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
