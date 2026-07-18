package pr2.ui.controls;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;

/** Native fl.controls.TextArea with authored skins and an authored UIScrollBar. */
class GameTextArea extends NativeControl {
	private static inline var SCROLL_WIDTH:Float = 15;
	private static final UP_GRID = new Rectangle(1.55, 1.55, 148.5, 18.4);
	private static final DISABLED_GRID = new Rectangle(38, 5.5, 76, 11);
	private static final FOCUS_GRID = new Rectangle(4, 2, 74, 18);

	public var text(get, set):String;
	public var htmlText(get, set):String;
	public var restrict(get, set):String;
	public var maxChars(get, set):Int;
	public var editable(default, set):Bool = true;
	public var wordWrap(default, set):Bool = true;
	public var verticalScrollPolicy(default, set):String = "auto";
	public var onChange:Null<String->Void>;
	public final textField:TextField;
	public final verticalScrollBar:GameScrollBar;

	private var authoredBackground:Sprite;
	private var focusBackground:Sprite;

	public function new(width:Float = 160, height:Float = 100) {
		super(width, height);
		buttonMode = false;
		useHandCursor = false;
		graphics.clear();

		authoredBackground = new Sprite();
		authoredBackground.mouseEnabled = false;
		authoredBackground.mouseChildren = false;
		addChild(authoredBackground);
		focusBackground = new Sprite();
		focusBackground.mouseEnabled = false;
		focusBackground.mouseChildren = false;
		focusBackground.visible = false;
		addChild(focusBackground);

		textField = new TextField();
		textField.type = TextFieldType.INPUT;
		textField.multiline = true;
		textField.wordWrap = true;
		textField.selectable = true;
		textField.mouseEnabled = true;
		textField.autoSize = TextFieldAutoSize.NONE;
		textField.defaultTextFormat = textFormatForState();
		textField.addEventListener(Event.CHANGE, onTextChange);
		textField.addEventListener(Event.SCROLL, onFieldScroll);
		addChild(textField);

		verticalScrollBar = new GameScrollBar(1, 1, 1, 1);
		verticalScrollBar.onScroll = function(value:Float):Void textField.scrollV = Math.round(value);
		addChild(verticalScrollBar);
		layoutChildren();
		redraw();
	}

	override public function setSize(width:Float, height:Float):Void {
		super.setSize(width, height);
		if (textField != null) layoutChildren();
	}

	override public function focus():Void {
		if (!enabled || disposed) return;
		focused = true;
		if (stage != null && stage.focus != textField) stage.focus = textField;
		redraw();
	}

	override public function blur():Void {
		focused = false;
		pressed = false;
		if (stage != null && stage.focus == textField) stage.focus = null;
		redraw();
	}

	override public function redraw():Void {
		if (authoredBackground == null || focusBackground == null) {
			super.redraw();
			return;
		}
		graphics.clear();
		while (authoredBackground.numChildren > 0) authoredBackground.removeChildAt(0);
		authoredBackground.addChild(NativeAssets.svg(authoredAsset()));
		authoredBackground.scale9Grid = enabled ? UP_GRID : DISABLED_GRID;
		authoredBackground.width = controlWidth;
		authoredBackground.height = controlHeight;
		while (focusBackground.numChildren > 0) focusBackground.removeChildAt(0);
		focusBackground.addChild(NativeAssets.svg(StaticSvg.FocusRect));
		focusBackground.scale9Grid = FOCUS_GRID;
		focusBackground.width = controlWidth;
		focusBackground.height = controlHeight;
		focusBackground.visible = focused && enabled;
	}

	override public function enabledChanged(value:Bool):Void {
		if (textField == null) return;
		textField.mouseEnabled = value;
		textField.selectable = value;
		textField.type = value && editable ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
		verticalScrollBar.enabled = value;
		applyTextFormat();
		redraw();
	}

	override public function dispose():Void {
		textField.removeEventListener(Event.CHANGE, onTextChange);
		textField.removeEventListener(Event.SCROLL, onFieldScroll);
		verticalScrollBar.onScroll = null;
		verticalScrollBar.dispose();
		onChange = null;
		super.dispose();
	}

	public function append(value:String):Void {
		textField.appendText(value == null ? "" : value);
		syncScrollBar();
	}

	public function setSelection(beginIndex:Int, endIndex:Int):Void textField.setSelection(beginIndex, endIndex);

	private function get_text():String return textField.text;
	private function set_text(value:String):String {
		textField.text = value == null ? "" : value;
		syncScrollBar();
		return textField.text;
	}
	private function get_htmlText():String return textField.htmlText;
	private function set_htmlText(value:String):String {
		textField.htmlText = value == null ? "" : value;
		syncScrollBar();
		return textField.htmlText;
	}
	private function get_restrict():String return textField.restrict;
	private function set_restrict(value:String):String return textField.restrict = value;
	private function get_maxChars():Int return textField.maxChars;
	private function set_maxChars(value:Int):Int return textField.maxChars = value;
	private function set_editable(value:Bool):Bool {
		editable = value;
		if (textField != null) textField.type = enabled && value ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
		return value;
	}
	private function set_wordWrap(value:Bool):Bool {
		wordWrap = value;
		if (textField != null) {
			textField.wordWrap = value;
			syncScrollBar();
		}
		return value;
	}
	private function set_verticalScrollPolicy(value:String):String {
		if (value != "auto" && value != "on" && value != "off") throw "Invalid vertical scroll policy";
		verticalScrollPolicy = value;
		if (textField != null) syncScrollBar();
		return value;
	}

	private function onTextChange(event:Event):Void {
		if (event.target != textField) return;
		syncScrollBar();
		if (onChange != null) onChange(text);
		dispatchEvent(new Event(Event.CHANGE));
	}

	private function onFieldScroll(_:Event):Void syncScrollBar();

	private function layoutChildren():Void {
		textField.x = 3;
		textField.y = 3;
		textField.height = Math.max(1, controlHeight - 6);
		verticalScrollBar.x = controlWidth - SCROLL_WIDTH - 1;
		verticalScrollBar.y = 1;
		verticalScrollBar.setSize(SCROLL_WIDTH, Math.max(30, controlHeight - 2));
		syncScrollBar();
	}

	private function syncScrollBar():Void {
		if (verticalScrollBar == null || textField == null) return;
		// Flash TextArea defaults to ScrollPolicy.AUTO. Measure at the full text
		// width first so removing the scrollbar can also remove wrapping overflow.
		textField.width = Math.max(1, controlWidth - 6);
		var showScrollBar = verticalScrollPolicy == "on"
			|| (verticalScrollPolicy == "auto" && textField.maxScrollV > 1);
		verticalScrollBar.visible = showScrollBar;
		if (showScrollBar) textField.width = Math.max(1, controlWidth - SCROLL_WIDTH - 6);
		else if (textField.scrollV != 1) textField.scrollV = 1;
		var visibleLines = Math.max(1, textField.bottomScrollV - textField.scrollV + 1);
		verticalScrollBar.setScrollProperties(visibleLines, 1, Math.max(1, textField.maxScrollV));
		verticalScrollBar.value = textField.scrollV;
	}

	private function textFormatForState():TextFormat {
		return new TextFormat(NativeAssets.font(FontAsset.Body), 11, enabled ? 0x000000 : 0x999999, false, false, false, null, null,
			TextFormatAlign.LEFT);
	}

	private function authoredAsset():StaticSvg return enabled ? StaticSvg.TextAreaUp : StaticSvg.TextAreaDisabled;

	private function applyTextFormat():Void {
		var format = textFormatForState();
		textField.defaultTextFormat = format;
		textField.setTextFormat(format);
	}
}
