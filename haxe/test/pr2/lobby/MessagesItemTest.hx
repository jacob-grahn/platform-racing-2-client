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
		testFilterSettingAndTrustedHtml();
		testMessageBodyLinksStayClickable();
		testTimestampDisplayAndHover();
		testActionButtonHoverWrappers();
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
}
