package pr2.lobby.dialogs;

import pr2.lobby.LobbyArt;
import pr2.net.ServerConfig;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

typedef LevelModerateUploadFactory = String->Map<String, String>->String->(Dynamic->Void)->(String->Void)->Null<UploadingPopup>;

/**
	Port of Flash `dialogs.ChooseLevelModModePopup`: moderators choose whether to
	unpublish or restrict a level, confirm, then POST `level_id` and `action`.
**/
class ChooseLevelModModePopup extends Popup {
	public static var uploadFactory:LevelModerateUploadFactory = defaultUpload;

	public final levelId:Int;

	private var art:Null<PR2MovieClip>;
	private var uploading:Null<UploadingPopup>;
	private var unpublishBinding:Null<LobbyArt.Binding>;
	private var restrictBinding:Null<LobbyArt.Binding>;
	private var cancelBinding:Null<LobbyArt.Binding>;

	public function new(levelId:Int = 0) {
		super();
		this.levelId = levelId;
		art = PR2MovieClip.fromLinkage("ChooseLevelModModePopupGraphic", {maxNestedDepth: 4});
		addChild(art);
		unpublishBinding = LobbyArt.bind(DisplayUtil.findByName(art, "unpublish_bt"), clickUnpublish);
		restrictBinding = LobbyArt.bind(DisplayUtil.findByName(art, "restrict_bt"), clickRestrict);
		cancelBinding = LobbyArt.bind(DisplayUtil.findByName(art, "cancel_bt"), function():Void startFadeOut());
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
		}
	}

	private function handleUploadError(message:String):Void {
		if (message != null && message != "") {
			new MessagePopup("Error: " + message);
		}
	}

	override public function remove():Void {
		LobbyArt.unbind(unpublishBinding);
		LobbyArt.unbind(restrictBinding);
		LobbyArt.unbind(cancelBinding);
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
