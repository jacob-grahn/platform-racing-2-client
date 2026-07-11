package pr2.levelEditor;

import com.jiggmin.data.Data;
import openfl.events.MouseEvent;
import pr2.gameplay.Modes;
import pr2.lobby.dialogs.HoverPopup;
import pr2.lobby.LobbyArt;
import pr2.runtime.PR2MovieClip;
import pr2.ui.SelectableButton;

class GetLevelsPopupItem extends SelectableButton {
	public final level:Dynamic;
	public final levelId:Int;
	public final version:Int;
	public final title:String;
	public var art(default, null):PR2MovieClip;
	private var popup:Null<GetLevelsPopup>;
	private var info:Null<HoverPopup>;

	public function new(level:Dynamic, popup:GetLevelsPopup) {
		super(PR2MovieClip.fromLinkage("GetLevelsPopupItemGraphic", {maxNestedDepth: 4}));
		this.level = level;
		this.popup = popup;
		art = cast selectableTarget;
		addChild(art);
		levelId = parseInt(field("level_id"), 0);
		version = parseInt(field("version"), 0);
		title = field("title");
		name = "getLevelsPopupItem";
		setText("titleBox", title);
		setText("statusBox", parseInt(field("live"), 0) == 1 ? "Published" : "Unpublished");
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
		info = new HoverPopup(hoverTitle(level), hoverBody(level), art);
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
		var text = LobbyArt.text(art, name);
		if (text != null) {
			text.text = value;
		}
	}

	private function field(name:String):String {
		return levelField(level, name);
	}

	public static function hoverTitleForTests(level:Dynamic):String {
		return hoverTitle(level);
	}

	public static function hoverBodyForTests(level:Dynamic):String {
		return hoverBody(level);
	}

	public function showHoverForTests():Void {
		onMouseOver(null);
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

	private static function hoverBody(level:Dynamic):String {
		var popText = "Game Mode: " + Modes.getFullName(levelField(level, "type")) + "<br/>";
		popText += "Version: " + Data.formatNumber(parseFloat(levelField(level, "version"), 0)) + "<br/>";
		popText += "Updated: " + Data.getShortDateStr(parseFloat(levelField(level, "time"), 0)) + "<br/>";
		popText += "Plays: " + Data.formatNumber(parseFloat(levelField(level, "play_count"), 0)) + "<br/>";
		popText += "Rating: " + levelField(level, "rating");
		var note = StringTools.trim(levelField(level, "note"));
		if (note != "") {
			popText += "<br/>-----<br/><i>" + Data.escapeString(note, true) + "</i>";
		}
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
