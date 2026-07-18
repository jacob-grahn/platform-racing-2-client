package pr2.util;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;

/** Direct access helpers for explicitly constructed OpenFL views. */
class DisplayUtil {
	/**
		Return an immediate named child. Native callers must hold a typed reference
		to an intermediate container instead of searching an arbitrary subtree.
	**/
	public static function directChildByName(container:Null<DisplayObjectContainer>, name:String):Null<DisplayObject>
		return container == null ? null : container.getChildByName(name);
}
