package pr2.lobby;

import haxe.Json;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import pr2.crypto.PR2Encryptor;
import pr2.lobby.dialogs.ChangePasswordPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.net.ServerConfig;
import pr2.runtime.FlTextInput;
import pr2.util.DisplayUtil;

class ChangePasswordPopupTest {
	private static inline var LOGIN_KEY:String = "VUovam5GKndSMHFSSy9kSA==";
	private static inline var LOGIN_IV:String = "JmM5KnkqNXA9MVVOeC9Ucg==";

	private static var assertions:Int = 0;

	public static function main():Void {
		var savedUserName = LobbySession.userName;
		var savedUploadFactory = ChangePasswordPopup.uploadFactory;
		ServerConfig.setHost("http://example.test");
		LobbySession.userName = "Password Tester";

		testValidation();
		testEncryptedUploadFromEnterKey();
		testCancel();

		LobbySession.userName = savedUserName;
		ChangePasswordPopup.uploadFactory = savedUploadFactory;
		ServerConfig.resetHost();
		closeAll();
		trace('ChangePasswordPopupTest passed $assertions assertions');
	}

	private static function testValidation():Void {
		var uploads:Array<Dynamic> = [];
		ChangePasswordPopup.uploadFactory = function(url:String, fields:Map<String, String>, label:String):Null<pr2.lobby.dialogs.UploadingPopup> {
			uploads.push({url: url, fields: fields, label: label});
			return null;
		};

		var popup = new ChangePasswordPopup();
		assertPasswordInput(popup, "currentPassBox");
		assertPasswordInput(popup, "newPassBox1");
		assertPasswordInput(popup, "newPassBox2");
		input(popup, "currentPassBox").text = "old";
		input(popup, "newPassBox1").text = "new";
		input(popup, "newPassBox2").text = "different";
		click(popup, "ok_bt");
		assertEquals(0, uploads.length, "mismatched passwords do not upload");
		assertEquals("Error: The passwords don't match.", lastMessageText(), "mismatch error copy");
		closeAll();

		popup = new ChangePasswordPopup();
		input(popup, "currentPassBox").text = "same";
		input(popup, "newPassBox1").text = "same";
		input(popup, "newPassBox2").text = "same";
		click(popup, "ok_bt");
		assertEquals(0, uploads.length, "matching current/new passwords do not upload");
		assertEquals("Error: Your current and new passwords match. Try picking a new password.", lastMessageText(), "same-password error copy");
		closeAll();
	}

	private static function testEncryptedUploadFromEnterKey():Void {
		var uploads:Array<{url:String, fields:Map<String, String>, label:String}> = [];
		ChangePasswordPopup.uploadFactory = function(url:String, fields:Map<String, String>, label:String):Null<pr2.lobby.dialogs.UploadingPopup> {
			uploads.push({url: url, fields: fields, label: label});
			return null;
		};
		var popup = new ChangePasswordPopup();
		input(popup, "currentPassBox").text = "oldpass";
		input(popup, "newPassBox1").text = "newpass";
		input(popup, "newPassBox2").text = "newpass";
		input(popup, "newPassBox2").dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, 13));

		assertEquals(1, uploads.length, "enter key submits password change");
		assertEquals(ServerConfig.changePasswordUrl(), uploads[0].url, "change-password endpoint");
		assertEquals("Changing password...", uploads[0].label, "upload label");
		var payload:Dynamic = Json.parse(PR2Encryptor.decryptBase64(uploads[0].fields.get("i"), LOGIN_KEY, LOGIN_IV));
		assertEquals("Password Tester", Reflect.field(payload, "name"), "payload includes logged-in name");
		assertEquals("oldpass", Reflect.field(payload, "old_pass"), "payload includes current password");
		assertEquals("newpass", Reflect.field(payload, "new_pass"), "payload includes new password");
		assertEquals(true, popup.fadeOutStarted, "successful submit fades the dialog");
		closeAll();
	}

	private static function testCancel():Void {
		var popup = new ChangePasswordPopup();
		click(popup, "cancel_bt");
		assertEquals(true, popup.fadeOutStarted, "cancel fades the dialog");
		closeAll();
	}

	private static function input(popup:ChangePasswordPopup, name:String):FlTextInput {
		var value = Std.downcast(DisplayUtil.findByName(popup, name), FlTextInput);
		if (value == null) throw name + " missing";
		return value;
	}

	private static function click(popup:ChangePasswordPopup, name:String):Void {
		var target = DisplayUtil.findByName(popup, name);
		if (target == null) throw name + " missing";
		target.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	}

	private static function assertPasswordInput(popup:ChangePasswordPopup, name:String):Void {
		assertEquals(true, input(popup, name).displayAsPassword, name + " is password-masked");
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
