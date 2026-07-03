package pr2.display;

import openfl.display.Sprite;
import openfl.events.Event;

/** Flash `Removable`: idempotent teardown with parent/child cleanup and event dispatch. */
class Removable extends Sprite {
	public static inline var REMOVE:String = "remove";

	private var removed:Bool = false;

	public function new() {
		super();
	}

	public function isRemoved():Bool {
		return removed;
	}

	public function safeRemove():Void {
		if (!removed) remove();
	}

	public function remove():Void {
		if (removed) return;
		removed = true;
		if (parent != null) parent.removeChild(this);
		while (numChildren > 0) removeChildAt(0);
		dispatchEvent(new Event(REMOVE));
	}
}
