package pr2.levelEditor;

import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.net.ServerConfig;
import pr2.levelEditor.EditorPersistenceTypes.DeleteLevelPostFactory;

class DeletingLevelPopup {
	public static var postFactory:DeleteLevelPostFactory = defaultPost;

	public final levelId:Int;

	public function new(levelId:Int) {
		this.levelId = levelId;
		postFactory(ServerConfig.deleteLevelUrl(), requestFields(levelId), "Deleting level...", handleResponse, handleError);
	}

	private function handleResponse(_:Dynamic):Void {
		new GetLevelsPopup();
	}

	private function handleError(message:String):Void {
		if (message != null && message != "") {
			new MessagePopup("Error: " + message);
		}
	}

	private static function requestFields(levelId:Int):Map<String, String> {
		var fields = new Map<String, String>();
		fields.set("level_id", Std.string(levelId));
		fields.set("rand", Std.string(Std.random(10000000)));
		fields.set("token", LobbySession.token);
		return fields;
	}

	public static function defaultPost(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
			onError:String->Void):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label, onResult, onError);
	}
}
