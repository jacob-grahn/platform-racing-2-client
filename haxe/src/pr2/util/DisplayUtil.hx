package pr2.util;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;

/**
	Shared helpers for walking OpenFL display trees.
**/
class DisplayUtil {
	/**
		Find the first descendant of `container` whose `name` matches, searching
		breadth-first so the shallowest match wins. This matters when the same
		instance name appears at multiple depths: a depth-first walk can return a
		deeply nested decoy instead of the intended top-level instance.

		Does not consider `container` itself. Returns `null` when `container` is
		`null` or no match is found.
	**/
	public static function findByName(container:Null<DisplayObjectContainer>, name:String):Null<DisplayObject> {
		if (container == null) {
			return null;
		}
		var queue:Array<DisplayObjectContainer> = [container];
		var head = 0;
		while (head < queue.length) {
			var current = queue[head++];
			for (i in 0...current.numChildren) {
				var child = current.getChildAt(i);
				if (child.name == name) {
					return child;
				}
				var childContainer = Std.downcast(child, DisplayObjectContainer);
				if (childContainer != null) {
					queue.push(childContainer);
				}
			}
		}
		return null;
	}
}
