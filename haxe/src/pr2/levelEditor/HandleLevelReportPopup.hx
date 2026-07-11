package pr2.levelEditor;

import openfl.events.Event;
import openfl.events.MouseEvent;
import pr2.lobby.chat.ChatText;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.lobby.dialogs.HoverPopup;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.net.ServerConfig;
import pr2.runtime.FlComboBox;
import pr2.runtime.FlComponents;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;
import pr2.levelEditor.EditorPersistenceTypes.HandleLevelReportUploadFactory;
import pr2.levelEditor.EditorPersistenceTypes.HandleLevelReportReopenFactory;

class HandleLevelReportPopup extends Popup {
	private static final MONTHS:Array<String> = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sept", "Oct", "Nov", "Dec"];

	public static var uploadFactory:HandleLevelReportUploadFactory = defaultUpload;
	public static var reopenFactory:HandleLevelReportReopenFactory = defaultReopen;

	public final reportsPopup:GetReportedLevelsPopup;
	public final level:Dynamic;
	public var art(default, null):Null<PR2MovieClip>;
	private var htmlNameMaker:HtmlNameMaker = new HtmlNameMaker();
	private var bindings:Array<Null<Binding>> = [];
	private var uploading:Null<UploadingPopup>;
	private var banRet:Dynamic = null;
	private var info:Null<HoverPopup>;

	public function new(reportsPopup:GetReportedLevelsPopup, level:Dynamic) {
		super();
		this.reportsPopup = reportsPopup;
		this.level = level;
		art = PR2MovieClip.fromLinkage("HandleLevelReportPopupGraphic", {maxNestedDepth: 6});
		addChild(art);
		var titleBox = LobbyArt.text(art, "titleBox");
		if (titleBox != null) {
			htmlNameMaker.listenForLink(titleBox);
			titleBox.htmlText = htmlNameMaker.makeLevel(field("title"), levelId()) + " by "
				+ htmlNameMaker.makeName(field("creator"), fieldOr("creator_group", "0"));
		}
		setOtherReasonMode(false);
		var reason = reasonCombo();
		if (reason != null) {
			reason.addEventListener(Event.CHANGE, checkIfSelectedOther);
		}
		bind("other_cancel_bt", function():Void setOtherReasonMode(false));
		bind("ban_bt", clickBan);
		bind("cancel_bt", function():Void startFadeOut());
		bind("archive_bt", clickArchive);
		bindMouse("info_bt", MouseEvent.MOUSE_OVER, addInfoHover);
		bindMouse("info_bt", MouseEvent.MOUSE_OUT, removeInfoHover);
	}

	private function addInfoHover(_:MouseEvent):Void {
		var title = "-- " + ChatText.escapeString(field("title")) + " --";
		var popText = "Creator: " + ChatText.escapeString(field("creator")) + "<br/>";
		popText += "Version: " + version();
		var note = StringTools.trim(field("note"));
		if (note != "") {
			popText += "<br/>Note: <i>" + ChatText.escapeString(note) + "</i>";
		}
		popText += "<br/>-----<br/>";
		popText += "Reported: " + shortDate(parseFloat(field("report_time"), 0)) + "<br/>";
		popText += "^ By: " + ChatText.escapeString(field("reporter")) + "<br/>";
		popText += "Reason: <i>" + ChatText.escapeString(field("reason")) + "</i>";
		var target = DisplayUtil.findByName(art, "info_bt");
		if (target != null) {
			info = new HoverPopup(title, popText, target);
			info.x += info.width + 23;
		}
	}

	private function removeInfoHover(?_:MouseEvent):Void {
		if (info != null) {
			info.remove();
			info = null;
		}
	}

	private function checkIfSelectedOther(_:Event):Void {
		var reason = reasonCombo();
		if (reason == null || reason.selectedIndex < reason.length - 1) {
			return;
		}
		setOtherReasonMode(true);
	}

	private function setOtherReasonMode(selectedOther:Bool):Void {
		var reason = reasonCombo();
		if (reason != null) {
			reason.selectedIndex = 0;
			reason.visible = !selectedOther;
		}
		var otherReason = DisplayUtil.findByName(art, "otherReasonBox");
		if (otherReason != null) {
			otherReason.visible = selectedOther;
		}
		var otherCancel = DisplayUtil.findByName(art, "other_cancel_bt");
		if (otherCancel != null) {
			otherCancel.visible = selectedOther;
		}
	}

	private function clickBan():Void {
		var reason = reportReason();
		if (reason == "") {
			new MessagePopup("Error: You must enter a reason for the ban.");
			return;
		}
		var duration = selectedDataInt(durationCombo(), 0);
		if (duration == 0) {
			new MessagePopup("Error: You must specify a ban length.");
			return;
		}
		new ConfirmPopup(banUser,
			"Are you sure you want to socially ban " + ChatText.escapeString(field("creator")) + "? This will also unpublish the reported level.");
	}

	private function banUser():Void {
		banRet = null;
		uploading = uploadFactory(ServerConfig.banUserUrl(), banFields(), "Unpublishing and banning...", function(ret:Dynamic):Void {
			banRet = ret;
			archiveReport();
		}, handleUploadError);
	}

	private function clickArchive():Void {
		new ConfirmPopup(archiveReport, "Are you sure you want to archive this report?");
	}

	private function archiveReport():Void {
		uploading = uploadFactory(ServerConfig.archiveReportUrl(), archiveFields(), "Archiving report...", archiveDone, handleUploadError);
	}

	private function archiveDone(_:Dynamic):Void {
		reportsPopup.startFadeOut();
		reopenFactory();
		if (banRet != null && Reflect.hasField(banRet, "message")) {
			new MessagePopup(Std.string(Reflect.field(banRet, "message")));
		}
		startFadeOut();
	}

	private function handleUploadError(message:String):Void {
		if (message != null && message != "") {
			new MessagePopup("Error: " + message);
		}
	}

	private function banFields():Map<String, String> {
		return [
			"level_id" => Std.string(levelId()),
			"banned_name" => field("creator"),
			"duration" => Std.string(selectedDataInt(durationCombo(), 0)),
			"reason" => "Inappropriate Level -- " + reportReason(),
			"scope" => "social",
			"record" => "Level ID: " + levelId() + "\nTitle: " + ChatText.escapeString(field("title")) + "\nNote: "
				+ ChatText.escapeString(field("note")) + "\nVersion: " + version()
		];
	}

	private function archiveFields():Map<String, String> {
		return [
			"level_id" => Std.string(levelId()),
			"version" => Std.string(version())
		];
	}

	private function reportReason():String {
		var reason = reasonCombo();
		if (reason == null || reason.selectedIndex == 0 || reason.selectedIndex == reason.length - 1) {
			return otherReasonText();
		}
		return selectedData(reason, "");
	}

	private function otherReasonText():String {
		var field = FlComponents.asTextField(DisplayUtil.findByName(art, "otherReasonBox"));
		return field == null ? "" : field.text;
	}

	private function reasonCombo():Null<FlComboBox> {
		return Std.downcast(DisplayUtil.findByName(art, "reason"), FlComboBox);
	}

	private function durationCombo():Null<FlComboBox> {
		return Std.downcast(DisplayUtil.findByName(art, "duration"), FlComboBox);
	}

	private static function selectedData(combo:Null<FlComboBox>, fallback:String):String {
		if (combo == null || combo.selectedItem == null) {
			return fallback;
		}
		var data:Dynamic = Reflect.field(combo.selectedItem, "data");
		return data == null ? fallback : Std.string(data);
	}

	private static function selectedDataInt(combo:Null<FlComboBox>, fallback:Int):Int {
		var parsed = Std.parseInt(selectedData(combo, Std.string(fallback)));
		return parsed == null ? fallback : parsed;
	}

	private function bind(name:String, handler:Void->Void):Void {
		bindings.push(LobbyArt.bind(DisplayUtil.findByName(art, name), handler));
	}

	private function bindMouse(name:String, type:String, handler:MouseEvent->Void):Void {
		var target = DisplayUtil.findByName(art, name);
		if (target != null) {
			target.addEventListener(type, handler);
		}
	}

	private function unbindMouse(name:String, type:String, handler:MouseEvent->Void):Void {
		var target = DisplayUtil.findByName(art, name);
		if (target != null) {
			target.removeEventListener(type, handler);
		}
	}

	private function field(name:String):String {
		return fieldOr(name, "");
	}

	private function fieldOr(name:String, fallback:String):String {
		var value = level == null ? null : Reflect.field(level, name);
		return value == null ? fallback : Std.string(value);
	}

	private function levelId():Int {
		return parseInt(field("level_id"), 0);
	}

	private function version():Int {
		return parseInt(field("version"), 0);
	}

	private static function parseInt(value:String, fallback:Int):Int {
		var parsed = Std.parseInt(value);
		return parsed == null ? fallback : parsed;
	}

	private static function parseFloat(value:String, fallback:Float):Float {
		var parsed = Std.parseFloat(value);
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	private static function shortDate(time:Float):String {
		var d = Date.fromTime(time * 1000);
		return d.getDate() + "/" + MONTHS[d.getMonth()] + "/" + d.getFullYear();
	}

	override public function remove():Void {
		removeInfoHover();
		var reason = reasonCombo();
		if (reason != null) {
			reason.removeEventListener(Event.CHANGE, checkIfSelectedOther);
		}
		unbindMouse("info_bt", MouseEvent.MOUSE_OVER, addInfoHover);
		unbindMouse("info_bt", MouseEvent.MOUSE_OUT, removeInfoHover);
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		if (uploading != null) {
			uploading.startFadeOut();
			uploading = null;
		}
		htmlNameMaker.remove();
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

	public static function defaultReopen():Void {
		new GetReportedLevelsPopup();
	}
}
