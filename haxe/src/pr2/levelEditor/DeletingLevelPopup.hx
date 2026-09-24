package pr2.levelEditor;

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
		return EditorLevelService.deleteFields(levelId);
	}

	public static function defaultPost(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
			onError:String->Void):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label, onResult, onError);
	}
}
