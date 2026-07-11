package pr2.lobby.dialogs;

import haxe.Json;
import pr2.crypto.PR2Encryptor;
import pr2.lobby.LobbySession;
import pr2.net.ServerConfig;

typedef ChangePasswordUploadFactory = String->Map<String, String>->String->Null<UploadingPopup>;

class ChangePasswordPopup extends FormPopup {
	private static inline var LOGIN_KEY:String = "VUovam5GKndSMHFSSy9kSA==";
	private static inline var LOGIN_IV:String = "JmM5KnkqNXA9MVVOeC9Ucg==";

	public static var uploadFactory:ChangePasswordUploadFactory = defaultUpload;

	public function new() {
		super();
		initializeForm("ChangePasswordPopupGraphic", ["currentPassBox", "newPassBox1", "newPassBox2"], clickOk);
	}

	private function clickOk():Void {
		var currentPass = inputText("currentPassBox");
		var newPass1 = inputText("newPassBox1");
		var newPass2 = inputText("newPassBox2");
		if (newPass1 != newPass2) {
			new MessagePopup("Error: The passwords don't match.");
		} else if (newPass1 == currentPass) {
			new MessagePopup("Error: Your current and new passwords match. Try picking a new password.");
		} else {
			uploadFactory(ServerConfig.changePasswordUrl(), ["i" => encryptedPayload(currentPass, newPass1)], "Changing password...");
			startFadeOut();
		}
	}

	private function encryptedPayload(currentPass:String, newPass:String):String {
		var payload = Json.stringify({
			name: LobbySession.userName,
			old_pass: currentPass,
			new_pass: newPass,
		});
		return PR2Encryptor.encryptBase64(payload, LOGIN_KEY, LOGIN_IV);
	}

	public static function defaultUpload(url:String, fields:Map<String, String>, label:String):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label);
	}
}
