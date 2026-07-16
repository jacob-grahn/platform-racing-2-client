package pr2.ui.controls;

import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.ui.Keyboard;

class GameSlider extends NativeControl {
	public var minimum(default, null):Float;
	public var maximum(default, null):Float;
	public var step(default, null):Float;
	public var value(default, set):Float;
	public var onChange:Null<Float->Void>;
	private final thumb:openfl.display.Sprite;
	private var dragging:Bool = false;

	public function new(minimum:Float = 0, maximum:Float = 10, value:Float = 0, step:Float = 1, ?skin:ControlSkin) {
		if (maximum < minimum || step <= 0) throw "Invalid slider range";
		super(100, 22, skin == null ? new SliderControlSkin() : skin);
		this.minimum = minimum;
		this.maximum = maximum;
		this.step = step;
		thumb = new openfl.display.Sprite();
		thumb.mouseEnabled = false;
		addChild(thumb);
		this.value = value;
		addEventListener(KeyboardEvent.KEY_DOWN, adjustFromKey);
		addEventListener(MouseEvent.MOUSE_DOWN, beginDrag);
		addEventListener(MouseEvent.CLICK, selectFromMouse);
	}

	public function setValueFromUser(next:Float):Void {
		if (!enabled || disposed) return;
		var before = value;
		value = next;
		if (value != before) { if (onChange != null) onChange(value); dispatchEvent(new Event(Event.CHANGE)); }
	}

	override public function setSize(width:Float, height:Float):Void { super.setSize(width, height); drawThumb(); }
	override public function enabledChanged(value:Bool):Void drawThumb();
	override public function dispose():Void {
		removeEventListener(KeyboardEvent.KEY_DOWN, adjustFromKey);
		removeEventListener(MouseEvent.MOUSE_DOWN, beginDrag);
		removeEventListener(MouseEvent.CLICK, selectFromMouse);
		removeStageDragListeners();
		onChange = null;
		super.dispose();
	}
	private function set_value(next:Float):Float {
		var clamped = Math.max(minimum, Math.min(maximum, next));
		value = minimum + Math.round((clamped - minimum) / step) * step;
		redraw();
		if (thumb != null) drawThumb();
		return value;
	}
	private function selectFromMouse(event:MouseEvent):Void setValueFromPosition(event.localX);
	private function beginDrag(event:MouseEvent):Void {
		if (!enabled || stage == null) return;
		dragging = true;
		setValueFromPosition(event.localX);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, drag);
		stage.addEventListener(MouseEvent.MOUSE_UP, endDrag);
	}
	private function drag(event:MouseEvent):Void {
		if (!dragging) return;
		setValueFromPosition(globalToLocal(new openfl.geom.Point(event.stageX, event.stageY)).x);
	}
	private function endDrag(_:MouseEvent):Void { dragging = false; removeStageDragListeners(); }
	private function removeStageDragListeners():Void {
		if (stage == null) return;
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, drag);
		stage.removeEventListener(MouseEvent.MOUSE_UP, endDrag);
	}
	private function setValueFromPosition(localX:Float):Void {
		var usable = Math.max(1, controlWidth - 10);
		setValueFromUser(minimum + (maximum - minimum) * Math.max(0, Math.min(1, (localX - 5) / usable)));
	}
	private function drawThumb():Void {
		if (thumb == null) return;
		var ratio = maximum == minimum ? 0 : (value - minimum) / (maximum - minimum);
		thumb.graphics.clear();
		thumb.graphics.lineStyle(1, enabled ? 0x555555 : 0x999999);
		thumb.graphics.beginFill(enabled ? 0xEEEEEE : 0xCCCCCC);
		thumb.graphics.drawRoundRect(-5, -7, 10, 14, 3, 3);
		thumb.graphics.endFill();
		thumb.x = 5 + ratio * Math.max(1, controlWidth - 10);
		thumb.y = Math.floor(controlHeight / 2);
	}

	@:noCompletion public function setValueFromPositionForTests(localX:Float):Void setValueFromPosition(localX);
	private function adjustFromKey(event:KeyboardEvent):Void {
		if (event.keyCode == Keyboard.LEFT || event.keyCode == Keyboard.DOWN) setValueFromUser(value - step);
		if (event.keyCode == Keyboard.RIGHT || event.keyCode == Keyboard.UP) setValueFromUser(value + step);
		if (event.keyCode == Keyboard.HOME) setValueFromUser(minimum);
		if (event.keyCode == Keyboard.END) setValueFromUser(maximum);
	}
}
