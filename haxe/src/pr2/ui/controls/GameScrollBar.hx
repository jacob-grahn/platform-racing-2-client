package pr2.ui.controls;

import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.ui.Keyboard;

class GameScrollBar extends NativeControl {
	public var minimum(default, null):Float;
	public var maximum(default, null):Float;
	public var pageSize(default, null):Float;
	public var lineStep(default, null):Float;
	public var value(default, set):Float;
	public var onScroll:Null<Float->Void>;

	public function new(minimum:Float = 0, maximum:Float = 100, pageSize:Float = 10, lineStep:Float = 1, ?skin:ControlSkin) {
		if (maximum < minimum || pageSize < 0 || lineStep <= 0) throw "Invalid scroll bar range";
		super(16, 100, skin);
		this.minimum = minimum;
		this.maximum = maximum;
		this.pageSize = pageSize;
		this.lineStep = lineStep;
		this.value = minimum;
		addEventListener(KeyboardEvent.KEY_DOWN, scrollFromKey);
		addEventListener(MouseEvent.MOUSE_WHEEL, scrollFromWheel);
	}

	public function scrollTo(next:Float):Void {
		if (!enabled || disposed) return;
		var before = value;
		value = next;
		if (value != before) { if (onScroll != null) onScroll(value); dispatchEvent(new Event(Event.SCROLL)); }
	}

	override public function dispose():Void { removeEventListener(KeyboardEvent.KEY_DOWN, scrollFromKey); removeEventListener(MouseEvent.MOUSE_WHEEL, scrollFromWheel); onScroll = null; super.dispose(); }
	private function set_value(next:Float):Float { value = Math.max(minimum, Math.min(maximum, next)); redraw(); return value; }
	private function scrollFromWheel(event:MouseEvent):Void scrollTo(value - event.delta * lineStep);
	private function scrollFromKey(event:KeyboardEvent):Void {
		if (event.keyCode == Keyboard.UP || event.keyCode == Keyboard.LEFT) scrollTo(value - lineStep);
		if (event.keyCode == Keyboard.DOWN || event.keyCode == Keyboard.RIGHT) scrollTo(value + lineStep);
		if (event.keyCode == Keyboard.PAGE_UP) scrollTo(value - pageSize);
		if (event.keyCode == Keyboard.PAGE_DOWN) scrollTo(value + pageSize);
		if (event.keyCode == Keyboard.HOME) scrollTo(minimum);
		if (event.keyCode == Keyboard.END) scrollTo(maximum);
	}
}
