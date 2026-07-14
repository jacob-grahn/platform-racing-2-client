package pr2.lobby;

import openfl.events.TextEvent;
import openfl.text.TextField;
import pr2.lobby.dialogs.ExternalLinkPopup;
import pr2.lobby.dialogs.PMRFCodesPopup;
import pr2.lobby.dialogs.Popup;

class PMRFCodesPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testReferenceLinksUseHtmlNameMakerPayloads();
		if (pr2.DeterministicTestMode.finishSmokeSuite("PMRFCodesPopupTest")) return;
		testRemoveUnregistersLinkListener();
		trace('PMRFCodesPopupTest passed $assertions assertions');
	}

	private static function testReferenceLinksUseHtmlNameMakerPayloads():Void {
		var popup = new PMRFCodesPopup();
		var links = linksBox(popup);
		assertContains(links.htmlText, "event:url`https://pr2hub.com/", "PR2 Hub URL link payload");
		assertContains(links.htmlText, "PR2 Hub Website", "PR2 Hub text link label");
		assertContains(links.htmlText, "event:user`3`Jiggmin", "Jiggmin username link payload");
		assertContains(links.htmlText, "event:level`50815", "Newbieland 2 level link payload");
		assertContains(links.htmlText, "event:guild`183", "PR2 Staff guild link payload");
		popup.remove();
		closeAll();
	}

	private static function testRemoveUnregistersLinkListener():Void {
		var popup = new PMRFCodesPopup();
		var links = linksBox(popup);
		var before = Popup.getOpen().length;
		links.dispatchEvent(new TextEvent(TextEvent.LINK, false, false, "url`https://pr2hub.com/"));
		assertEquals(before + 1, Popup.getOpen().length, "registered PMRF link opens external-link popup");
		var opened = Std.downcast(Popup.getOpen()[Popup.getOpen().length - 1], ExternalLinkPopup);
		assertNotNull(opened, "PMRF URL link opens external-link popup type");
		assertEquals("https://pr2hub.com/", opened.url, "PMRF URL link forwards href");

		popup.remove();
		var afterRemove = Popup.getOpen().length;
		links.dispatchEvent(new TextEvent(TextEvent.LINK, false, false, "url`https://pr2hub.com/"));
		assertEquals(afterRemove, Popup.getOpen().length, "removed PMRF popup detaches link listener");
		closeAll();
	}

	private static function linksBox(popup:PMRFCodesPopup):TextField {
		var links = LobbyArt.text(popup, "linksBox");
		if (links == null) throw "linksBox missing";
		return links;
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
		if (value == null) throw message;
	}

	private static function closeAll():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}
}
