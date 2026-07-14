package pr2.lobby;

import openfl.events.TextEvent;
import openfl.text.TextField;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.UploadingPopup;

class HtmlNameMakerTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testGroupColors();
		if (pr2.DeterministicTestMode.finishSmokeSuite("HtmlNameMakerTest")) return;
		testHtmlRendering();
		testInviteAndDiscordRoutes();
		testRemoveUnregistersEveryField();
		trace('HtmlNameMakerTest passed $assertions assertions');
	}

	private static function testGroupColors():Void {
		assertEquals("047B7B", HtmlNameMaker.groupColor("1,0"), "regular member color");
		assertEquals("BC9055", HtmlNameMaker.groupColor("1,1"), "ambassador color");
		assertEquals("006400", HtmlNameMaker.groupColor("2,0"), "trial moderator color");
		assertEquals("0092FF", HtmlNameMaker.groupColor("2,1"), "moderator color");
		assertEquals("1C369F", HtmlNameMaker.groupColor("2"), "admin fallback color");
		assertEquals("870A6F", HtmlNameMaker.groupColor("3"), "higher admin color");
		assertEquals("676666", HtmlNameMaker.groupColor("0"), "guest color");
		assertEquals("83C141", HtmlNameMaker.groupColor("1,*"), "special user color");
	}

	private static function testHtmlRendering():Void {
		var maker = new HtmlNameMaker();
		assertEquals('<u><font color="#0092FF"><a href="event:user`2`Mod &amp;">Display &lt;&gt;</a></font></u>',
			maker.makeName("Mod &", "2,1", "Display <>"), "makeName uses parsed group color and escaped labels");
		assertEquals('<u><font color="#0000FF"><a href="event:url`https://example.com/a%20path?x=1&amp;y=two#hash">Go &amp;</a></font></u>',
			maker.makeLink("Go &", "https://example.com/a path?x=1&y=two#hash"), "makeLink uses Flash encodeURI-style escaping");

		var compat = new com.jiggmin.data.HTMLNameMaker();
		assertEquals(maker.makeGuild("Guild", 5), compat.makeGuild("Guild", 5), "AS-style package facade delegates to HtmlNameMaker");
	}

	private static function testInviteAndDiscordRoutes():Void {
		var savedPostFactory = UploadingPopup.postFactory;
		UploadingPopup.postFactory = function(url:String, fields:Map<String, String>, onResult:String->Void, onError:String->Void):Void {
			onResult("{}");
		};
		var maker = new HtmlNameMaker();
		var field = new TextField();
		maker.listenForLink(field);

		LobbyPopups.lastRequest = "sentinel";
		field.dispatchEvent(new TextEvent(TextEvent.LINK, false, false, "invite`45"));
		assertEquals("invite:45", LobbyPopups.lastRequest, "invite links route to guild join popup boundary");

		field.dispatchEvent(new TextEvent(TextEvent.LINK, false, false, "discordverify`abc123"));
		assertEquals("discordverify:abc123", LobbyPopups.lastRequest, "Discord verification links route to verification popup boundary");
		maker.remove();
		UploadingPopup.postFactory = savedPostFactory;
		closeAll();
	}

	private static function testRemoveUnregistersEveryField():Void {
		var maker = new HtmlNameMaker();
		var field1 = new TextField();
		var field2 = new TextField();
		maker.listenForLink(field1);
		maker.listenForLink(field2);
		maker.remove();

		LobbyPopups.lastRequest = "sentinel";
		field1.dispatchEvent(new TextEvent(TextEvent.LINK, false, false, "invite`12"));
		field2.dispatchEvent(new TextEvent(TextEvent.LINK, false, false, "discordverify`deadbeef"));
		assertEquals("sentinel", LobbyPopups.lastRequest, "remove detaches all registered link listeners");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function closeAll():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}
}
