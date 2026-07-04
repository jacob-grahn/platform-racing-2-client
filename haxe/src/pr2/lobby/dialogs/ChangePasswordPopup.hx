package pr2.lobby.dialogs;

import haxe.Json;
import openfl.events.KeyboardEvent;
import pr2.crypto.PR2Encryptor;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.LobbySession;
import pr2.net.ServerConfig;
import pr2.runtime.FlTextInput;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

typedef ChangePasswordUploadFactory = String->Map<String, String>->String->Null<UploadingPopup>;

class ChangePasswordPopup extends Popup {
	private static inline var LOGIN_KEY:String = "VUovam5GKndSMHFSSy9kSA==";
	private static inline var LOGIN_IV:String = "JmM5KnkqNXA9MVVOeC9Ucg==";

	public static var uploadFactory:ChangePasswordUploadFactory = defaultUpload;

	private var art:Null<PR2MovieClip>;
	private var okBinding:Null<Binding>;
	private var cancelBinding:Null<Binding>;
	private var inputs:Array<FlTextInput> = [];

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("ChangePasswordPopupGraphic", {maxNestedDepth: 4});
		addChild(art);

		okBinding = LobbyArt.bind(DisplayUtil.findByName(art, "ok_bt"), clickOk);
		cancelBinding = LobbyArt.bind(DisplayUtil.findByName(art, "cancel_bt"), startFadeOut);
		for (name in ["currentPassBox", "newPassBox1", "newPassBox2"]) {
			var input = textInput(name);
			if (input != null) {
				input.addEventListener(KeyboardEvent.KEY_DOWN, listenForEnterKey);
				inputs.push(input);
			}
		}
	}

	private function listenForEnterKey(event:KeyboardEvent):Void {
		if (event.keyCode == 13) {
			clickOk();
		}
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

	private function textInput(name:String):Null<FlTextInput> {
		return Std.downcast(DisplayUtil.findByName(art, name), FlTextInput);
	}

	private function inputText(name:String):String {
		var input = textInput(name);
		return input == null ? "" : input.text;
	}

	override public function remove():Void {
		LobbyArt.unbind(okBinding);
		LobbyArt.unbind(cancelBinding);
		for (input in inputs) {
			input.removeEventListener(KeyboardEvent.KEY_DOWN, listenForEnterKey);
		}
		inputs = [];
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	public static function defaultUpload(url:String, fields:Map<String, String>, label:String):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label);
	}
}
