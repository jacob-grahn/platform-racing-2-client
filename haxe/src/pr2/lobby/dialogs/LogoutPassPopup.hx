package pr2.lobby.dialogs;

import haxe.Json;
import openfl.events.KeyboardEvent;
import pr2.crypto.PR2Encryptor;
import pr2.lobby.LobbySession;
import pr2.net.ServerConfig;
import pr2.ui.controls.GameTextInput;

typedef LogoutUploadFactory = String->Map<String, String>->String->(Dynamic->Void)->Null<UploadingPopup>;

/** Obsolete Flash logout-confirmation dialog, preserved for parity. */
class LogoutPassPopup extends Popup {
	private static inline var LOGIN_KEY:String = "VUovam5GKndSMHFSSy9kSA==";
	private static inline var LOGIN_IV:String = "JmM5KnkqNXA9MVVOeC9Ucg==";

	public static var uploadFactory:LogoutUploadFactory = defaultUpload;

	private var art:Null<NativeFormView>;
	private var passBox:Null<GameTextInput>;
	private var uploading:Null<UploadingPopup>;

	public function new(?hideGraphic:Void->Void) {
		super();
		art = new NativeFormView("LogoutPassPopupGraphic");
		addChild(art);
		passBox = art.inputs.get("passBox");
		art.onSubmit = clickLogOut;
		art.onCancel = startFadeOut;
		if (passBox != null) {
			passBox.addEventListener(KeyboardEvent.KEY_DOWN, listenForEnter);
		}
	}

	private function listenForEnter(event:KeyboardEvent):Void {
		if (event.keyCode == 13) {
			clickLogOut();
		}
	}

	private function clickLogOut():Void {
		var password = passBox == null ? "" : passBox.text;
		if (password == "") {
			new MessagePopup("Error: You must enter a password in order to log out.");
			return;
		}
		uploading = uploadFactory(ServerConfig.logoutUrl(), ["i" => encryptedPayload(password)], "Logging out...", receiveResult);
		startFadeOut();
	}

	private function receiveResult(ret:Dynamic):Void {
		if (ret == null || Std.string(Reflect.field(ret, "errorType")) != "pass") {
			LobbySession.clear();
			startFadeOut();
		}
	}

	private function encryptedPayload(password:String):String {
		var payload = Json.stringify({
			user_name: LobbySession.userName,
			user_pass: password,
		});
		return PR2Encryptor.encryptBase64(payload, LOGIN_KEY, LOGIN_IV);
	}

	override public function remove():Void {
		if (passBox != null) {
			passBox.removeEventListener(KeyboardEvent.KEY_DOWN, listenForEnter);
			passBox = null;
		}
		uploading = null;
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
