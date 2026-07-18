package pr2.lobby;

import openfl.events.Event;
import openfl.events.MouseEvent;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.PMRFCodesPopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.SendMessagePopup;
import pr2.lobby.dialogs.SendMessageView;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.net.ServerConfig;
import pr2.util.TestDisplayUtil as DisplayUtil;

/**
	Verifies the lobby social-action route for composing a private message opens
	the authored popup directly instead of recording a placeholder request.
**/
class SendMessagePopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testEntryPoint();
		if (pr2.DeterministicTestMode.finishSmokeSuite("SendMessagePopupTest")) return;
		testExactViewAndNestedCodes();
		testValidationAndUploadFlows();
		closeAll();
		trace('SendMessagePopupTest passed $assertions assertions');
	}

	private static function testExactViewAndNestedCodes():Void {
		closeAll();
		var popup = new SendMessagePopup("Jiggmin", "Hello");
		var view = findView(popup);
		assertNear(-166.5, view.panel.x, "message ShadowBG keeps XFL X");
		assertNear(-109.9, view.panel.y, "message ShadowBG keeps XFL Y");
		assertNear(1.2242431640625, view.panel.scaleX, "message ShadowBG keeps XFL horizontal scale");
		assertNear(1.0732421875, view.panel.scaleY, "message ShadowBG keeps XFL vertical scale");
		assertEquals("To:", view.toLabel.text, "message recipient label keeps exact authored copy");
		assertEquals("NEVER give your password to ANYONE.", view.warning.text, "message warning keeps exact authored copy");
		assertNear(-44, view.nameInput.x, "recipient input keeps XFL X");
		assertNear(197.996520996094, view.nameInput.controlWidth, "recipient input keeps authored horizontal scale");
		assertNear(-155, view.messageInput.x, "message area keeps XFL X");
		assertNear(309.109497070313, view.messageInput.controlWidth, "message area keeps authored horizontal scale");
		assertNear(50.0082397460936, view.messageInput.controlHeight, "message area keeps authored vertical scale");
		assertEquals("5 / 1000", view.charsRemaining.text, "message counter starts from supplied body length");
		view.messageInput.text = "1234567";
		view.messageInput.textField.dispatchEvent(new Event(Event.CHANGE));
		assertEquals("7 / 1000", view.charsRemaining.text, "message counter follows real TextArea changes");
		view.codesButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertNotNull(lastPopup(PMRFCodesPopup), "authored info button opens formatting reference");
		popup.remove();
		closeAll();
	}

	private static function testValidationAndUploadFlows():Void {
		var popup = new SendMessagePopup("", "body");
		findView(popup).sendButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertNotNull(lastPopup(MessagePopup), "missing recipient opens validation popup");
		popup.remove();
		closeAll();

		popup = new SendMessagePopup("Target", "");
		findView(popup).sendButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertNotNull(lastPopup(MessagePopup), "missing body opens validation popup");
		popup.remove();
		closeAll();

		var savedPost = UploadingPopup.postFactory;
		var captured:Null<{url:String, fields:Map<String, String>}> = null;
		UploadingPopup.postFactory = function(url:String, fields:Map<String, String>, onResult:String->Void, onError:String->Void):Void {
			captured = {url: url, fields: fields};
			onResult("{}");
		};
		popup = new SendMessagePopup("Target", "Hello there");
		findView(popup).sendButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(ServerConfig.messageSendUrl(), captured.url, "private message uses real endpoint");
		assertEquals("Target", captured.fields.get("to_name"), "private message forwards recipient");
		assertEquals("Hello there", captured.fields.get("message"), "private message forwards body");
		assertEquals(true, popup.fadeOutStarted, "successful upload fades compose popup");
		popup.remove();
		closeAll();

		var guildPopup = new SendMessagePopup("Guild", "Announcement", true);
		var guildView = findView(guildPopup);
		assertEquals(false, guildView.nameInput.editable, "guild recipient is authored read-only");
		guildView.sendButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(ServerConfig.guildMessageUrl(), captured.url, "guild message uses real endpoint");
		guildPopup.remove();
		UploadingPopup.postFactory = savedPost;
		closeAll();
	}

	private static function findView(popup:SendMessagePopup):SendMessageView {
		for (index in 0...popup.numChildren) {
			var view = Std.downcast(popup.getChildAt(index), SendMessageView);
			if (view != null) return view;
		}
		throw "SendMessageView missing";
	}

	private static function lastPopup<T:Popup>(type:Class<T>):Null<T> {
		for (value in Popup.getOpen().copy()) {
			var found = Std.downcast(value, type);
			if (found != null) return found;
		}
		return null;
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

	private static function assertNear(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000001) throw '$message: expected $expected, got $actual';
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
