package pr2.lobby.dialogs;

import haxe.Json;
import pr2.crypto.PR2Encryptor;
import pr2.lobby.LobbySession;
import pr2.net.ServerConfig;

typedef TransferGuildUploadFactory = String->Map<String, String>->String->(Dynamic->Void)->Null<UploadingPopup>;

class TransferGuildPopup extends FormPopup {
	private static inline var ACCOUNT_CHANGE_KEY:String = "KVhFJSVLNigvKkdhV0RaSw==";
	private static inline var ACCOUNT_CHANGE_IV:String = "QEFUZCskMnhhdk8rYlFLKg==";

	public static var uploadFactory:TransferGuildUploadFactory = defaultUpload;

	public function new() {
		super();
		initializeForm("TransferGuildPopupGraphic", ["emailBox", "passBox", "nameBox"], clickOk);
	}

	private function clickOk():Void {
		var email = inputText("emailBox");
		var pass = inputText("passBox");
		var newOwner = inputText("nameBox");
		if (email == "" || pass == "" || newOwner == "") {
			new MessagePopup("Please fill in all of the fields.");
		} else {
			uploadFactory(ServerConfig.guildTransferUrl(), ["data" => encryptedPayload(email, pass, newOwner)], "Uploading...", receiveResult);
			startFadeOut();
		}
	}

	private function receiveResult(ret:Dynamic):Void {
		if (ret == null || Reflect.field(ret, "success") != false) {
			LobbySession.updateGuildState(LobbySession.guildId, LobbySession.guildName, false, LobbySession.emblem);
		}
	}

	private function encryptedPayload(email:String, pass:String, newOwner:String):String {
		return PR2Encryptor.encryptBase64(Json.stringify({
			email: email,
			name: LobbySession.userName,
			pass: pass,
			new_owner: newOwner,
		}), ACCOUNT_CHANGE_KEY, ACCOUNT_CHANGE_IV);
	}

	public static function defaultUpload(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label, onResult);
	}
}
