package pr2.ui.controls;

import openfl.display.Sprite;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;

class NativeControl extends Sprite {
	public var enabled(get, set):Bool;
	public var focused(default, null):Bool = false;
	public var disposed(default, null):Bool = false;
	public var controlWidth(default, null):Float;
	public var controlHeight(default, null):Float;
	public var skin:ControlSkin;

	private var _enabled:Bool = true;
	public var hovered(default, null):Bool = false;
	public var pressed(default, null):Bool = false;

	public function new(width:Float, height:Float, ?skin:ControlSkin) {
		super();
		controlWidth = width;
		controlHeight = height;
		this.skin = skin == null ? new DefaultControlSkin() : skin;
		tabEnabled = true;
		buttonMode = true;
		addEventListener(MouseEvent.ROLL_OVER, onRollOver);
		addEventListener(MouseEvent.ROLL_OUT, onRollOut);
		addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		addEventListener(FocusEvent.FOCUS_IN, onFocusIn);
		addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
		addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		redraw();
	}

	public function setSize(width:Float, height:Float):Void {
		controlWidth = width;
		controlHeight = height;
		redraw();
	}

	public function focus():Void {
		if (!enabled || disposed) return;
		focused = true;
		if (stage != null && stage.focus != this) stage.focus = this;
		redraw();
	}

	public function blur():Void {
		focused = false;
		pressed = false;
		if (stage != null && stage.focus == this) stage.focus = null;
		redraw();
	}

	public function dispose():Void {
		if (disposed) return;
		disposed = true;
		removeEventListener(MouseEvent.ROLL_OVER, onRollOver);
		removeEventListener(MouseEvent.ROLL_OUT, onRollOut);
		removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		removeEventListener(FocusEvent.FOCUS_IN, onFocusIn);
		removeEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
		removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		focused = false;
		mouseEnabled = false;
		mouseChildren = false;
	}

	public function activate():Void {}

	public function state():ControlState {
		if (!enabled) return Disabled;
		if (pressed) return Pressed;
		if (focused) return Focused;
		if (hovered) return Hovered;
		return Normal;
	}

	public function redraw():Void {
		skin.draw(graphics, controlWidth, controlHeight, state());
	}

	private function get_enabled():Bool return _enabled;

	private function set_enabled(value:Bool):Bool {
		_enabled = value;
		if (!value) {
			hovered = false;
			pressed = false;
		}
		mouseEnabled = value && !disposed;
		mouseChildren = value && !disposed;
		buttonMode = value && !disposed;
		enabledChanged(value);
		if (!value) blur(); else redraw();
		return value;
	}

	public function enabledChanged(value:Bool):Void {}

	private function onRollOver(_):Void { if (enabled) { hovered = true; redraw(); } }
	private function onRollOut(_):Void { hovered = false; pressed = false; redraw(); }
	private function onMouseDown(_):Void { if (enabled) { pressed = true; focus(); redraw(); } }
	private function onMouseUp(_):Void { if (enabled) { pressed = false; redraw(); } }
	private function onFocusIn(_):Void focus();
	private function onFocusOut(_):Void blur();
	private function onKeyDown(event:KeyboardEvent):Void {
		if (!enabled) return;
		if (event.keyCode == 13 || event.keyCode == 32) activate();
	}
}
