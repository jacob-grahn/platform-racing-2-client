package pr2.page;

import openfl.display.DisplayObject;
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
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameCheckBox;
import pr2.ui.controls.GameSelect;
import pr2.ui.controls.GameTextInput;
import pr2.ui.controls.NativeControl;
import pr2.ui.view.NativeView;
import pr2.runtime.SvgAsset;

class LoginFlashPopup extends Sprite {
	public static inline var LOADED:String = "loaded";
	public static inline var REMOVED:String = "removed";
	public var fadeOutStarted(default, null):Bool = false;
	private var art:LoginPopupView;
	private var buttonHandlers:Array<{target:DisplayObject, handler:MouseEvent->Void}> = [];
	private var comboHandlers:Array<{target:GameSelect<Dynamic>, handler:Event->Void}> = [];
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
		alpha = 0;
		addEventListener(Event.ENTER_FRAME, fadeIn);
	}

	private function fadeIn(_:Event):Void {
		alpha += 0.15;
		if (alpha >= 1) {
			alpha = 1;
			removeEventListener(Event.ENTER_FRAME, fadeIn);
			dispatchEvent(new Event(LOADED));
		}
	}

	public function startFadeOut():Void {
		if (fadeOutStarted) return;
		fadeOutStarted = true;
		removeEventListener(Event.ENTER_FRAME, fadeIn);
		addEventListener(Event.ENTER_FRAME, fadeOut);
	}

	private function fadeOut(_:Event):Void {
		alpha -= 0.15;
		if (alpha <= 0) {
			remove();
			dispatchEvent(new Event(REMOVED));
		}
	}

	public function child(name:String):Null<DisplayObject> {
		return art.child(name);
	}

	public function input(name:String):TextField {
		var field = Std.downcast(child(name), TextField);
		if (field == null) {
			throw 'Login popup missing TextInput $name';
		}
		return field;
	}

	public function comboBox(name:String):Null<GameSelect<Dynamic>> {
		return Std.downcast(child(name), GameSelect);
	}

	public function checkBox(name:String):Null<GameCheckBox> {
		return Std.downcast(child(name), GameCheckBox);
	}

	public function bindComboBox(name:String, changeHandler:GameSelect<Dynamic>->Void):Void {
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
		var button = Std.downcast(child(name), GameButton);
		if (button != null) {
			button.label = value;
			return;
		}
		var select = Std.downcast(child(name), GameSelect);
		if (select != null) select.prompt = value;
	}

	public function setText(name:String, value:String):Void {
		var text = Std.downcast(child(name), TextField);
		if (text != null) {
			text.text = value;
		}
	}

	public function setHtmlText(name:String, value:String):Void {
		var text = Std.downcast(child(name), TextField);
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
		removeEventListener(Event.ENTER_FRAME, fadeIn);
		removeEventListener(Event.ENTER_FRAME, fadeOut);
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
		if (parent != null) parent.removeChild(this);
	}

}

private class LoginPopupView extends NativeView {
	private final named:Map<String, DisplayObject> = [];

	public function child(name:String):Null<DisplayObject> return named.get(name);

	public function new(linkage:String) {
		super();
		if (linkage == "ServerSelectPopupGraphic") buildServerSelect();
		else if (linkage == "ConnectingPopupGraphic") buildConnecting();
		else if (linkage == "LoginPopupGraphic") buildCredentials();
		else throw 'Unsupported native login popup: $linkage';
	}

	private function buildCredentials():Void {
		var background = NativeAssets.svg(StaticSvg.QuantityPanel);
		background.x = -111;
		background.y = -121.5;
		background.scaleX = 0.8162841796875;
		background.scaleY = 1.27224731445312;
		addChild(background);
		label("-- Login --", null, -43, -109.45, 86, 17.05, 14, true, TextFormatAlign.CENTER);
		label("name:", null, -74.3, -74.25, 39.1, 14.55, 12, false, TextFormatAlign.LEFT);
		input("nameBox", -31, -76.2, 110.000610351562, false, 20);
		label("pass:", null, -68.3, -46.25, 32.5, 14.55, 12, false, TextFormatAlign.LEFT);
		input("passBox", -31, -48.2, 110.000610351562, true);
		forgotPasswordLink();
		var remember = ownControl(new GameCheckBox("Remember Me", false));
		remember.name = "rememberMe_chk";
		remember.x = -17;
		remember.y = 0.15;
		remember.setSize(108.000183105469, 22);
		addChild(remember);
		named.set(remember.name, remember);
		label("server:", null, -98, 43.8, 43.2, 14.55, 12, false, TextFormatAlign.LEFT);
		combo("dropdown", -51, 39.8, 130.998229980469);
		reloadButton();
		button("login_bt", "Log In", -80, 87.8, 74.0005493164062, 22);
		button("cancel_bt", "Cancel", 7, 87.8, 74.0005493164062, 22);
	}

	private function buildServerSelect():Void {
		var background = NativeAssets.svg(StaticSvg.QuantityPanel);
		background.x = -118;
		background.y = -75;
		background.scaleX = 0.867523193359375;
		background.scaleY = 0.785446166992188;
		addChild(background);
		label("-- Login --", null, -43, -64.15, 86, 17.05, 14, true, TextFormatAlign.CENTER);
		label("user:", null, -97.95, -27.7, 31.6, 14.55, 12, false, TextFormatAlign.RIGHT);
		var users = combo("userSelect", -50, -31.7, 131.001281738281);
		users.prompt = "Guest";
		users.enabled = false;
		iconButton("user_del_bt", LoginIconKind.Minus, 99, -20.2);
		label("server:", null, -97.95, 4, 43.2, 14.55, 12, false, TextFormatAlign.LEFT);
		var servers = combo("serverSelect", -50, 0, 131.001281738281);
		servers.prompt = "Loading...";
		servers.enabled = false;
		reloadButtonAt(99, 11.5, "reload_bt");
		button("login_bt", "Log In", -80, 40, 74.0005493164062, 22);
		button("cancel_bt", "Cancel", 7, 40, 74.0005493164062, 22);
	}

	private function buildConnecting():Void {
		var background = NativeAssets.svg(StaticSvg.QuantityPanel);
		background.x = -81;
		background.y = -48;
		background.scaleX = 0.604461669921875;
		background.scaleY = 0.505264282226562;
		addChild(background);
		label("Connecting...", null, -37, -28.2, 79.6, 14.55, 12, false, TextFormatAlign.LEFT);
		button("var_1", "Close", -48, 10, 100, 22);
	}

	private function input(name:String, x:Float, y:Float, width:Float, password:Bool, maxChars:Int = 0):Void {
		var control = ownControl(new GameTextInput());
		control.name = name + "_control";
		control.x = x;
		control.y = y;
		control.setSize(width, 22);
		control.maxChars = maxChars;
		control.displayAsPassword = password;
		control.textField.name = name;
		addChild(control);
		named.set(name, control.textField);
	}

	private function combo(name:String, x:Float, y:Float, width:Float):GameSelect<Dynamic> {
		var control = ownControl(new GameSelect<Dynamic>());
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 22);
		addChild(control);
		named.set(name, control);
		return control;
	}

	private function button(name:String, value:String, x:Float, y:Float, width:Float, height:Float = 24):Void {
		var control = ownControl(new GameButton(value));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, height);
		addChild(control);
		named.set(name, control);
	}

	private function forgotPasswordLink():Void {
		var control = new Sprite();
		control.name = "forgotPass";
		control.x = -34;
		control.y = -24.25;
		control.buttonMode = true;
		control.useHandCursor = true;
		var field = new TextField();
		field.mouseEnabled = false;
		field.selectable = false;
		field.x = 1.964111328125;
		field.y = 1.964111328125;
		field.width = 111.069;
		field.height = 13;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0x4E4EFE);
		field.text = "Forget your password?";
		control.addChild(field);
		addChild(control);
		named.set(control.name, control);
	}

	private function reloadButton():Void {
		reloadButtonAt(94.85, 50.85, "reload_bt");
	}

	private function reloadButtonAt(x:Float, y:Float, name:String):Void {
		iconButton(name, LoginIconKind.Reload, x, y);
	}

	private function iconButton(name:String, kind:LoginIconKind, x:Float, y:Float):Void {
		var control = ownControl(new LoginIconButton(kind));
		control.name = name;
		control.x = x;
		control.y = y;
		addChild(control);
		named.set(name, control);
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
		if (name != null) named.set(name, field);
	}
}

private enum abstract LoginIconKind(Int) {
	var Reload = 0;
	var Minus = 1;
}

private class LoginIconButton extends NativeControl {
	private var kind:Null<LoginIconKind>;

	public function new(kind:LoginIconKind) {
		super(18, 18);
		this.kind = kind;
		mouseChildren = false;
		redraw();
	}

	override public function redraw():Void {
		graphics.clear();
		while (numChildren > 0) removeChildAt(0);
		if (kind == null) return;
		addChild(NativeAssets.svg(authoredAsset()));
	}

	private function authoredAsset():StaticSvg {
		var down = state() == Pressed;
		var over = state() == Hovered || state() == Focused;
		return switch (kind) {
			case Reload: down ? StaticSvg.ReloadButtonDown : over ? StaticSvg.ReloadButtonOver : StaticSvg.ReloadButtonUp;
			case Minus: down ? StaticSvg.MinusButtonDown : over ? StaticSvg.MinusButtonOver : StaticSvg.MinusButtonUp;
		}
	}
}
