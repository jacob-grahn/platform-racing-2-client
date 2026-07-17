package pr2.lobby.dialogs;

import pr2.net.ServerConfig;

typedef LevelReportUploadFactory = String->Map<String, String>->String->Null<UploadingPopup>;

/**
	Port of Flash `dialogs.LevelReportPopup`: collect a report reason, require a
	non-empty message, confirm, then POST `level_id`, `version`, and `reason`.
**/
class LevelReportPopup extends Popup {
	public static var uploadFactory:LevelReportUploadFactory = defaultUpload;

	public final levelId:Int;
	public final version:Int;

	private var art:Null<LevelReportView>;

	public function new(levelId:Int = 0, version:Int = 0) {
		super();
		this.levelId = levelId;
		this.version = version;

		art = new LevelReportView();
		addChild(art);
		art.onReport = clickReport;
		art.onCancel = startFadeOut;
	}

	private function clickReport():Void {
		var reason = reportReason();
		if (reason == "") {
			new MessagePopup("Error: Oops, you forgot to write the reason for your report!");
			return;
		}
		new ConfirmPopup(confirmReport,
			"Are you sure you want to report this level to the moderators? If it contains something inappropriate or mean, then please do report this level.");
	}

	private function confirmReport():Void {
		if (LevelInfoPopup.instance != null) {
			LevelInfoPopup.instance.startFadeOut();
		}
		uploadFactory(ServerConfig.levelReportUrl(), [
			"level_id" => Std.string(levelId),
			"version" => Std.string(version),
			"reason" => reasonText()
		], "Reporting level...");
		startFadeOut();
	}

	private function reportReason():String {
		return StringTools.trim(reasonText());
	}

	private function reasonText():String {
		return art == null ? "" : art.reasonInput.text;
	}

	override public function remove():Void {
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
