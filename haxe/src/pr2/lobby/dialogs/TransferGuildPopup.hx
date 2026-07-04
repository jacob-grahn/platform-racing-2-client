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

typedef TransferGuildUploadFactory = String->Map<String, String>->String->(Dynamic->Void)->Null<UploadingPopup>;

class TransferGuildPopup extends Popup {
	private static inline var ACCOUNT_CHANGE_KEY:String = "KVhFJSVLNigvKkdhV0RaSw==";
	private static inline var ACCOUNT_CHANGE_IV:String = "QEFUZCskMnhhdk8rYlFLKg==";

	public static var uploadFactory:TransferGuildUploadFactory = defaultUpload;

	private var art:Null<PR2MovieClip>;
	private var okBinding:Null<Binding>;
	private var cancelBinding:Null<Binding>;
	private var inputs:Array<FlTextInput> = [];

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("TransferGuildPopupGraphic", {maxNestedDepth: 4});
		addChild(art);
		okBinding = LobbyArt.bind(DisplayUtil.findByName(art, "ok_bt"), clickOk);
		cancelBinding = LobbyArt.bind(DisplayUtil.findByName(art, "cancel_bt"), startFadeOut);
		for (name in ["emailBox", "passBox", "nameBox"]) {
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

	public static function defaultUpload(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label, onResult);
	}
}
