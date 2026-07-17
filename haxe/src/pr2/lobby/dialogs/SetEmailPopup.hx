package pr2.lobby.dialogs;

import haxe.Json;
import pr2.crypto.PR2Encryptor;
import pr2.net.ServerConfig;

typedef SetEmailUploadFactory = String->Map<String, String>->String->Null<UploadingPopup>;

class SetEmailPopup extends FormPopup {
	private static inline var ACCOUNT_CHANGE_KEY:String = "KVhFJSVLNigvKkdhV0RaSw==";
	private static inline var ACCOUNT_CHANGE_IV:String = "QEFUZCskMnhhdk8rYlFLKg==";

	public static var uploadFactory:SetEmailUploadFactory = defaultUpload;

	public function new() {
		super();
		initializeForm("SetEmailPopupGraphic", ["email1Box", "email2Box", "passBox"], clickOk);
	}

	private function clickOk():Void {
		var email1 = inputText("email1Box");
		var email2 = inputText("email2Box");
		var pass = inputText("passBox");
		if (email1 == "" || pass == "") {
			new MessagePopup("Please fill in all of the fields.");
		} else if (email1 != email2) {
			new MessagePopup("The emails don't match. Please re-check them.");
		} else {
			uploadFactory(ServerConfig.accountChangeEmailUrl(), ["data" => encryptedPayload(email1, pass)], "Uploading...");
			startFadeOut();
		}
	}

	private function encryptedPayload(email:String, pass:String):String {
		return PR2Encryptor.encryptBase64(Json.stringify({email: email, pass: pass}), ACCOUNT_CHANGE_KEY, ACCOUNT_CHANGE_IV);
	}

	public static function defaultUpload(url:String, fields:Map<String, String>, label:String):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label);
	}
}
