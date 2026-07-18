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

/** Native fl.controls.TextInput using the exact authored component skins. */
class GameTextInput extends NativeControl {
	private static final UP_GRID = new Rectangle(2.25, 1.45, 147.8, 18.6);
	private static final DISABLED_GRID = new Rectangle(2, 2, 148, 17.95);
	private static final FOCUS_GRID = new Rectangle(4, 2, 74, 18);

	public var text(get, set):String;
	public var htmlText(get, set):String;
	public var displayAsPassword(get, set):Bool;
	public var restrict(get, set):String;
	public var maxChars(get, set):Int;
	public var selectionBeginIndex(get, never):Int;
	public var selectionEndIndex(get, never):Int;
	public var editable(default, set):Bool = true;
	public var onChange:Null<String->Void>;
	public final textField:TextField;

	private var useAuthoredSkin:Bool = false;
	private var authoredBackground:Null<Sprite>;
	private var focusBackground:Null<Sprite>;

	public function new(text:String = "", ?skin:ControlSkin) {
		super(100, 22, skin);
		buttonMode = false;
		useHandCursor = false;
		useAuthoredSkin = skin == null;
		if (useAuthoredSkin) {
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
		}

		textField = new TextField();
		textField.type = TextFieldType.INPUT;
		textField.multiline = false;
		textField.wordWrap = false;
		textField.selectable = true;
		textField.mouseEnabled = true;
		textField.autoSize = TextFieldAutoSize.NONE;
		textField.defaultTextFormat = textFormatForState();
		textField.text = text == null ? "" : text;
		addChild(textField);
		textField.addEventListener(Event.CHANGE, onTextChange);
		layoutField();
		redraw();
	}

	override public function setSize(width:Float, height:Float):Void {
		super.setSize(width, height);
		layoutField();
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
		if (!useAuthoredSkin || authoredBackground == null || focusBackground == null) {
			super.redraw();
			return;
		}
		graphics.clear();
		while (authoredBackground.numChildren > 0) authoredBackground.removeChildAt(0);
		var background = NativeAssets.svg(authoredAsset());
		authoredBackground.addChild(background);
		authoredBackground.scale9Grid = enabled ? UP_GRID : DISABLED_GRID;
		authoredBackground.width = controlWidth;
		authoredBackground.height = controlHeight;

		while (focusBackground.numChildren > 0) focusBackground.removeChildAt(0);
		var focusArt = NativeAssets.svg(StaticSvg.FocusRect);
		focusBackground.addChild(focusArt);
		focusBackground.scale9Grid = FOCUS_GRID;
		focusBackground.width = controlWidth;
		focusBackground.height = controlHeight;
		focusBackground.visible = focused && enabled;
	}

	override public function enabledChanged(value:Bool):Void {
		if (textField == null) return;
		updateFieldInteraction();
		applyTextFormat();
		redraw();
	}

	override public function dispose():Void {
		textField.removeEventListener(Event.CHANGE, onTextChange);
		onChange = null;
		textField.type = TextFieldType.DYNAMIC;
		textField.selectable = false;
		textField.mouseEnabled = false;
		super.dispose();
	}

	public function setSelection(beginIndex:Int, endIndex:Int):Void textField.setSelection(beginIndex, endIndex);
	public function appendText(value:String):Void textField.appendText(value == null ? "" : value);

	private function get_text():String return textField.text;
	private function set_text(value:String):String {
		textField.text = value == null ? "" : value;
		return textField.text;
	}
	private function get_htmlText():String return textField.htmlText;
	private function set_htmlText(value:String):String {
		textField.htmlText = value == null ? "" : value;
		return textField.htmlText;
	}
	private function get_displayAsPassword():Bool return textField.displayAsPassword;
	private function set_displayAsPassword(value:Bool):Bool return textField.displayAsPassword = value;
	private function get_restrict():String return textField.restrict;
	private function set_restrict(value:String):String return textField.restrict = value;
	private function get_maxChars():Int return textField.maxChars;
	private function set_maxChars(value:Int):Int return textField.maxChars = value;
	private function get_selectionBeginIndex():Int return textField.selectionBeginIndex;
	private function get_selectionEndIndex():Int return textField.selectionEndIndex;
	private function set_editable(value:Bool):Bool {
		editable = value;
		if (textField != null) updateFieldInteraction();
		return value;
	}

	private function onTextChange(event:Event):Void {
		if (event.target != textField) return;
		if (onChange != null) onChange(text);
		dispatchEvent(new Event(Event.CHANGE));
	}

	private function updateFieldInteraction():Void {
		textField.mouseEnabled = enabled;
		textField.selectable = enabled;
		textField.type = enabled && editable ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
	}

	private function textFormatForState():TextFormat {
		return new TextFormat(NativeAssets.font(FontAsset.Body), 11, enabled ? 0x000000 : 0x999999, false, false, false, null, null,
			TextFormatAlign.LEFT);
	}

	private function authoredAsset():StaticSvg return enabled ? StaticSvg.TextInputUp : StaticSvg.TextInputDisabled;

	private function applyTextFormat():Void {
		var format = textFormatForState();
		textField.defaultTextFormat = format;
		textField.setTextFormat(format);
	}

	private function layoutField():Void {
		textField.x = 5;
		textField.y = 1;
		textField.width = Math.max(1, controlWidth - 10);
		textField.height = Math.max(1, controlHeight - 2);
	}
}
