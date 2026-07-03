package pr2.effects;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.runtime.PR2MovieClip;

class StarEffect extends Sprite {
	public static inline var LIFETIME_FRAMES:Int = 15;

	public var graphic(default, null):PR2MovieClip;
	private var framesRemaining:Int = LIFETIME_FRAMES;

	public function new(startX:Float, startY:Float) {
		super();
		x = startX;
		y = startY;
		graphic = PR2MovieClip.fromLinkage("PointyStar", {maxNestedDepth: 2});
		addChild(graphic);
		addEventListener(Event.ENTER_FRAME, tick);
	}

	private function tick(_:Event):Void {
		framesRemaining--;
		if (framesRemaining <= 0) {
			remove();
		}
	}

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, tick);
		if (graphic != null) {
			graphic.dispose();
			removeChild(graphic);
			graphic = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
