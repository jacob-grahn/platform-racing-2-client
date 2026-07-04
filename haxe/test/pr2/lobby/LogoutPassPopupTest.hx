package pr2.lobby;

import haxe.Json;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import pr2.crypto.PR2Encryptor;
import pr2.lobby.dialogs.LogoutPassPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.net.ServerConfig;
import pr2.runtime.FlTextInput;
import pr2.util.DisplayUtil;

class LogoutPassPopupTest {
	private static inline var LOGIN_KEY:String = "VUovam5GKndSMHFSSy9kSA==";
	private static inline var LOGIN_IV:String = "JmM5KnkqNXA9MVVOeC9Ucg==";

	private static var assertions:Int = 0;

	public static function main():Void {
		var savedUploadFactory = LogoutPassPopup.uploadFactory;
		ServerConfig.setHost("http://example.test");
		testValidationAndCancel();
		testEncryptedUploadFromEnterKey();
		testPasswordErrorDoesNotClearSession();
		LogoutPassPopup.uploadFactory = savedUploadFactory;
		ServerConfig.resetHost();
		closeAll();
		trace('LogoutPassPopupTest passed $assertions assertions');
	}

	private static function testValidationAndCancel():Void {
		var uploads = 0;
		LogoutPassPopup.uploadFactory = function(url:String, fields:Map<String, String>, label:String,
				onResult:Dynamic->Void):Null<pr2.lobby.dialogs.UploadingPopup> {
			uploads++;
			return null;
		};
		var popup = new LogoutPassPopup();
		assertEquals(true, input(popup).displayAsPassword, "password field is masked");
		click(popup, "logout_bt");
		assertEquals(0, uploads, "blank password does not upload");
		assertEquals("Error: You must enter a password in order to log out.", lastMessageText(), "blank-password error copy");
		closeAll();

		popup = new LogoutPassPopup();
		click(popup, "cancel_bt");
		assertEquals(true, popup.fadeOutStarted, "cancel fades the dialog");
		closeAll();
	}

	private static function testEncryptedUploadFromEnterKey():Void {
		var uploads:Array<{url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void}> = [];
		LogoutPassPopup.uploadFactory = function(url:String, fields:Map<String, String>, label:String,
				onResult:Dynamic->Void):Null<pr2.lobby.dialogs.UploadingPopup> {
			uploads.push({url: url, fields: fields, label: label, onResult: onResult});
			return null;
		};
		LobbySession.begin("Logout Tester", 1, null, 123, true);
		LobbySession.updateAccountState(true, "tok", false);
		var popup = new LogoutPassPopup();
		input(popup).text = "secret";
		input(popup).dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, 13));

		assertEquals(1, uploads.length, "enter key submits logout password");
		assertEquals(ServerConfig.logoutUrl(), uploads[0].url, "logout endpoint");
		assertEquals("Logging out...", uploads[0].label, "upload label");
		var payload:Dynamic = Json.parse(PR2Encryptor.decryptBase64(uploads[0].fields.get("i"), LOGIN_KEY, LOGIN_IV));
		assertEquals("Logout Tester", Reflect.field(payload, "user_name"), "payload includes logged-in name");
		assertEquals("secret", Reflect.field(payload, "user_pass"), "payload includes password");
		assertEquals(true, popup.fadeOutStarted, "submit fades the dialog");

		uploads[0].onResult({success: true});
		assertEquals("Guest", LobbySession.userName, "non-password server result clears session");
		closeAll();
	}

	private static function testPasswordErrorDoesNotClearSession():Void {
		var onResult:Dynamic->Void = null;
		LogoutPassPopup.uploadFactory = function(url:String, fields:Map<String, String>, label:String,
				result:Dynamic->Void):Null<pr2.lobby.dialogs.UploadingPopup> {
			onResult = result;
			return null;
		};
		LobbySession.begin("Still Logged In", 1, null, 456, true);
		var popup = new LogoutPassPopup();
		input(popup).text = "wrong";
		click(popup, "logout_bt");
		onResult({success: false, errorType: "pass"});
		assertEquals("Still Logged In", LobbySession.userName, "password server error preserves session");
		popup.remove();
	}

	private static function input(popup:LogoutPassPopup):FlTextInput {
		var value = Std.downcast(DisplayUtil.findByName(popup, "passBox"), FlTextInput);
		if (value == null) throw "passBox missing";
		return value;
	}

	private static function click(popup:LogoutPassPopup, name:String):Void {
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
		LobbySession.clear();
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
