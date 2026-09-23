package pr2.lobby.dialogs;

import pr2.lobby.account.AccountCredentialActions;
import pr2.net.ServerConfig;

typedef SetEmailUploadFactory = String->Map<String, String>->String->Null<UploadingPopup>;

class SetEmailPopup extends FormPopup {

	public static var uploadFactory:SetEmailUploadFactory = defaultUpload;

	public function new() {
		super();
		initializeForm("SetEmailPopupGraphic", ["email1Box", "email2Box", "passBox"], clickOk);
	}

	private function clickOk():Void {
		var email1 = inputText("email1Box");
		var email2 = inputText("email2Box");
		var pass = inputText("passBox");
		var error = AccountCredentialActions.validateEmail(email1,email2,pass);
		if (error != "") {
			new MessagePopup(error);
		} else {
			uploadFactory(ServerConfig.accountChangeEmailUrl(), ["data" => AccountCredentialActions.emailPayload(email1, pass)], "Uploading...");
			startFadeOut();
		}
	}

	public static function defaultUpload(url:String, fields:Map<String, String>, label:String):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label);
	}
}
