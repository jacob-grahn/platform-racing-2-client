package pr2.lobby.dialogs;

import pr2.net.ServerConfig;

typedef LevelModerateUploadFactory = String->Map<String, String>->String->(Dynamic->Void)->(String->Void)->Null<UploadingPopup>;

/**
	Port of Flash `dialogs.ChooseLevelModModePopup`: moderators choose whether to
	unpublish or restrict a level, confirm, then POST `level_id` and `action`.
**/
class ChooseLevelModModePopup extends Popup {
	public static var uploadFactory:LevelModerateUploadFactory = defaultUpload;

	public final levelId:Int;

	private var art:Null<ChooseLevelModModeView>;
	private var uploading:Null<UploadingPopup>;

	public function new(levelId:Int = 0) {
		super();
		this.levelId = levelId;
		art = new ChooseLevelModModeView();
		addChild(art);
		art.onUnpublish = clickUnpublish;
		art.onRestrict = clickRestrict;
		art.onCancel = startFadeOut;
	}

	private function clickUnpublish():Void {
		new ConfirmPopup(function():Void confirmAction("unpublish"),
			"Are you sure you want to unpublish this level? The author will need to re-publish it from their account.");
	}

	private function clickRestrict():Void {
		new ConfirmPopup(function():Void confirmAction("restrict"),
			"Are you sure you want to restrict this level? The level will remain playable but will not appear in any level lists except Search and Favorites.");
	}

	private function confirmAction(action:String):Void {
		uploading = uploadFactory(ServerConfig.levelModerateUrl(), [
			"level_id" => Std.string(levelId),
			"action" => action
		], action == "restrict" ? "Restricting level..." : "Unpublishing level...", returnAction, handleUploadError);
	}

	private function returnAction(parsedData:Dynamic):Void {
		if (parsedData != null && Reflect.field(parsedData, "success") == true) {
			if (LevelInfoPopup.instance != null) {
				LevelInfoPopup.instance.startFadeOut();
			}
			startFadeOut();
			return;
		}
		if (parsedData != null) {
			var error = Reflect.field(parsedData, "error");
			var message = error == null ? "The level moderation request failed." : Std.string(error);
			handleUploadError(message);
		}
	}

	private function handleUploadError(message:String):Void {
		if (message != null && message != "") {
			new MessagePopup("Error: " + message);
		}
	}

	override public function remove():Void {
		if (uploading != null) {
			uploading.startFadeOut();
			uploading = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	public static function defaultUpload(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
			onError:String->Void):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label, onResult, onError);
	}
}
