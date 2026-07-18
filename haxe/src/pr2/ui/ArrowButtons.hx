package pr2.ui;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.ui.controls.AuthoredArrowButton;

/**
	Port of Flash `ui.ArrowButtons`: a left/right stepper over a fixed array of
	values. Clicking wraps around the array ends and dispatches `Event.CHANGE`
	carrying the newly selected `value`.
**/
class ArrowButtons extends Sprite {
	public var value:Int = 0;

	private var leftButton:AuthoredArrowButton;
	private var rightButton:AuthoredArrowButton;
	private var array:Array<Int>;
	private var index:Int = 0;

	public function new(values:Array<Int>, val:Int) {
		super();
		this.array = values;
		leftButton = new AuthoredArrowButton(false, clickLeft);
		rightButton = new AuthoredArrowButton(true, clickRight);
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
