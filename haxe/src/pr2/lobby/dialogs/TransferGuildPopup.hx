package pr2.lobby.dialogs;

import pr2.lobby.LobbySession;
import pr2.lobby.players.GuildManagementActions;
import pr2.net.ServerConfig;

typedef TransferGuildUploadFactory = String->Map<String, String>->String->(Dynamic->Void)->Null<UploadingPopup>;

class TransferGuildPopup extends FormPopup {
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
			uploadFactory(ServerConfig.guildTransferUrl(), ["data" => GuildManagementActions.transferPayload(email, pass, newOwner, LobbySession.userName)], "Uploading...", receiveResult);
			startFadeOut();
		}
	}

	private function receiveResult(ret:Dynamic):Void {
		if (ret == null || Reflect.field(ret, "success") != false) {
			LobbySession.updateGuildState(LobbySession.guildId, LobbySession.guildName, false, LobbySession.emblem);
		}
	}

	public static function defaultUpload(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label, onResult);
	}
}
