package pr2.lobby;

import openfl.events.MouseEvent;
import pr2.lobby.dialogs.ExternalLinkPopup;
import pr2.lobby.dialogs.Popup;

class ExternalLinkPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var navigated:Array<String> = [];
		ExternalLinkPopup.navigate = function(url:String):Void navigated.push(url);
		LobbyPopups.lastRequest = "sentinel";

		LobbyPopups.openUrl("https://pr2hub.com/path?q=one%20two");
		var open = Popup.getOpen();
		var popup = Std.downcast(open[open.length - 1], ExternalLinkPopup);
		assertNotNull(popup, "external URL opens the authored warning popup");
		assertEquals("https://pr2hub.com/path?q=one%20two", LobbyArt.text(popup, "linkBox").text, "link is shown verbatim");
		assertEquals("sentinel", LobbyPopups.lastRequest, "external URL route is no longer record-only");
		assertEquals(0, navigated.length, "opening the popup does not navigate");

		click(popup, "proceed_bt");
		assertEquals("https://pr2hub.com/path?q=one%20two", navigated[0], "proceed opens the requested URL");
		assertEquals(true, popup.fadeOutStarted, "proceed closes the popup");
		popup.remove();

		var replaced = new ExternalLinkPopup("https://example.com/old");
		var canceled = new ExternalLinkPopup("https://example.com/new");
		assertEquals(true, replaced.fadeOutStarted, "a new external-link popup replaces the old one");
		replaced.remove();
		click(canceled, "close_bt");
		assertEquals(1, navigated.length, "close does not navigate");
		assertEquals(true, canceled.fadeOutStarted, "close fades out the popup");
		canceled.remove();
		ExternalLinkPopup.resetNavigator();
		trace('ExternalLinkPopupTest passed $assertions assertions');
	}

	private static function click(popup:ExternalLinkPopup, name:String):Void {
		var target = LobbyArt.findByName(popup, name);
		if (target == null) throw name + " missing";
		target.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
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
