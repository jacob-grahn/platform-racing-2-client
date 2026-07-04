package pr2.lobby;

import pr2.lobby.dialogs.DiscordVerificationPopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.UploadingPopup;

class DiscordVerificationPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var savedUserName = LobbySession.userName;
		var savedPostFactory = UploadingPopup.postFactory;
		closeAll();

		var posts:Array<{url:String, fields:Map<String, String>}> = [];
		UploadingPopup.postFactory = function(url:String, fields:Map<String, String>, onResult:String->Void, onError:String->Void):Void {
			posts.push({url: url, fields: fields});
			onResult('{"success":true}');
		};
		LobbySession.userName = "  PR2 Name \n";
		LobbyPopups.lastRequest = "sentinel";
		LobbyPopups.showDiscordVerification("abc123");

		var open = Popup.getOpen();
		var popup = Std.downcast(open[open.length - 1], DiscordVerificationPopup);
		assertNotNull(popup, "discord verification route opens uploading popup");
		assertEquals("discordverify:abc123", LobbyPopups.lastRequest, "route records verification request");
		assertEquals(1, posts.length, "verification posts once");
		assertEquals(DiscordVerificationPopup.VERIFY_URL, posts[0].url, "verification endpoint");
		assertEquals("abc123", posts[0].fields.get("code"), "verification posts code");
		assertEquals("PR2 Name", posts[0].fields.get("pr2_name"), "verification trims PR2 name");
		assertEquals("Verifying...", LobbyArt.text(popup, "textBox").text, "verification upload label");

		LobbySession.userName = savedUserName;
		UploadingPopup.postFactory = savedPostFactory;
		closeAll();
		trace('DiscordVerificationPopupTest passed $assertions assertions');
	}

	private static function closeAll():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) throw message;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
