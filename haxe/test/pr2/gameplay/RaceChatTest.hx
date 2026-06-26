package pr2.gameplay;

import pr2.page.CampaignTestScreen;

class RaceChatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testAuthoredInputAndSubmitCallback();
		testMessageWindow();
		trace('RaceChatTest passed $assertions assertions');
	}

	private static function testAuthoredInputAndSubmitCallback():Void {
		var sent:Array<String> = [];
		var chat = new RaceChat(function(message:String):Bool {
			sent.push(message);
			return CampaignTestScreen.isDebugChatCommand(message);
		});
		assertEquals(true, RaceChat.textBox != null, "race chat exposes authored input focus target");
		RaceChat.textBox.text = " /debug` ";
		assertEquals(true, chat.submitText(RaceChat.textBox.text), "debug command handled by callback");
		assertEquals(" /debug ", sent[0], "submit strips the Flash socket delimiter");
		assertEquals("", chat.inputText(), "submit clears the authored input");

		assertEquals(false, chat.submitText("hello"), "normal chat remains available for the game socket route");
		assertEquals("hello", sent[1], "normal chat is forwarded");
		chat.remove();
		assertEquals(null, RaceChat.textBox, "remove clears static input target");
	}

	private static function testMessageWindow():Void {
		var chat = new RaceChat();
		for (i in 0...8) {
			chat.displayMessage('line$i<br/>');
		}
		var html = chat.outputHtml();
		assertEquals(false, html.indexOf("line0") >= 0, "oldest message drops after seven race lines");
		assertEquals(true, html.indexOf("line1") >= 0, "newer messages remain visible");
		assertEquals(true, html.indexOf("line7") >= 0, "latest message remains visible");
		chat.remove();
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
