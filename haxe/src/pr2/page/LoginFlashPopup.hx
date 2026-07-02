package pr2.page;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.Constants;
import pr2.runtime.FlCheckBox;
import pr2.runtime.FlComponents;
import pr2.runtime.FlComboBox;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class LoginFlashPopup extends Sprite {
	private var art:PR2MovieClip;
	private var buttonHandlers:Array<{target:DisplayObject, handler:MouseEvent->Void}> = [];
	private var comboHandlers:Array<{target:FlComboBox, handler:Event->Void}> = [];
	private var keyHandlers:Array<{target:TextField, handler:KeyboardEvent->Void}> = [];

	public function new(linkage:String) {
		super();
		graphics.beginFill(0x000000, 0.55);
		graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		graphics.endFill();

		art = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 6});
		art.x = Constants.STAGE_WIDTH / 2;
		art.y = Constants.STAGE_HEIGHT / 2;
		addChild(art);
	}

	public function child(name:String):Null<DisplayObject> {
		return DisplayUtil.findByName(art, name);
	}

	public function input(name:String):TextField {
		// nameBox/passBox/etc. are authored as fl.controls.TextInput components, so
		// unwrap the FlTextInput/FlTextArea sprite to its inner editable field.
		var field = FlComponents.asTextField(child(name));
		if (field == null) {
			throw 'Popup ${art.symbol.linkageClassName} missing TextInput $name';
		}
		return field;
	}

	public function comboBox(name:String):Null<FlComboBox> {
		return Std.downcast(child(name), FlComboBox);
	}

	public function checkBox(name:String):Null<FlCheckBox> {
		return Std.downcast(child(name), FlCheckBox);
	}

	public function bindComboBox(name:String, changeHandler:FlComboBox->Void):Void {
		var target = comboBox(name);
		if (target == null) {
			return;
		}
		var handler = function(_:Event):Void {
			changeHandler(target);
		};
		target.addEventListener(Event.CHANGE, handler);
		comboHandlers.push({target: target, handler: handler});
	}

	public function bindButton(name:String, clickHandler:Void->Void):Void {
		var target = child(name);
		if (target == null) {
			return;
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
		var handler = function(_:MouseEvent):Void {
			clickHandler();
		};
		target.addEventListener(MouseEvent.CLICK, handler);
		buttonHandlers.push({target: target, handler: handler});
	}

	public function setButtonEnabled(name:String, enabled:Bool, alpha:Float):Void {
		var target = child(name);
		if (target == null) return;
		target.alpha = alpha;
		var interactive = Std.downcast(target, InteractiveObject);
		if (interactive != null) interactive.mouseEnabled = enabled;
	}

	public function bindEnter(name:String, enterHandler:Void->Void):Void {
		var target = input(name);
		var handler = function(event:KeyboardEvent):Void {
			if (event.keyCode == 13) {
				enterHandler();
			}
		};
		target.addEventListener(KeyboardEvent.KEY_DOWN, handler);
		keyHandlers.push({target: target, handler: handler});
	}

	public function setComponentLabel(name:String, value:String):Void {
		var target = Std.downcast(child(name), DisplayObjectContainer);
		if (target == null) {
			return;
		}
		var text = firstTextField(target);
		if (text != null) {
			text.text = value;
		}
	}

	public function setText(name:String, value:String):Void {
		var text = FlComponents.asTextField(child(name));
		if (text != null) {
			text.text = value;
		}
	}

	public function setMessage(message:String):Void {
		// Some authored popups expose a textBox. Popups without one (notably the
		// animated connecting/login graphics) communicate through their timeline;
		// do not add synthetic status text over the authored art.
		setText("textBox", message);
	}

	public function remove():Void {
		for (entry in buttonHandlers) {
			entry.target.removeEventListener(MouseEvent.CLICK, entry.handler);
		}
		buttonHandlers = [];
		for (entry in comboHandlers) {
			entry.target.removeEventListener(Event.CHANGE, entry.handler);
		}
		comboHandlers = [];
		for (entry in keyHandlers) {
			entry.target.removeEventListener(KeyboardEvent.KEY_DOWN, entry.handler);
		}
		keyHandlers = [];
		art.dispose();
	}

	private function firstTextField(container:DisplayObjectContainer):Null<TextField> {
		for (i in 0...container.numChildren) {
			var display = container.getChildAt(i);
			var text = Std.downcast(display, TextField);
			if (text != null) {
				return text;
			}
			var childContainer = Std.downcast(display, DisplayObjectContainer);
			if (childContainer != null) {
				var found = firstTextField(childContainer);
				if (found != null) {
					return found;
				}
			}
		}
		return null;
	}
}
