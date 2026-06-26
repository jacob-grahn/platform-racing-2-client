package pr2.gameplay;

import openfl.display.Sprite;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `gameplay.Hearts`.

	A vertical stack of small heart icons showing remaining deathmatch lives.
	`setHearts` grows or shrinks the stack toward the requested count, clamped to
	0..15 like `Data.numLimit`. Each heart is a `HeartGraphic` scaled to 0.2 and
	stepped 20px down the column.
**/
class Hearts extends Sprite {
	static inline var Y_INC:Int = 20;
	static inline var SCALE:Float = 0.2;

	private var hearts:Array<PR2MovieClip> = [];

	public var totalHearts(default, null):Int = 0;

	public function new() {
		super();
		mouseEnabled = false;
		mouseChildren = false;
	}

	public function setHearts(numHearts:Int):Void {
		numHearts = numLimit(numHearts, 0, 15);
		while (totalHearts < numHearts) {
			addHeart();
		}
		while (totalHearts > numHearts) {
			removeHeart();
		}
	}

	public function getHeartCount():Int {
		return totalHearts;
	}

	private function addHeart():Void {
		var m = PR2MovieClip.fromLinkage("HeartGraphic", {maxNestedDepth: 2});
		m.scaleX = m.scaleY = SCALE;
		m.x = 0;
		m.y = totalHearts * Y_INC;
		addChild(m);
		hearts.push(m);
		totalHearts++;
	}

	private function removeHeart():Void {
		var m = hearts.pop();
		if (m != null) {
			if (m.parent != null) {
				m.parent.removeChild(m);
			}
			m.dispose();
		}
		totalHearts--;
	}

	public function remove():Void {
		while (hearts.length > 0) {
			var m = hearts.pop();
			if (m != null) {
				if (m.parent != null) {
					m.parent.removeChild(m);
				}
				m.dispose();
			}
		}
		totalHearts = 0;
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	/** Mirrors `Data.numLimit`: clamp to the inclusive [min, max] range. */
	public static function numLimit(value:Int, min:Int, max:Int):Int {
		return value < min ? min : (value > max ? max : value);
	}
}
