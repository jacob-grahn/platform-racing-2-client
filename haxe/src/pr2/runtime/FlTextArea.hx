package pr2.runtime;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

/**
	A faithful port of the Flash `fl.controls.TextArea` component (library item
	`Components/TextArea`, linkage `fl.controls.TextArea`). Used by RaceChat and
	the OutfitPopup.

	A multiline, word-wrapping `TextField` drawn over the `TextArea_upSkin`
	background with an attached `FlUIScrollBar` down the right edge. Mirrors the
	bits of the fl API the source touches: `text`, `htmlText`, `editable`,
	`append`, `setSize`, and `Event.CHANGE`. Replaces the generic grey
	placeholder.
**/
class FlTextArea extends Sprite {
	// TextArea_upSkin is a white box with a 1px inset border. The skin art is only
	// 22px tall, so scaling it to a multiline box (~14x) smears that 1px border
	// into thick grey bands; we draw the border ourselves at the exact size
	// instead. Colours lifted straight from the skin's fills.
	private static inline final BORDER_OUTER:Int = 0xC9CBCC;
	private static inline final BORDER_SHADOW:Int = 0x6D6F70;
	private static inline final FILL_ENABLED:Int = 0xFFFFFF;
	private static inline final FILL_DISABLED:Int = 0xEEEEEE;

	private var background:Shape;
	private var field:TextField;
	private var scrollBar:FlUIScrollBar;

	private var boxWidth:Float = 160;
	private var boxHeight:Float = 100;

	private var _enabled:Bool = true;

	public var text(get, set):String;
	public var htmlText(get, set):String;
	public var editable(get, set):Bool;
	public var enabled(get, set):Bool;
	public var restrict(get, set):String;
	public var maxChars(get, set):Int;
	public var textField(get, never):TextField;
	public var verticalScrollBar(get, never):FlUIScrollBar;

	public function new(width:Float = 160, height:Float = 100) {
		super();
		boxWidth = width;
		boxHeight = height;

		background = new Shape();
		addChild(background);

		field = new TextField();
		field.type = TextFieldType.DYNAMIC;
		field.multiline = true;
		field.wordWrap = true;
		field.selectable = true;
		field.mouseEnabled = true;
		field.autoSize = TextFieldAutoSize.NONE;
		field.defaultTextFormat = new TextFormat(
			FontResolver.resolve("Arial"), 11, 0x111111, false, false, false, null, null, TextFormatAlign.LEFT
		);
		field.addEventListener(Event.CHANGE, onFieldChange);
		field.addEventListener(Event.SCROLL, function(_) scrollBar.syncFromTarget());
		addChild(field);

		scrollBar = new FlUIScrollBar(height);
		scrollBar.scrollTarget = field;
		addChild(scrollBar);

		redraw();
		layout();
	}

	public function setSize(width:Float, height:Float):Void {
		boxWidth = width;
		boxHeight = height;
		redraw();
		layout();
	}

	public function append(value:String):Void {
		field.appendText(value);
		afterTextChange();
	}

	private function onFieldChange(_):Void {
		afterTextChange();
		dispatchEvent(new Event(Event.CHANGE));
	}

	private function afterTextChange():Void {
		scrollBar.syncFromTarget();
	}

	private function get_text():String {
		return field.text;
	}

	private function set_text(value:String):String {
		field.text = value == null ? "" : value;
		afterTextChange();
		return field.text;
	}

	private function get_htmlText():String {
		return field.htmlText;
	}

	private function set_htmlText(value:String):String {
		field.htmlText = value == null ? "" : value;
		afterTextChange();
		return field.htmlText;
	}

	private function get_editable():Bool {
		return field.type == TextFieldType.INPUT;
	}

	private function set_editable(value:Bool):Bool {
		field.type = value ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
		return value;
	}

	private function get_enabled():Bool {
		return _enabled;
	}

	private function set_enabled(value:Bool):Bool {
		if (_enabled == value) {
			return _enabled;
		}
		_enabled = value;
		field.mouseEnabled = value;
		field.selectable = value;
		redraw();
		return _enabled;
	}

	private function get_restrict():String {
		return field.restrict;
	}

	private function set_restrict(value:String):String {
		field.restrict = value;
		return value;
	}

	private function get_maxChars():Int {
		return field.maxChars;
	}

	private function set_maxChars(value:Int):Int {
		field.maxChars = value;
		return value;
	}

	private function get_textField():TextField {
		return field;
	}

	private function get_verticalScrollBar():FlUIScrollBar {
		return scrollBar;
	}

	/** Draw the white field box with its 1px inset border at the exact size. */
	private function redraw():Void {
		var g = background.graphics;
		g.clear();
		// Outer 1px frame.
		g.beginFill(BORDER_OUTER);
		g.drawRect(0, 0, boxWidth, boxHeight);
		g.endFill();
		// Inner fill, inset by the 1px border, with a faint top/left shadow line.
		g.beginFill(BORDER_SHADOW);
		g.drawRect(1, 1, boxWidth - 2, boxHeight - 2);
		g.endFill();
		g.beginFill(_enabled ? FILL_ENABLED : FILL_DISABLED);
		g.drawRect(1, 2, boxWidth - 2, boxHeight - 3);
		g.endFill();
	}

	private function layout():Void {
		field.x = 3;
		field.y = 3;
		field.width = Math.max(1, boxWidth - FlUIScrollBar.WIDTH - 6);
		field.height = Math.max(1, boxHeight - 6);

		scrollBar.x = boxWidth - FlUIScrollBar.WIDTH - 1;
		scrollBar.y = 1;
		scrollBar.setSize(boxHeight - 2);
		scrollBar.syncFromTarget();
	}
}
