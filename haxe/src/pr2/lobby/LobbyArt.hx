package pr2.lobby;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;

/**
	Helpers shared by the lobby tab pages for poking at instance-named children of
	`PR2MovieClip` art: recursive name lookup, typed text-field access, and click
	wiring with bookkeeping so handlers can be cleanly removed on teardown. This is
	the same pattern the login popups use, factored out for reuse.
**/
class LobbyArt {
	private function new() {}

	public static function findByName(container:Null<DisplayObjectContainer>, name:String):Null<DisplayObject> {
		if (container == null) {
			return null;
		}
		for (i in 0...container.numChildren) {
			var child = container.getChildAt(i);
			if (child.name == name) {
				return child;
			}
			var childContainer = Std.downcast(child, DisplayObjectContainer);
			if (childContainer != null) {
				var found = findByName(childContainer, name);
				if (found != null) {
					return found;
				}
			}
		}
		return null;
	}

	public static function text(container:Null<DisplayObjectContainer>, name:String):Null<TextField> {
		return Std.downcast(findByName(container, name), TextField);
	}

	/**
		Make `target` behave like a button and call `handler` on click. Returns a
		binding token to pass to `unbind`.
	**/
	public static function bind(target:Null<DisplayObject>, handler:Void->Void):Null<Binding> {
		if (target == null) {
			return null;
		}
		var interactive = Std.downcast(target, InteractiveObject);
		if (interactive != null) {
			interactive.mouseEnabled = true;
		}
		var sprite = Std.downcast(target, Sprite);
		if (sprite != null) {
			sprite.buttonMode = true;
			sprite.useHandCursor = true;
			sprite.mouseChildren = false;
		}
		var listener = function(_:MouseEvent):Void {
			handler();
		};
		target.addEventListener(MouseEvent.CLICK, listener);
		return {target: target, listener: listener};
	}

	public static function unbind(binding:Null<Binding>):Void {
		if (binding != null) {
			binding.target.removeEventListener(MouseEvent.CLICK, binding.listener);
		}
	}
}

typedef Binding = {
	var target:DisplayObject;
	var listener:MouseEvent->Void;
};
