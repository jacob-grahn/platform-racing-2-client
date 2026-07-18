package pr2.lobby;

import openfl.events.TextEvent;
import openfl.events.MouseEvent;
import openfl.ui.MouseCursor;
import pr2.lobby.account.Settings;
import pr2.lobby.dialogs.ExternalLinkPopup;
import pr2.lobby.dialogs.HoverDelayPopup;
import pr2.lobby.dialogs.MessagesItem;
import pr2.lobby.dialogs.Popup;

class MessagesItemTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		Settings.disablePersistenceForTests();
		testPrivateMessageBodyFormatting();
		if (pr2.DeterministicTestMode.finishSmokeSuite("MessagesItemTest")) return;
		testMessageTextStaysInsidePmPane();
		testExactAuthoredLayout();
		testFilterSettingAndTrustedHtml();
		testMessageBodyLinksStayClickable();
		testTimestampDisplayAndHover();
		testActionButtonHoverWrappers();
		testAuthoredActionButtonStates();
		testReportConfirmationCopy();
		trace('MessagesItemTest passed $assertions assertions');
	}

	private static function testPrivateMessageBodyFormatting():Void {
		Settings.setValue(Settings.FILTER_SWEARS, false);
		var item = new MessagesItem(null, 1, "Sender", "1,0",
			" <raw>\r[level=123]Level[/level] [guild=456]Guild[/guild] [invite=789]Invite[/invite] [user=2,1]Mod[/user] [url]https://example.com/a?x=1&y=2[/url] [url=https://example.com]Site[/url] ",
			false, 1700000000);
		var html = @:privateAccess item.bodyHtml();

		assertContains(html, "&lt;raw&gt;", "low-group messages escape raw HTML");
		assertContains(html, "<br>", "carriage returns become Flash br tags");
		assertContains(html, "event:level`123", "level rich link is parsed");
		assertContains(html, "event:guild`456", "guild rich link is parsed");
		assertContains(html, "event:invite`789", "invite rich link is parsed");
		assertContains(html, "event:user`2,1`Mod`1", "user rich link is parsed");
		assertContains(html, "event:url`https://example.com/a?x=1&y=2", "bare URL event unescapes ampersands");
		assertContains(html, "event:url`https://example.com", "named URL rich link is parsed");
		item.remove();
	}

	private static function testMessageTextStaysInsidePmPane():Void {
		Settings.setValue(Settings.FILTER_SWEARS, false);
		var item = new MessagesItem(null, 9, "Sender", "1",
			"averyveryveryveryveryveryveryveryveryverylongunbrokenmessage that should stay out of the scrollbar column", false, 1700000000);

		assertEquals(true, @:privateAccess item.bodyWordWrapEnabled(), "PM body text wraps inside the authored text field");
		assertEquals(1595, Math.round(@:privateAccess item.bodyTextWidth() * 10), "PM body keeps the authored text width");
		assertEquals(true, @:privateAccess item.messageBackgroundIsNineSlice(), "PM message background uses scale-grid art");
		item.remove();
	}

	private static function testExactAuthoredLayout():Void {
		var item = new MessagesItem(null, 11, "Sender", "1", "Body", true, 1700000000);
		var name = @:privateAccess item.authoredChild("nameBox");
		var body = @:privateAccess item.authoredChild("textBox");
		var time = @:privateAccess item.authoredChild("timeBox");
		var background = @:privateAccess item.authoredChild("bg");
		var guild = @:privateAccess item.authoredChild("guildMsgIcon");
		assertNotNull(name, "authored sender field exists");
		assertNotNull(body, "authored message field exists");
		assertNotNull(time, "authored date field exists");
		assertNotNull(background, "authored TextArea background exists");
		assertNotNull(guild, "authored everyone icon exists");
		assertClose(2, name.x, "sender field keeps XFL X");
		assertClose(6.95, name.y, "sender field keeps XFL Y");
		assertClose(5, body.x, "message field keeps XFL X");
		assertClose(29.95, body.y, "message field keeps XFL Y");
		assertClose(52, time.x, "date field keeps XFL X");
		assertClose(115.95, time.width, "date field keeps authored width");
		assertClose(24, background.y, "TextArea skin keeps XFL Y");
		assertClose(152 * 1.13815307617188, background.width, "TextArea skin keeps XFL horizontal scale");
		assertClose(157.55, guild.x, "everyone icon keeps XFL X");
		assertClose(8.2, guild.y, "everyone icon keeps XFL Y");
		assertClose(0.037689208984375, guild.scaleX, "everyone icon keeps XFL horizontal scale");
		assertClose(0.0379486083984375, guild.scaleY, "everyone icon keeps XFL vertical scale");
		assertEquals(true, guild.visible, "guild messages show the authored everyone icon");
		item.remove();

		var privateItem = new MessagesItem(null, 12, "Sender", "1", "Body", false, 1700000000);
		var privateGuild = @:privateAccess privateItem.authoredChild("guildMsgIcon");
		assertEquals(false, privateGuild.visible, "private messages hide the authored everyone icon");
		privateItem.remove();
	}

	private static function testActionButtonHoverWrappers():Void {
		var item = new MessagesItem(null, 7, "Sender", "1", "Body", false, 1700000000);
		var buttons = @:privateAccess item.actionButtons();
		assertEquals(3, buttons.length, "message item exposes three action hover wrappers");
		assertButton(buttons[0], "Report Message", "If this message is inappropriate, you can report it to the moderators.");
		assertButton(buttons[1], "Delete Message", "Erase this flimsy correspondence from existence.");
		assertButton(buttons[2], "Reply to Message", "You've got something to say, and someone's gonna hear it.");

		@:privateAccess buttons[0].showPopup();
		assertNotNull(buttons[0].hover, "report button can show delayed hover popup");
		item.remove();
		assertEquals(null, buttons[0].hover, "item remove cleans shown action-button hover popup");
	}

	private static function assertButton(button:HoverDelayPopup, title:String, content:String):Void {
		assertEquals(title, button.title, '$title title');
		assertEquals(content, button.content, '$title content');
	}

	private static function testAuthoredActionButtonStates():Void {
		var item = new MessagesItem(null, 10, "Sender", "1", "Body", false, 1700000000);
		var buttons = @:privateAccess item.actionButtons();
		var report = buttons[0];
		var delete = buttons[1];
		var reply = buttons[2];
		for (button in buttons) {
			assertEquals(2, button.numChildren, "authored up state has backing and icon");
			assertClose(-8, button.getChildAt(0).x, "authored up backing x");
			button.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
			assertClose(-9, button.getChildAt(0).x, "authored over backing x");
			assertClose(1.125, button.getChildAt(0).scaleX, "authored over backing scale");
			button.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
			assertEquals(1, button.numChildren, "authored down state hides the icon");
			button.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
			assertEquals(2, button.numChildren, "mouse up restores authored over icon");
		}
		assertClose(-2.25, report.getChildAt(1).x, "report over icon registration x");
		assertClose(-8.6, report.getChildAt(1).y, "report over icon registration y");
		assertClose(1.30987548828125, report.getChildAt(1).scaleX, "report over icon authored scale");
		assertClose(0, delete.getChildAt(1).x, "delete over icon keeps XFL origin");
		assertClose(0, reply.getChildAt(1).x, "reply over icon keeps XFL origin");
		item.remove();
	}

	private static function testReportConfirmationCopy():Void {
		var item = new MessagesItem(null, 8, "Sender", "1", "Body", false, 1700000000);
		@:privateAccess item.clickReport();
		var open = Popup.getOpen();
		var popup = open[open.length - 1];
		var textBox = LobbyArt.text(popup, "textBox");
		assertNotNull(textBox, "report confirmation has text");
		assertContains(textBox.htmlText, "asking for your password", "report confirmation includes password warning");
		assertContains(textBox.htmlText, "spamming your inbox", "report confirmation includes spam warning");
		item.remove();
	}

	private static function testFilterSettingAndTrustedHtml():Void {
		Settings.setValue(Settings.FILTER_SWEARS, true);
		var filtered = new MessagesItem(null, 2, "Sender", "1", "shit", false, 1700000000);
		assertContains(@:privateAccess filtered.bodyHtml(), "[...]", "enabled PM swear filter masks message body");
		filtered.remove();

		Settings.setValue(Settings.FILTER_SWEARS, false);
		var unfiltered = new MessagesItem(null, 3, "Sender", "1", "shit", false, 1700000000);
		assertContains(@:privateAccess unfiltered.bodyHtml(), "shit", "disabled PM swear filter preserves message body");
		unfiltered.remove();

		var trusted = new MessagesItem(null, 4, "Mod", "3", "<b>trusted</b>", false, 1700000000);
		assertContains(@:privateAccess trusted.bodyHtml(), "<b>trusted</b>", "high-group messages preserve trusted HTML");
		trusted.remove();
	}

	private static function testMessageBodyLinksStayClickable():Void {
		Settings.setValue(Settings.FILTER_SWEARS, false);
		var navigated:Array<String> = [];
		ExternalLinkPopup.navigate = function(url:String):Void navigated.push(url);
		var item = new MessagesItem(null, 5, "Sender", "1", "[url]https://example.com/path[/url]", false, 1700000000);
		var field = @:privateAccess item.bodyTextField();
		assertNotNull(field, "message item exposes a body text field");

		field.dispatchEvent(new TextEvent(TextEvent.LINK, false, false, "url`https://example.com/path"));
		var open = Popup.getOpen();
		assertEquals(true, Std.downcast(open[open.length - 1], ExternalLinkPopup) != null, "message body link listener opens URL popup");
		assertEquals(0, navigated.length, "clicking message URL opens confirmation before navigating");

		item.remove();
		ExternalLinkPopup.resetNavigator();
	}

	private static function testTimestampDisplayAndHover():Void {
		var item = new MessagesItem(null, 6, "Sender", "1", "Body", false, 1700000000);
		var field = @:privateAccess item.timeTextField();
		assertNotNull(field, "message item exposes a time text field");
		assertEquals("11/14/2023", field.text, "row time uses locale-style date instead of ISO");

		field.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals(MouseCursor.BUTTON, @:privateAccess item.currentCursorState(), "hover switches cursor to button");
		assertEquals(0x666666, field.textColor, "hover tints date gray");
		assertEquals("This message was sent on November 14, 2023 5:13:20 PM.", @:privateAccess item.sentTimeHoverContent(),
			"hover copy uses long date and medium time");

		field.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals(MouseCursor.AUTO, @:privateAccess item.currentCursorState(), "hover out restores cursor");
		assertEquals(0x000000, field.textColor, "hover out restores date color");
		item.remove();
	}

	private static function assertContains(value:String, needle:String, message:String):Void {
		assertions++;
		if (value.indexOf(needle) < 0) throw '$message: missing $needle in $value';
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) throw '$message: value was null';
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000001) throw '$message: expected $expected, got $actual';
	}
}
