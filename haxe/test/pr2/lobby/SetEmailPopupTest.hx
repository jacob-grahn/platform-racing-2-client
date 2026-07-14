package pr2.lobby;

import haxe.Json;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import pr2.crypto.PR2Encryptor;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.SetEmailPopup;
import pr2.net.ServerConfig;
import pr2.runtime.FlTextInput;
import pr2.util.DisplayUtil;

class SetEmailPopupTest {
	private static inline var ACCOUNT_CHANGE_KEY:String = "KVhFJSVLNigvKkdhV0RaSw==";
	private static inline var ACCOUNT_CHANGE_IV:String = "QEFUZCskMnhhdk8rYlFLKg==";

	private static var assertions:Int = 0;

	public static function main():Void {
		var savedUploadFactory = SetEmailPopup.uploadFactory;
		ServerConfig.setHost("http://example.test");
		testValidation();
		if (pr2.DeterministicTestMode.finishSmokeSuite("SetEmailPopupTest")) return;
		testEncryptedUploadFromEnterKey();
		testCancel();
		SetEmailPopup.uploadFactory = savedUploadFactory;
		ServerConfig.resetHost();
		closeAll();
		trace('SetEmailPopupTest passed $assertions assertions');
	}

	private static function testValidation():Void {
		var uploads = 0;
		SetEmailPopup.uploadFactory = function(url:String, fields:Map<String, String>, label:String):Null<pr2.lobby.dialogs.UploadingPopup> {
			uploads++;
			return null;
		};

		var popup = new SetEmailPopup();
		input(popup, "passBox").text = "pass";
		click(popup, "ok_bt");
		assertEquals(0, uploads, "blank email does not upload");
		assertEquals("Please fill in all of the fields.", lastMessageText(), "blank field error copy");
		closeAll();

		popup = new SetEmailPopup();
		input(popup, "email1Box").text = "one@example.test";
		input(popup, "email2Box").text = "two@example.test";
		input(popup, "passBox").text = "pass";
		click(popup, "ok_bt");
		assertEquals(0, uploads, "mismatched emails do not upload");
		assertEquals("The emails don't match. Please re-check them.", lastMessageText(), "mismatch error copy");
		closeAll();
	}

	private static function testEncryptedUploadFromEnterKey():Void {
		var uploads:Array<{url:String, fields:Map<String, String>, label:String}> = [];
		SetEmailPopup.uploadFactory = function(url:String, fields:Map<String, String>, label:String):Null<pr2.lobby.dialogs.UploadingPopup> {
			uploads.push({url: url, fields: fields, label: label});
			return null;
		};
		var popup = new SetEmailPopup();
		input(popup, "email1Box").text = "new@example.test";
		input(popup, "email2Box").text = "new@example.test";
		input(popup, "passBox").text = "secret";
		input(popup, "email2Box").dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, 13));

		assertEquals(1, uploads.length, "enter key submits email change");
		assertEquals(ServerConfig.accountChangeEmailUrl(), uploads[0].url, "email-change endpoint");
		assertEquals("Uploading...", uploads[0].label, "default upload label");
		var payload:Dynamic = Json.parse(PR2Encryptor.decryptBase64(uploads[0].fields.get("data"), ACCOUNT_CHANGE_KEY, ACCOUNT_CHANGE_IV));
		assertEquals("new@example.test", Reflect.field(payload, "email"), "payload includes email");
		assertEquals("secret", Reflect.field(payload, "pass"), "payload includes password");
		assertEquals(true, popup.fadeOutStarted, "successful submit fades the dialog");
		closeAll();
	}

	private static function testCancel():Void {
		var popup = new SetEmailPopup();
		click(popup, "cancel_bt");
		assertEquals(true, popup.fadeOutStarted, "cancel fades the dialog");
		closeAll();
	}

	private static function input(popup:SetEmailPopup, name:String):FlTextInput {
		var value = Std.downcast(DisplayUtil.findByName(popup, name), FlTextInput);
		if (value == null) throw name + " missing";
		return value;
	}

	private static function click(popup:SetEmailPopup, name:String):Void {
		var target = DisplayUtil.findByName(popup, name);
		if (target == null) throw name + " missing";
		target.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	}

	private static function lastMessageText():String {
		var open = Popup.getOpen();
		var message = Std.downcast(open[open.length - 1], MessagePopup);
		assertNotNull(message, "validation opens message popup");
		return LobbyArt.text(message, "textBox").text;
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
