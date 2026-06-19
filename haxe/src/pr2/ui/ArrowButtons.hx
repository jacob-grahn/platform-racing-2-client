package pr2.ui;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import pr2.lobby.LobbyArt;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `ui.ArrowButtons`: a left/right stepper over a fixed array of
	values. Clicking wraps around the array ends and dispatches `Event.CHANGE`
	carrying the newly selected `value`.
**/
class ArrowButtons extends Sprite {
	public var value:Int = 0;

	private var art:PR2MovieClip;
	private var leftButton:Null<DisplayObject>;
	private var rightButton:Null<DisplayObject>;
	private var leftBinding:Null<LobbyArt.Binding>;
	private var rightBinding:Null<LobbyArt.Binding>;
	private var array:Array<Int>;
	private var index:Int = 0;

	public function new(values:Array<Int>, val:Int) {
		super();
		this.array = values;
		art = PR2MovieClip.fromLinkage("ArrowButtonsGraphic", {maxNestedDepth: 4});
		addChild(art);
		leftButton = LobbyArt.findByName(art, "left");
		rightButton = LobbyArt.findByName(art, "right");
		leftBinding = LobbyArt.bind(leftButton, clickLeft);
		rightBinding = LobbyArt.bind(rightButton, clickRight);
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
		LobbyArt.unbind(leftBinding);
		LobbyArt.unbind(rightBinding);
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
