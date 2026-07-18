package pr2.gameplay;

import openfl.text.TextField;
import openfl.text.TextFieldType;
import pr2.net.LobbySocket;
import pr2.page.CampaignTestScreen;

class RaceChatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testAuthoredInputAndSubmitCallback();
		if (pr2.DeterministicTestMode.finishSmokeSuite("RaceChatTest")) return;
		testIncomingChatFormatting();
		testMessageWindow();
		testPopupTextAreaEnterGuard();
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
		assertEquals(45.0, RaceChat.textBox.x, "input uses authored x");
		assertEquals(129.7, RaceChat.textBox.y, "input uses authored y");
		assertEquals(100.0, RaceChat.textBox.width, "input uses authored width");
		assertEquals(14.545115661621095, RaceChat.textBox.height, "input uses authored transformed height");
		assertEquals(100, RaceChat.textBox.maxChars, "input preserves authored character limit");
		var geometry = chat.authoredGeometry();
		assertEquals(2.0, geometry[4], "top transcript uses authored x");
		assertEquals(2.0, geometry[5], "top transcript uses authored y");
		assertEquals(141.0, geometry[6], "top transcript uses authored width");
		assertEquals(116.01104278564453, geometry[7], "top transcript uses authored transformed height");
		assertEquals(3.0, geometry[8], "shadow transcript keeps authored one-pixel x offset");
		assertEquals(3.0, geometry[9], "shadow transcript keeps authored one-pixel y offset");
		assertEquals(0.999664306640625, geometry[10], "input preserves authored vertical matrix");
		assertEquals(0.999664306640625, geometry[11], "top transcript preserves authored vertical matrix");
		assertEquals(0.999664306640625, geometry[12], "shadow transcript preserves child vertical matrix");
		assertEquals(1.00079345703125, geometry[13], "shadow transcript preserves parent vertical matrix");
		assertEquals(1.0, geometry[14], "input preserves authored layer order above white label");
		assertEquals(3.0, geometry[15], "shadow transcript preserves authored layer below top transcript");
		assertEquals(4.0, geometry[16], "top transcript remains the topmost authored layer");
		RaceChat.textBox.text = " /debug` ";
		assertEquals(true, chat.submitText(RaceChat.textBox.text), "debug command handled by callback");
		assertEquals(" /debug ", sent[0], "submit strips the Flash socket delimiter");
		assertEquals("", chat.inputText(), "submit clears the authored input");

		assertEquals(true, chat.submitText("hello"), "normal chat submits through the game socket route");
		assertEquals("hello", sent[1], "normal chat is forwarded");
		assertEquals("chat`hello", LobbySocket.lastSent(), "normal race chat emits Flash chat command");
		chat.submitText("two\nlines");
		assertEquals("chat`twolines", LobbySocket.lastSent(), "normal race chat removes embedded newlines like page.Chat");
		assertEquals(true, CampaignTestScreen.isRaceChatFixtureCommand(" /CHATFIXTURE "),
			"live course fixture command is whitespace/case tolerant");
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
		chat.receiveSystemMessage("Visit <u>this</u>");
		assertEquals(true, chat.outputHtml().indexOf("Visit <u>this</u>") >= 0, "trusted system chat preserves authored html");
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
		var scroll = chat.transcriptScroll();
		assertEquals(scroll[1], scroll[0], "top transcript remains locked to its bottom line");
		assertEquals(scroll[3], scroll[2], "shadow transcript remains locked to its bottom line");
		chat.remove();
	}

	private static function testPopupTextAreaEnterGuard():Void {
		var popupBody = new TextField();
		popupBody.type = TextFieldType.INPUT;
		popupBody.multiline = true;
		assertEquals(true, RaceChat.isMultilineInputTarget(popupBody),
			"race Enter shortcut ignores native multiline popup text areas like Flash");
		popupBody.multiline = false;
		assertEquals(false, RaceChat.isMultilineInputTarget(popupBody),
			"single-line fields still transfer Enter focus to race chat");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
