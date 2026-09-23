package pr2.lobby.dialogs;

import pr2.lobby.account.AccountCredentialActions;
import pr2.net.ServerConfig;

typedef ChangePasswordUploadFactory = String->Map<String, String>->String->Null<UploadingPopup>;

class ChangePasswordPopup extends FormPopup {

	public static var uploadFactory:ChangePasswordUploadFactory = defaultUpload;

	public function new() {
		super();
		initializeForm("ChangePasswordPopupGraphic", ["currentPassBox", "newPassBox1", "newPassBox2"], clickOk);
	}

	private function clickOk():Void {
		var currentPass = inputText("currentPassBox");
		var newPass1 = inputText("newPassBox1");
		var newPass2 = inputText("newPassBox2");
		var error = AccountCredentialActions.validatePassword(currentPass,newPass1,newPass2);
		if (error != "") {
			new MessagePopup(error);
		} else {
			uploadFactory(ServerConfig.changePasswordUrl(), ["i" => AccountCredentialActions.passwordPayload(currentPass, newPass1)], "Changing password...");
			startFadeOut();
		}
	}

	public static function defaultUpload(url:String, fields:Map<String, String>, label:String):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label);
	}
}
