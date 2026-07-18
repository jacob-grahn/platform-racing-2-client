package pr2.lobby;

import openfl.events.MouseEvent;
import openfl.text.TextFieldType;
import pr2.lobby.dialogs.ExternalLinkPopup;
import pr2.lobby.dialogs.ExternalLinkView;
import pr2.lobby.dialogs.Popup;
import pr2.util.TestDisplayUtil as DisplayUtil;

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
		if (pr2.DeterministicTestMode.finishSmokeSuite("ExternalLinkPopupTest")) return;
		assertEquals("https://pr2hub.com/path?q=one%20two", LobbyArt.text(popup, "linkBox").text, "link is shown verbatim");
		assertEquals("sentinel", LobbyPopups.lastRequest, "external URL route is no longer record-only");
		assertEquals(0, navigated.length, "opening the popup does not navigate");
		var art = findView(popup);
		assertNotNull(art, "external link popup mounts the typed authored view");
		assertEquals(-150.0, art.topPanel.x, "upper ShadowBG keeps its XFL X");
		assertEquals(-155.0, art.topPanel.y, "upper ShadowBG keeps its XFL Y");
		assertEquals(0.523590087890625, art.topPanel.scaleY, "upper ShadowBG keeps its XFL vertical scale");
		assertEquals(-45.0, art.bodyPanel.y, "warning ShadowBG keeps its separate XFL Y");
		assertEquals(1.04719543457031, art.bodyPanel.scaleY, "warning ShadowBG keeps its XFL vertical scale");
		assertEquals(-142.5, art.linkArea.x, "link TextArea keeps its XFL X");
		assertEquals(-147.5, art.linkArea.y, "link TextArea keeps its XFL Y");
		assertEquals(285.000610351562, art.linkArea.controlWidth, "link TextArea keeps its authored width");
		assertEquals(TextFieldType.DYNAMIC, art.linkArea.textField.type, "authored link TextArea is selectable but not editable");
		assertEquals("Proceed", art.proceedButton.label, "proceed button keeps its XFL label");
		assertEquals("Go Back", art.closeButton.label, "close button keeps its exact XFL label");

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
		var target = DisplayUtil.findByName(popup, name);
		if (target == null) throw name + " missing";
		target.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	}

	private static function findView(popup:ExternalLinkPopup):ExternalLinkView {
		for (index in 0...popup.numChildren) {
			var view = Std.downcast(popup.getChildAt(index), ExternalLinkView);
			if (view != null) return view;
		}
		return null;
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
