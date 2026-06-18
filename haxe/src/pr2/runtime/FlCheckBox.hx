package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

/**
	A faithful port of the Flash `fl.controls.CheckBox` component (library item
	`Components/CheckBox`, linkage `fl.controls.CheckBox`).

	The original is a label plus a toggle icon skinned by the eight
	`Components/Component Assets/CheckBoxSkins/CheckBox_*Icon` symbols. PR2 source
	(options/song menus, block options, the login "remember me" box) drives it
	through three members:

	  - `selected` — get/set on/off state. Setting it in code updates the icon
	    but, like fl, does **not** dispatch `CHANGE` (only user clicks do).
	  - `label` — caption to the right of the icon.
	  - `Event.CHANGE` — dispatched when the user clicks to toggle the box.

	The icons are real library symbols instantiated through `PR2MovieClip` and
	swapped per mouse/selected state, matching the original artwork.
**/
class FlCheckBox extends Sprite {
	private static inline final ICON_PREFIX:String = "Components/Component Assets/CheckBoxSkins/CheckBox_";
	// fl authors the check icon at roughly 14x14 and pads the label 4px after it.
	private static inline final ICON_NOMINAL:Float = 14;
	private static inline final LABEL_GAP:Float = 4;

	private var iconHolder:Sprite;
	private var textField:TextField;
	private var iconCache:Map<String, DisplayObject> = new Map();
	private var currentIcon:Null<DisplayObject>;

	private var mouseOver:Bool = false;
	private var mouseDown:Bool = false;

	private var _label:String;
	private var _selected:Bool = false;
	private var _enabled:Bool = true;

	public var label(get, set):String;
	public var selected(get, set):Bool;
	public var enabled(get, set):Bool;

	public function new(label:String = "", selected:Bool = false) {
		super();
		_label = label == null ? "" : label;
		_selected = selected;

		iconHolder = new Sprite();
		addChild(iconHolder);

		textField = new TextField();
		textField.selectable = false;
		textField.mouseEnabled = false;
		textField.autoSize = TextFieldAutoSize.LEFT;
		textField.multiline = false;
		textField.defaultTextFormat = new TextFormat(
			FontResolver.resolve("Arial"), 11, 0x000000, false, false, false, null, null, TextFormatAlign.LEFT
		);
		textField.text = _label;
		addChild(textField);

		mouseChildren = false;
		buttonMode = true;
		useHandCursor = true;

		addEventListener(MouseEvent.ROLL_OVER, onRollOver);
		addEventListener(MouseEvent.ROLL_OUT, onRollOut);
		addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		addEventListener(MouseEvent.CLICK, onClick);

		redraw();
		layoutLabel();
	}

	private function get_label():String {
		return _label;
	}

	private function set_label(value:String):String {
		_label = value == null ? "" : value;
		textField.text = _label;
		layoutLabel();
		return _label;
	}

	private function get_selected():Bool {
		return _selected;
	}

	private function set_selected(value:Bool):Bool {
		if (_selected == value) {
			return _selected;
		}
		_selected = value;
		redraw();
		return _selected;
	}

	private function get_enabled():Bool {
		return _enabled;
	}

	private function set_enabled(value:Bool):Bool {
		if (_enabled == value) {
			return _enabled;
		}
		_enabled = value;
		mouseEnabled = value;
		buttonMode = value;
		useHandCursor = value;
		if (!value) {
			mouseOver = false;
			mouseDown = false;
		}
		redraw();
		return _enabled;
	}

	private function onRollOver(_):Void {
		mouseOver = true;
		redraw();
	}

	private function onRollOut(_):Void {
		mouseOver = false;
		mouseDown = false;
		redraw();
	}

	private function onMouseDown(_):Void {
		mouseDown = true;
		redraw();
	}

	private function onMouseUp(_):Void {
		mouseDown = false;
		redraw();
	}

	private function onClick(_):Void {
		// User interaction flips the box and fires CHANGE; programmatic
		// `selected =` does not, matching fl.controls.CheckBox.
		_selected = !_selected;
		redraw();
		dispatchEvent(new Event(Event.CHANGE));
	}

	private function currentStateName():String {
		var phase = !_enabled ? "disabled" : (mouseDown ? "down" : (mouseOver ? "over" : "up"));
		if (_selected) {
			return "selected" + phase.charAt(0).toUpperCase() + phase.substr(1) + "Icon";
		}
		return phase + "Icon";
	}

	private function redraw():Void {
		var icon = iconForState(currentStateName());
		if (icon == currentIcon) {
			return;
		}
		if (currentIcon != null && currentIcon.parent == iconHolder) {
			iconHolder.removeChild(currentIcon);
		}
		currentIcon = icon;
		if (icon != null) {
			iconHolder.addChild(icon);
		}
		layoutLabel();
	}

	private function iconForState(state:String):Null<DisplayObject> {
		var cached = iconCache.get(state);
		if (cached != null) {
			return cached;
		}
		var icon = FlSkin.create(ICON_PREFIX + state);
		if (icon == null) {
			return null;
		}
		iconCache.set(state, icon);
		return icon;
	}

	private function iconWidth():Float {
		if (currentIcon == null) {
			return ICON_NOMINAL;
		}
		var w = currentIcon.width;
		return w <= 0 ? ICON_NOMINAL : w;
	}

	private function layoutLabel():Void {
		textField.x = iconWidth() + LABEL_GAP;
		var iconH = currentIcon == null || currentIcon.height <= 0 ? ICON_NOMINAL : currentIcon.height;
		textField.y = (iconH - textField.height) / 2;
	}
}
