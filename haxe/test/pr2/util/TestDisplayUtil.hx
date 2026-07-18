package pr2.util;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;

/** Test-only subtree search for assertions that inspect opaque display trees. */
class TestDisplayUtil {
	public static function findByName(container:Null<DisplayObjectContainer>, name:String):Null<DisplayObject> {
		if (container == null) return null;
		var queue:Array<DisplayObjectContainer> = [container];
		var head = 0;
		while (head < queue.length) {
			var current = queue[head++];
			for (i in 0...current.numChildren) {
				var child = current.getChildAt(i);
				if (child.name == name) return child;
				var nested = Std.downcast(child, DisplayObjectContainer);
				if (nested != null) queue.push(nested);
			}
		}
		return null;
	}
}
