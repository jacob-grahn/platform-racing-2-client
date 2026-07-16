package pr2.ui;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.ControlState;
import pr2.ui.controls.NativeControl;

/**
	Port of Flash `ui.ArrowButtons`: a left/right stepper over a fixed array of
	values. Clicking wraps around the array ends and dispatches `Event.CHANGE`
	carrying the newly selected `value`.
**/
class ArrowButtons extends Sprite {
	public var value:Int = 0;

	private var leftButton:ArrowStepperButton;
	private var rightButton:ArrowStepperButton;
	private var array:Array<Int>;
	private var index:Int = 0;

	public function new(values:Array<Int>, val:Int) {
		super();
		this.array = values;
		leftButton = new ArrowStepperButton(false, clickLeft);
		rightButton = new ArrowStepperButton(true, clickRight);
		rightButton.x = 100;
		addChild(leftButton);
		addChild(rightButton);
		setValue(val);
	}

	private function clickLeft():Void {
		index--;
		wrapCheck();
	}

	private function clickRight():Void {
		index++;
		wrapCheck();
	}

	private function wrapCheck():Void {
		var lastKey = array.length - 1;
		index = index < 0 ? lastKey : (index > lastKey ? 0 : index);
		value = array.length > 0 ? array[index] : value;
		dispatchEvent(new Event(Event.CHANGE));
	}

	public function setValue(val:Int):Void {
		var pos = array.indexOf(val);
		if (pos == -1) {
			pos = 0;
		} else {
			value = val;
			index = pos;
		}
		dispatchEvent(new Event(Event.CHANGE));
	}

	public function remove():Void {
		leftButton.dispose();
		rightButton.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}

/** Native focusable control retaining the authored ArrowButton state artwork. */
private class ArrowStepperButton extends NativeControl {
	private var pointsRight:Bool;
	private var action:Void->Void;
	private var visual:Null<Shape>;

	public function new(pointsRight:Bool, action:Void->Void) {
		super(10, 16);
		this.pointsRight = pointsRight;
		this.action = action;
		redraw();
	}

	override public function activate():Void {
		if (enabled && !disposed) action();
	}

	override public function redraw():Void {
		graphics.clear();
		if (visual != null) removeChild(visual);
		if (disposed) return;
		visual = NativeAssets.svg(assetForState());
		if (!pointsRight) {
			visual.scaleX = -1;
			visual.x = 10;
		}
		addChild(visual);
	}

	override public function dispose():Void {
		action = function():Void {};
		super.dispose();
	}

	private function assetForState():StaticSvg {
		return switch (state()) {
			case Disabled: StaticSvg.ArrowButtonDisabled;
			case Hovered | Focused: StaticSvg.ArrowButtonOver;
			case Pressed: StaticSvg.ArrowButtonDown;
			case Normal | Selected: StaticSvg.ArrowButtonUp;
		};
	}
}
