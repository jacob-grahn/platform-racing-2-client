package pr2.page;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.Constants;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.runtime.FlCheckBox;
import pr2.runtime.FlComponents;
import pr2.runtime.FlComboBox;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;
import pr2.util.DisplayUtil;

class LoginFlashPopup extends Sprite {
	private var art:LoginPopupView;
	private var buttonHandlers:Array<{target:DisplayObject, handler:MouseEvent->Void}> = [];
	private var comboHandlers:Array<{target:FlComboBox, handler:Event->Void}> = [];
	private var keyHandlers:Array<{target:TextField, handler:KeyboardEvent->Void}> = [];

	public function new(linkage:String) {
		super();
		graphics.beginFill(0x000000, 0.55);
		graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		graphics.endFill();

		art = new LoginPopupView(linkage);
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
			throw 'Login popup missing TextInput $name';
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

	public function setHtmlText(name:String, value:String):Void {
		var text = FlComponents.asTextField(child(name));
		if (text != null) {
			text.htmlText = value;
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

private class LoginPopupView extends NativeView {
	public function new(linkage:String) {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		if (linkage == "ServerSelectPopupGraphic") buildServerSelect();
		else if (linkage == "ConnectingPopupGraphic") buildConnecting();
		else if (linkage == "LoginPopupGraphic") buildCredentials();
		else throw 'Unsupported native login popup: $linkage';
	}

	private function buildCredentials():Void {
		graphics.drawRoundRect(-155, -112, 310, 224, 14, 14);
		graphics.endFill();
		label("-- Login --", null, -110, -96, 220, 24, 17, true, TextFormatAlign.CENTER);
		label("name:", null, -128, -55, 70, 20, 11, false, TextFormatAlign.RIGHT);
		input("nameBox", -51, -58, 165, false);
		label("password:", null, -128, -22, 70, 20, 11, false, TextFormatAlign.RIGHT);
		input("passBox", -51, -25, 165, true);
		var combo = combo("dropdown", -51, 8, 165);
		combo.rowCount = 6;
		var remember = new FlCheckBox();
		remember.name = "rememberMe_chk";
		remember.label = "Remember me";
		remember.x = -51;
		remember.y = 38;
		addChild(remember);
		button("forgotPass", "Forgot?", -132, 72, 65);
		button("reload_bt", "Reload", -61, 72, 60);
		button("login_bt", "Login", 5, 72, 60);
		button("cancel_bt", "Cancel", 71, 72, 60);
	}

	private function buildServerSelect():Void {
		graphics.drawRoundRect(-160, -105, 320, 210, 14, 14);
		graphics.endFill();
		label("-- Choose Server --", null, -115, -90, 230, 24, 17, true, TextFormatAlign.CENTER);
		label("Account:", null, -130, -50, 70, 18, 11, false, TextFormatAlign.RIGHT);
		combo("userSelect", -53, -53, 166);
		button("user_del_bt", "×", 118, -53, 27);
		label("Server:", null, -130, -15, 70, 18, 11, false, TextFormatAlign.RIGHT);
		combo("serverSelect", -53, -18, 166);
		button("reload_bt", "Reload", 118, -18, 27);
		label("", "textBox", -125, 18, 250, 18, 10, false, TextFormatAlign.CENTER);
		button("login_bt", "Connect", -102, 57, 90);
		button("cancel_bt", "Cancel", 12, 57, 90);
	}

	private function buildConnecting():Void {
		graphics.drawRoundRect(-125, -65, 250, 130, 14, 14);
		graphics.endFill();
		label("Connecting...", null, -95, -45, 190, 23, 16, true, TextFormatAlign.CENTER);
		label("", "textBox", -105, -13, 210, 22, 11, false, TextFormatAlign.CENTER);
		button("var_1", "Cancel", -42, 25, 84);
	}

	private function input(name:String, x:Float, y:Float, width:Float, password:Bool):Void {
		var field = new TextField();
		field.name = name;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = 24;
		field.type = TextFieldType.INPUT;
		field.selectable = true;
		field.displayAsPassword = password;
		field.background = true;
		field.backgroundColor = 0xFFFFFF;
		field.border = true;
		field.borderColor = 0x777777;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 11, 0x222222);
		addChild(field);
	}

	private function combo(name:String, x:Float, y:Float, width:Float):FlComboBox {
		var control = new FlComboBox();
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 22);
		addChild(control);
		return control;
	}

	private function button(name:String, value:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(value));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 24);
		addChild(control);
	}

	private function label(value:String, name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign):Void {
		var field = new TextField();
		if (name != null) field.name = name;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		field.text = value;
		addChild(field);
	}
}
