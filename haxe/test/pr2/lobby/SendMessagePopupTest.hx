package pr2.lobby;

import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.SendMessagePopup;

/**
	Verifies the lobby social-action route for composing a private message opens
	the authored popup directly instead of recording a placeholder request.
**/
class SendMessagePopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testEntryPoint();
		if (pr2.DeterministicTestMode.finishSmokeSuite("SendMessagePopupTest")) return;
		closeAll();
		trace('SendMessagePopupTest passed $assertions assertions');
	}

	private static function testEntryPoint():Void {
		closeAll();
		LobbyPopups.lastRequest = "sentinel";
		LobbyPopups.sendMessage("Jiggmin");
		var open = Popup.getOpen();
		var popup = Std.downcast(open[open.length - 1], SendMessagePopup);
		assertNotNull(popup, "sendMessage opens a SendMessagePopup");
		assertEquals("Jiggmin", LobbyArt.text(popup, "nameBox").text, "recipient is prefilled");
		assertEquals("sentinel", LobbyPopups.lastRequest, "send-message route is no longer record-only");
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
