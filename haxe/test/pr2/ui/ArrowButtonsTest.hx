package pr2.ui;

import openfl.events.Event;
import pr2.ui.controls.NativeControl;

/** Native stepper controls retain wrap, disabled, and keyboard activation behavior. */
class ArrowButtonsTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var arrows = new ArrowButtons([10, 20, 30], 20);
		var changes = 0;
		arrows.addEventListener(Event.CHANGE, function(_):Void changes++);
		var left:NativeControl = cast arrows.getChildAt(0);
		var right:NativeControl = cast arrows.getChildAt(1);
		left.activate();
		assertEquals(10, arrows.value, "left native control steps backward");
		right.activate();
		right.activate();
		assertEquals(30, arrows.value, "right native control wraps through values");
		left.enabled = false;
		left.activate();
		assertEquals(30, arrows.value, "disabled native control does not change value");
		assertEquals(3, changes, "only successful control activations dispatch changes");
		arrows.remove();
		trace('ArrowButtonsTest passed $assertions assertions');
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
