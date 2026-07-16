package pr2.ui.controls;

import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

class GameSlider extends NativeControl {
	public var minimum(default, null):Float;
	public var maximum(default, null):Float;
	public var step(default, null):Float;
	public var value(default, set):Float;
	public var onChange:Null<Float->Void>;

	public function new(minimum:Float = 0, maximum:Float = 10, value:Float = 0, step:Float = 1, ?skin:ControlSkin) {
		if (maximum < minimum || step <= 0) throw "Invalid slider range";
		super(100, 22, skin);
		this.minimum = minimum;
		this.maximum = maximum;
		this.step = step;
		this.value = value;
		addEventListener(KeyboardEvent.KEY_DOWN, adjustFromKey);
	}

	public function setValueFromUser(next:Float):Void {
		if (!enabled || disposed) return;
		var before = value;
		value = next;
		if (value != before) { if (onChange != null) onChange(value); dispatchEvent(new Event(Event.CHANGE)); }
	}

	override public function dispose():Void { removeEventListener(KeyboardEvent.KEY_DOWN, adjustFromKey); onChange = null; super.dispose(); }
	private function set_value(next:Float):Float {
		var clamped = Math.max(minimum, Math.min(maximum, next));
		value = minimum + Math.round((clamped - minimum) / step) * step;
		redraw();
		return value;
	}
	private function adjustFromKey(event:KeyboardEvent):Void {
		if (event.keyCode == Keyboard.LEFT || event.keyCode == Keyboard.DOWN) setValueFromUser(value - step);
		if (event.keyCode == Keyboard.RIGHT || event.keyCode == Keyboard.UP) setValueFromUser(value + step);
		if (event.keyCode == Keyboard.HOME) setValueFromUser(minimum);
		if (event.keyCode == Keyboard.END) setValueFromUser(maximum);
	}
}
