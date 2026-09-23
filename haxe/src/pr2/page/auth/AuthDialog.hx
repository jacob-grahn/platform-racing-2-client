package pr2.page.auth;

import openfl.display.DisplayObject;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.ui.controls.GameCheckBox;
import pr2.ui.controls.GameSelect;
import pr2.ui.controls.NativeControl;

/** Presentation contract consumed by LoginFlow. No authentication lives here. */
class AuthDialog extends Sprite {
	public var onSubmit:Null<Void->Void>;
	public var onCancel:Null<Void->Void>;
	public var onClose:Null<Void->Void>;
	public var onConfirm:Null<Void->Void>;
	public final kind:String;
	private var named:Map<String, DisplayObject> = [];
	private var cleanup:Array<Void->Void> = [];
	public function new(kind:String) { super(); this.kind = kind; }
	public function child(name:String):Null<DisplayObject> return named.get(name);
	public function input(name:String):TextField return cast child(name);
	public function comboBox(name:String):Null<GameSelect<Dynamic>> return Std.downcast(child(name), GameSelect);
	public function checkBox(name:String):Null<GameCheckBox> return Std.downcast(child(name), GameCheckBox);
	public function bindButton(name:String, action:Void->Void):Void {
		var target = child(name);
		if (target == null) return;
		if (name == "cancel_bt" || name == "var_1") onCancel = action;
		var handler = function(_:Event):Void action();
		target.addEventListener(MouseEvent.CLICK, handler);
		target.addEventListener(NativeControl.KEYBOARD_ACTIVATE, handler);
		cleanup.push(function():Void {
			target.removeEventListener(MouseEvent.CLICK, handler);
			target.removeEventListener(NativeControl.KEYBOARD_ACTIVATE, handler);
		});
	}
	public function bindEnter(name:String, action:Void->Void):Void {
		var target = input(name);
		var handler = function(e:KeyboardEvent):Void if (e.keyCode == 13) action();
		target.addEventListener(KeyboardEvent.KEY_DOWN, handler);
		cleanup.push(function():Void target.removeEventListener(KeyboardEvent.KEY_DOWN, handler));
	}
	public function bindComboBox(name:String, action:GameSelect<Dynamic>->Void):Void {
		var target = comboBox(name);
		if (target == null) return;
		var handler = function(_:Event):Void action(target);
		target.addEventListener(Event.CHANGE, handler);
		cleanup.push(function():Void target.removeEventListener(Event.CHANGE, handler));
	}
	public function setButtonEnabled(name:String, enabled:Bool, alpha:Float):Void {
		var target = child(name);
		if (target == null) return;
		target.alpha = alpha;
		var interactive = Std.downcast(target, InteractiveObject);
		if (interactive != null) interactive.mouseEnabled = enabled;
		var control = Std.downcast(target, NativeControl);
		if (control != null) control.enabled = enabled;
	}
	public function setComponentLabel(name:String, value:String):Void {
		var choice = comboBox(name);
		if (choice != null) choice.prompt = value;
	}
	public function setMessage(value:String):Void {}
	public function resizeViewport(width:Float, height:Float):Void {}
	public function dismiss(immediate:Bool = false):Void {
		for (fn in cleanup) fn();
		cleanup = [];
		onSubmit = onCancel = onClose = onConfirm = null;
		if (parent != null) parent.removeChild(this);
	}
}
