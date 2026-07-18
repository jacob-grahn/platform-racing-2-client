package pr2.levelEditor;

import com.jiggmin.data.Data;
import openfl.events.MouseEvent;
import pr2.lobby.dialogs.HoverPopup;
import pr2.lobby.LobbyArt;
import pr2.ui.SelectableButton;

class GetReportedLevelsPopupItem extends SelectableButton {
	public final level:Dynamic;
	public final levelId:Int;
	public final version:Int;
	public final title:String;
	public var art(default, null):LevelListItemView;
	private var popup:Null<GetReportedLevelsPopup>;
	private var info:Null<HoverPopup>;

	public function new(level:Dynamic, popup:GetReportedLevelsPopup) {
		super(new LevelListItemView(true));
		this.level = level;
		this.popup = popup;
		art = cast selectableTarget;
		addChild(art);
		levelId = parseInt(field("level_id"), 0);
		version = parseInt(field("version"), 0);
		title = field("title");
		setText("titleBox", title);
		setText("timeBox", Data.getShortDateStr(parseFloat(field("report_time"), 0)));
		mouseChildren = false;
		buttonMode = true;
		doubleClickEnabled = true;
		addEventListener(MouseEvent.CLICK, onClick);
		addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
		addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}

	private function onClick(_:MouseEvent):Void {
		if (popup != null) {
			popup.selectListing(this);
		}
	}

	private function onDoubleClick(_:MouseEvent):Void {
		if (popup != null) {
			popup.selectListing(this);
			popup.loadSelected();
		}
	}

	private function onMouseOver(_:MouseEvent):Void {
		info = new HoverPopup(hoverTitle(level), hoverBody(level, fieldText("timeBox")), art);
		info.width -= 3;
		info.x = 550 - info.width;
	}

	private function onMouseOut(_:MouseEvent = null):Void {
		if (info != null) {
			info.remove();
			info = null;
		}
	}

	override public function remove():Void {
		onMouseOut();
		removeEventListener(MouseEvent.CLICK, onClick);
		removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
		removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		popup = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private function setText(name:String, value:String):Void {
		var text = LobbyArt.directText(art, name);
		if (text != null) {
			text.text = value;
		}
	}

	private function fieldText(name:String):String {
		var text = LobbyArt.directText(art, name);
		return text == null ? "" : text.text;
	}

	private function field(name:String):String {
		return levelField(level, name);
	}

	public static function hoverTitleForTests(level:Dynamic):String {
		return hoverTitle(level);
	}

	public static function hoverBodyForTests(level:Dynamic):String {
		return hoverBody(level, Data.getShortDateStr(parseFloat(levelField(level, "report_time"), 0)));
	}

	public function showHoverForTests():Void {
		onMouseOver(null);
	}

	public function hideHoverForTests():Void {
		onMouseOut();
	}

	public function hasHoverForTests():Bool {
		return info != null;
	}

	public function hoverXForTests():Float {
		return info == null ? Math.NaN : info.x;
	}

	public function hoverWidthForTests():Float {
		return info == null ? Math.NaN : info.width;
	}

	private static function hoverTitle(level:Dynamic):String {
		return "-- " + Data.escapeString(levelField(level, "title")) + " --";
	}

	private static function hoverBody(level:Dynamic, reportedDate:String):String {
		var popText = "Creator: " + Data.escapeString(levelField(level, "creator")) + "<br/>";
		popText += "Version: " + Data.formatNumber(parseFloat(levelField(level, "version"), 0));
		var note = StringTools.trim(levelField(level, "note"));
		if (note != "") {
			popText += "<br/>Note: <i>" + Data.escapeString(note, true) + "</i>";
		}
		popText += "<br/>-----<br/>";
		popText += "Reported: " + reportedDate + "<br/>";
		popText += "^ By: " + Data.escapeString(levelField(level, "reporter")) + "<br/>";
		popText += "Reason: <i>" + Data.escapeString(levelField(level, "reason")) + "</i>";
		return popText;
	}

	private static function levelField(level:Dynamic, name:String):String {
		var value = level == null ? null : Reflect.field(level, name);
		return value == null ? "" : Std.string(value);
	}

	private static function parseInt(value:String, fallback:Int):Int {
		var parsed = Std.parseInt(value);
		return parsed == null ? fallback : parsed;
	}

	private static function parseFloat(value:String, fallback:Float):Float {
		var parsed = Std.parseFloat(value);
		return Math.isNaN(parsed) ? fallback : parsed;
	}

}
