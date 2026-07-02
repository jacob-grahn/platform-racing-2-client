package pr2.lobby;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.runtime.FlComponents;
import pr2.util.DisplayUtil;

/**
	Helpers shared by the lobby tab pages for poking at instance-named children of
	`PR2MovieClip` art: recursive name lookup, typed text-field access, and click
	wiring with bookkeeping so handlers can be cleanly removed on teardown. This is
	the same pattern the login popups use, factored out for reuse.
**/
class LobbyArt {
	private function new() {}

	/**
		Find the named child nearest the container. The search is breadth-first so a
		field authored directly on the art (e.g. a popup's own `nameBox`) always wins
		over a same-named instance buried deeper in a nested symbol. That matters now
		that `PR2MovieClip` renders eye-hidden layers like Flash does: an avatar card
		or part symbol can carry its own empty `nameBox`, and a depth-first walk would
		return that stray field instead of the one the caller means.
	**/
	public static function text(container:Null<DisplayObjectContainer>, name:String):Null<TextField> {
		return FlComponents.asTextField(DisplayUtil.findByName(container, name));
	}

	/**
		Collect every `TextField` under `container`, left-to-right by x. Used to
		recover the name/rank/hats fields of art whose dynamic-text instances were
		exported without instance names (e.g. `PlayersTabListItemGraphic`).
	**/
	public static function textFields(container:Null<DisplayObjectContainer>):Array<TextField> {
		var fields:Array<TextField> = [];
		collectTextFields(container, fields);
		fields.sort(function(a, b) {
			return a.x < b.x ? -1 : (a.x > b.x ? 1 : 0);
		});
		return fields;
	}

	/**
		Immediate `TextField` children of `container`, top-to-bottom by y. Used to
		recover stacked text fields (e.g. `LevelItemGraphic`'s title above author)
		whose instances were exported without names, without pulling in text from
		nested sub-clips the way `textFields` would.
	**/
	public static function directTextFields(container:Null<DisplayObjectContainer>):Array<TextField> {
		var fields:Array<TextField> = [];
		if (container != null) {
			for (i in 0...container.numChildren) {
				var field = Std.downcast(container.getChildAt(i), TextField);
				if (field != null) {
					fields.push(field);
				}
			}
		}
		fields.sort(function(a, b) {
			return a.y < b.y ? -1 : (a.y > b.y ? 1 : 0);
		});
		return fields;
	}

	private static function collectTextFields(container:Null<DisplayObjectContainer>, into:Array<TextField>):Void {
		if (container == null) {
			return;
		}
		for (i in 0...container.numChildren) {
			var child = container.getChildAt(i);
			var field = Std.downcast(child, TextField);
			if (field != null) {
				into.push(field);
				continue;
			}
			var childContainer = Std.downcast(child, DisplayObjectContainer);
			if (childContainer != null) {
				collectTextFields(childContainer, into);
			}
		}
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
