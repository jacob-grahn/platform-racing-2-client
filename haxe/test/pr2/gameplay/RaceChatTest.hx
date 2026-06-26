package pr2.gameplay;

import pr2.net.LobbySocket;
import pr2.page.CampaignTestScreen;

class RaceChatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testAuthoredInputAndSubmitCallback();
		testIncomingChatFormatting();
		testMessageWindow();
		trace('RaceChatTest passed $assertions assertions');
	}

	private static function testAuthoredInputAndSubmitCallback():Void {
		LobbySocket.resetSent();
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

		assertEquals(true, chat.submitText("hello"), "normal chat submits through the game socket route");
		assertEquals("hello", sent[1], "normal chat is forwarded");
		assertEquals("chat`hello", LobbySocket.lastSent(), "normal race chat emits Flash chat command");
		chat.remove();
		assertEquals(null, RaceChat.textBox, "remove clears static input target");
		LobbySocket.resetSent();
	}

	private static function testIncomingChatFormatting():Void {
		var chat = new RaceChat();
		chat.receiveChatMessage("Player<One>", "1,0", "hello <world>");
		var html = chat.outputHtml();
		assertEquals(true, html.indexOf('event:user`1`Player&lt;One&gt;') >= 0, "incoming chat links escaped user name");
		assertEquals(true, html.indexOf('Player&lt;One&gt;</a>') >= 0, "incoming chat displays escaped user name");
		assertEquals(true, html.indexOf("<font color='#666666'>: hello &lt;world&gt;</font><br/>") >= 0,
			"incoming chat escapes message text");

		chat.receiveChatMessage("Guest", "0", "damn", false, true);
		assertEquals(true, chat.outputHtml().indexOf("[...]") >= 0, "incoming chat applies swear filter by default");

		chat.receiveChatMessage("Fred", "3,*", "raw <b>hint</b>", true);
		html = chat.outputHtml();
		assertEquals(true, html.indexOf("<i><u><font") >= 0, "fred chat is italicized");
		assertEquals(true, html.indexOf("raw <b>hint</b>") >= 0, "fred chat preserves authored html");
		chat.remove();
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
