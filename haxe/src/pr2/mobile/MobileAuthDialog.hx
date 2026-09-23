package pr2.mobile;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.page.auth.AuthDialog;
import pr2.mobile.MobileAuthControls.AuthButton;
import pr2.mobile.MobileAuthControls.AuthInput;
import pr2.mobile.MobileAuthControls.AuthCheckBox;
import pr2.mobile.MobileAuthControls.AuthSelect;
import pr2.ui.controls.NativeControl;

/** Full-viewport modal with unscaled touch targets and a separate choice picker. */
class MobileAuthDialog extends AuthDialog {
	private var panel = new Sprite();
	private var controls:Array<NativeControl> = [];
	private var labels:Map<String, TextField> = [];
	private var inputs:Map<String, AuthInput> = [];
	private var message:TextField;
	private var viewportW:Float = 844;
	private var viewportH:Float = 390;
	private var panelW:Float = 720;
	private var panelH:Float = 340;
	private var dragY:Null<Float>;
	private var dragPanelY:Float;
	private var ownerStage:openfl.display.Stage;
	private var picker:Sprite;
	private var pickerControls:Array<AuthButton> = [];
	private var picking:AuthSelect;
	private var pickerOffset:Int = 0;
	private var disposed:Bool = false;
	#if js
	private var visualViewport:Dynamic;
	private var viewportListener:Dynamic;
	#end

	public function new(kind:String, initialMessage:String, values:Map<String, String>) {
		super(kind);
		name = "mobileAuth_" + kind;
		addChild(panel);
		label("heading", switch kind {
			case "LoginPopupGraphic": "Log in";
			case "ServerSelectPopupGraphic": "Choose your race server";
			case "Register": "Create your racer";
			case "Recover": "Recover your password";
			case "Confirm": values.exists("heading") ? values.get("heading") : "Remove saved account?";
			case "Message": "Heads up!";
			default: "Getting you ready...";
		}, 28, true);
		message = label("message", initialMessage, 16);
		switch kind {
			case "LoginPopupGraphic":
				field("nameBox", "Racer name", ""); field("passBox", "Password", "", true);
				choice("dropdown", "Server");
				var check = new AuthCheckBox(); addControl("rememberMe_chk", check);
				button("forgotPass", "Forgot password?"); button("reload_bt", "Reload");
				button("login_bt", "LOG IN", true); button("cancel_bt", "Back");
			case "ServerSelectPopupGraphic":
				choice("userSelect", "Account"); choice("serverSelect", "Server");
				button("user_del_bt", "Remove saved account"); button("reload_bt", "Reload servers");
				button("login_bt", "LET'S GO", true); button("cancel_bt", "Back");
			case "Register":
				field("nameBox", "Racer name (up to 20 characters)", values.get("nameBox"));
				field("passBox1", "Password", values.get("passBox1"), true);
				field("passBox2", "Confirm password", values.get("passBox2"), true);
				field("emailBox", "Email (optional)", values.get("emailBox"));
				message.text = "Your email is only used to recover a forgotten password.";
				button("submit", "CREATE ACCOUNT", true, function():Void if (onSubmit != null) onSubmit());
				button("cancel", "Back", false, function():Void if (onCancel != null) onCancel());
			case "Recover":
				field("nameBox", "Racer name", values.get("nameBox")); field("emailBox", "Email", "");
				message.text = "Enter the email you used when registering. A new password will be sent there. If you did not add an email, this recovery method is unavailable.";
				button("submit", "SEND PASSWORD", true, function():Void if (onSubmit != null) onSubmit());
				button("cancel", "Back", false, function():Void if (onCancel != null) onCancel());
			case "Confirm":
				button("submit", values.exists("confirmLabel") ? values.get("confirmLabel") : "REMOVE", true, function():Void if (onConfirm != null) onConfirm());
				button("cancel", values.exists("cancelLabel") ? values.get("cancelLabel") : "Keep account", false, function():Void if (onCancel != null) onCancel());
			case "Message":
				button("submit", "OK", true, function():Void if (onClose != null) onClose());
			case "ConnectingPopupGraphic": button("var_1", "Cancel");
			default: button("cancel", "Cancel", false, function():Void if (onClose != null) onClose());
		}
		for (key in inputs.keys()) {
			if (kind == "Register" || kind == "Recover") bindEnter(key, function():Void if (onSubmit != null) onSubmit());
		}
		addEventListener(Event.ADDED_TO_STAGE, added);
		addEventListener(FocusEvent.FOCUS_IN, focused);
		addEventListener(MouseEvent.MOUSE_WHEEL, wheel);
		panel.addEventListener(MouseEvent.MOUSE_DOWN, beginDrag);
		resizeViewport(844, 390);
	}

	private function label(key:String, value:String, size:Int, heading:Bool = false):TextField {
		var text = new TextField(); text.name = key;
		text.defaultTextFormat = new TextFormat(heading ? "Lilita One" : "Nunito Bold", size, 0x18334B);
		text.embedFonts = true; text.text = value; text.selectable = false; text.mouseEnabled = false;
		text.multiline = text.wordWrap = true; panel.addChild(text); labels.set(key, text); return text;
	}
	private function addControl(key:String, control:NativeControl):Void {
		control.name = key; named.set(key, control); controls.push(control); panel.addChild(control);
	}
	private function field(key:String, caption:String, value:String, password:Bool = false):Void {
		label(key + "Label", caption, 15);
		var input = new AuthInput(value == null ? "" : value);
		input.displayAsPassword = password;
		if (key == "nameBox") input.maxChars = 20;
		addControl(key + "Control", input); inputs.set(key, input);
		input.textField.name = key; named.set(key, input.textField);
	}
	private function choice(key:String, caption:String):Void {
		label(key + "Label", caption, 15);
		var select = new AuthSelect(); addControl(key, select);
		select.onPick = openPicker;
		select.onDismissPicker = function(value):Void if (picking == value) closePicker();
	}
	private function button(key:String, caption:String, primary:Bool = false, ?action:Void->Void):Void {
		var view = new AuthButton(caption, primary); addControl(key, view); view.onPress = action;
	}
	private function place(key:String, x:Float, y:Float, width:Float, height:Float):Void {
		var node:DisplayObject = labels.exists(key) ? labels.get(key) : child(key);
		if (node == null) return;
		node.x = x; node.y = y;
		var control = Std.downcast(node, NativeControl);
		if (control != null) control.setSize(width, height); else { node.width = width; node.height = height; }
	}
	private function placeField(key:String, x:Float, y:Float, width:Float):Void {
		place(key + "Label", x, y, width, 24);
		place(inputs.exists(key) ? key + "Control" : key, x, y + 24, width, 46);
	}

	override public function resizeViewport(width:Float, height:Float):Void {
		viewportW = width; viewportH = height;
		#if js
		if (visualViewport != null) viewportH = Math.min(height, visualViewport.height);
		#end
		closePicker();
		graphics.clear(); graphics.beginFill(0x081A2B, 0.78); graphics.drawRect(0, 0, width, height); graphics.endFill();
		panelW = Math.min(720, Math.max(280, width - 24));
		var narrow = panelW < 560;
		var col = narrow ? panelW - 40 : (panelW - 60) / 2;
		var right = narrow ? 20 : col + 40;
		var extra = narrow ? 164 : 0;
		place("heading", 20, 12, panelW - 40, 40);
		var footer:Float = 280 + extra;
		switch kind {
			case "LoginPopupGraphic":
				placeField("nameBox", 20, 64, col); placeField("passBox", 20, 146, col);
				placeField("dropdown", right, 64 + extra, col);
				place("rememberMe_chk", right, 152 + extra, col - 110, 46);
				place("reload_bt", right + col - 100, 152 + extra, 100, 46);
				place("forgotPass", 20, narrow ? 438 : 222, col, 44);
				place("message", right, 206 + extra, col, 66);
				if (narrow) footer = 494;
			case "Register":
				placeField("nameBox", 20, 64, col); placeField("passBox1", 20, 146, col);
				placeField("passBox2", right, 64 + extra, col); placeField("emailBox", right, 146 + extra, col);
				place("message", 20, 228 + extra, panelW - 40, 44);
			case "Recover":
				placeField("nameBox", 20, 64, col); placeField("emailBox", right, narrow ? 146 : 64, col);
				place("message", 20, narrow ? 234 : 152, panelW - 40, 104);
				footer = narrow ? 350 : 280;
			case "ServerSelectPopupGraphic":
				placeField("userSelect", 20, 64, col); placeField("serverSelect", right, 64 + extra, col);
				place("user_del_bt", 20, 152, col, 46); place("reload_bt", right, 152 + extra, col, 46);
				place("message", 20, 216 + extra, panelW - 40, 56);
			default:
				place("message", 24, 78, panelW - 48, 170);
				var messageHeight = Math.max(130, message.textHeight + 8);
				message.height = messageHeight;
				footer = Math.max(250, 94 + messageHeight);
		}
		place("login_bt", panelW - 240, footer, 220, 48); place("cancel_bt", 20, footer, 180, 48);
		place("submit", panelW - 240, footer, 220, 48); place("cancel", 20, footer, 180, 48);
		place("var_1", (panelW - 200) / 2, footer, 200, 48);
		if (narrow) {
			for (key in ["login_bt", "submit"]) place(key, 20, footer, panelW - 40, 48);
			for (key in ["cancel_bt", "cancel"]) place(key, 20, footer + 60, panelW - 40, 48);
			footer += 60;
		}
		panelH = footer + 64;
		panel.graphics.clear(); panel.graphics.lineStyle(3, 0x18334B); panel.graphics.beginFill(0xF3F8FA);
		panel.graphics.drawRoundRect(0, 0, panelW, panelH, 24, 24); panel.graphics.endFill();
		panel.x = (viewportW - panelW) / 2; panel.y = Math.max(12, (viewportH - panelH) / 2);
		scrollRect = new Rectangle(0, 0, viewportW, viewportH);
		if (ownerStage != null && ownerStage.focus != null) reveal(ownerStage.focus);
	}
	override public function setMessage(value:String):Void { message.text = value; resizeViewport(viewportW, viewportH); }

	private function added(_:Event):Void {
		ownerStage = stage;
		ownerStage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown, true, 2000);
		ownerStage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown, false, 2000);
		ownerStage.addEventListener(MouseEvent.MOUSE_MOVE, drag);
		ownerStage.addEventListener(MouseEvent.MOUSE_UP, endDrag);
		#if js
		visualViewport = untyped js.Browser.window.visualViewport;
		if (visualViewport != null) {
			viewportListener = function(_):Void resizeViewport(ownerStage.stageWidth, ownerStage.stageHeight);
			visualViewport.addEventListener("resize", viewportListener);
		}
		#end
	}
	private function focused(e:FocusEvent):Void reveal(cast e.target);
	private function reveal(target:DisplayObject):Void {
		if (target == null || !panel.contains(target)) return;
		var bounds = target.getBounds(panel);
		if (panel.y + bounds.bottom > viewportH - 12) panel.y = viewportH - 12 - bounds.bottom;
		if (panel.y + bounds.top < 12) panel.y = 12 - bounds.top;
		clampScroll();
	}
	private function clampScroll():Void {
		if (panelH <= viewportH - 24) panel.y = (viewportH - panelH) / 2;
		else panel.y = Math.min(12, Math.max(viewportH - panelH - 12, panel.y));
	}
	private function beginDrag(e:MouseEvent):Void {
		if (e.target != panel || panelH <= viewportH - 24) return;
		dragY = e.stageY; dragPanelY = panel.y;
	}
	private function drag(e:MouseEvent):Void { if (dragY != null) { panel.y = dragPanelY + e.stageY - dragY; clampScroll(); } }
	private function endDrag(_:MouseEvent):Void dragY = null;
	private function wheel(e:MouseEvent):Void { if (panelH > viewportH - 24) { panel.y += e.delta * 28; clampScroll(); } }
	private function keyDown(e:KeyboardEvent):Void {
		if (e.isDefaultPrevented() || parent == null || parent.getChildIndex(this) != parent.numChildren - 1) return;
		if (e.keyCode == 9) {
			var candidates:Array<NativeControl> = picker == null ? controls.filter(function(c) return c.enabled) : [for (c in pickerControls) if (c.enabled) c];
			var index = -1;
			for (i in 0...candidates.length) if (ownerStage.focus != null && (candidates[i] == ownerStage.focus || candidates[i].contains(ownerStage.focus))) index = i;
			if (candidates.length > 0) {
				index = index < 0 ? (e.shiftKey ? candidates.length - 1 : 0) : (index + (e.shiftKey ? -1 : 1) + candidates.length) % candidates.length;
				NativeControl.showFocusIndicator = true;
				candidates[index].focus();
			}
			e.preventDefault(); e.stopImmediatePropagation(); return;
		}
		if (e.keyCode != 27) return;
		e.preventDefault(); e.stopImmediatePropagation();
		if (picker != null) { closePicker(); return; }
		if (onCancel != null) onCancel(); else if (onClose != null) onClose();
	}

	private function openPicker(select:AuthSelect):Void {
		closePicker(); picking = select; pickerOffset = 0; renderPicker();
	}
	private function renderPicker():Void {
		clearPickerArt();
		picker = new Sprite(); picker.name = "authChoicePicker"; addChild(picker);
		picker.graphics.beginFill(0x081A2B, 0.98); picker.graphics.drawRect(0, 0, viewportW, viewportH); picker.graphics.endFill();
		var w = Math.min(680, viewportW - 32), x = (viewportW - w) / 2;
		var rows = Std.int(Math.max(1, Math.floor((viewportH - 92) / 54)));
		var count = picking.length;
		pickerOffset = Std.int(Math.max(0, Math.min(pickerOffset, Math.max(0, count - 1))));
		for (i in pickerOffset...Std.int(Math.min(count, pickerOffset + rows))) {
			var index = i;
			var item = picking.itemAt(i);
			pickerButton(Std.string(Reflect.field(item, "label")), x, 12 + (i - pickerOffset) * 54, w, function():Void {
				var select = picking; closePicker(); select.selectFromUser(index);
			}, i == picking.selectedIndex);
		}
		var y = viewportH - 60;
		var previous = pickerButton("Previous", x, y, (w - 24) / 3, function():Void { pickerOffset = Std.int(Math.max(0, pickerOffset - rows)); renderPicker(); });
		previous.enabled = pickerOffset > 0;
		pickerButton("Back", x + (w + 12) / 3, y, (w - 24) / 3, closePicker);
		var next = pickerButton("Next", x + (w + 12) * 2 / 3, y, (w - 24) / 3, function():Void { pickerOffset += rows; renderPicker(); });
		next.enabled = pickerOffset + rows < count;
	}
	private function pickerButton(label:String, x:Float, y:Float, w:Float, action:Void->Void, selected:Bool = false):AuthButton {
		var button = new AuthButton(label, selected); button.x = x; button.y = y; button.setSize(w, 46);
		button.onPress = action; picker.addChild(button); pickerControls.push(button); return button;
	}
	private function clearPickerArt():Void {
		for (button in pickerControls) button.dispose(); pickerControls = [];
		if (picker != null && picker.parent != null) picker.parent.removeChild(picker); picker = null;
	}
	private function closePicker():Void { clearPickerArt(); picking = null; }
	override public function dismiss(immediate:Bool = false):Void {
		if (disposed) return; disposed = true;
		closePicker();
		if (ownerStage != null) {
			ownerStage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown, true);
			ownerStage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown, false);
			ownerStage.removeEventListener(MouseEvent.MOUSE_MOVE, drag); ownerStage.removeEventListener(MouseEvent.MOUSE_UP, endDrag);
			if (ownerStage.focus != null && contains(ownerStage.focus)) ownerStage.focus = null;
		}
		#if js
		if (visualViewport != null && viewportListener != null) visualViewport.removeEventListener("resize", viewportListener);
		#end
		removeEventListener(Event.ADDED_TO_STAGE, added); removeEventListener(FocusEvent.FOCUS_IN, focused);
		removeEventListener(MouseEvent.MOUSE_WHEEL, wheel);
		panel.removeEventListener(MouseEvent.MOUSE_DOWN, beginDrag);
		for (control in controls) control.dispose(); controls = [];
		for (input in inputs) input.text = "";
		super.dismiss(true);
	}
}
