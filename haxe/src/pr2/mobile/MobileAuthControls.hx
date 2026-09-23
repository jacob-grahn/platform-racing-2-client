package pr2.mobile;

import openfl.display.Graphics;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.ui.controls.ControlSkin;
import pr2.ui.controls.ControlState;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameCheckBox;
import pr2.ui.controls.GameSelect;
import pr2.ui.controls.GameTextInput;

class AuthSkin implements ControlSkin {
	private var primary:Bool;
	public function new(primary:Bool = false) this.primary = primary;
	public function draw(g:Graphics, width:Float, height:Float, state:ControlState):Void {
		g.clear();
		g.lineStyle(2, state == Focused ? 0x0B519E : 0x18334B);
		g.beginFill(state == Disabled ? 0xD5E2E9 : state == Pressed ? 0xE6F1F8 : primary || state == Selected ? 0xD1ED62 : 0xFFFFFF);
		g.drawRoundRect(1, 1, width - 2, height - 2, 14, 14); g.endFill();
	}
}

class AuthButton extends GameButton {
	public function new(label:String, primary:Bool = false) super(label, new AuthSkin(primary));
	override private function layoutLabel():Void {
		if (labelField == null) return;
		labelField.text = label;
		var format = new TextFormat("Lilita One", 20, 0x18334B, false, false, false, null, null, TextFormatAlign.CENTER);
		labelField.defaultTextFormat = format; labelField.setTextFormat(format); labelField.embedFonts = true;
		labelField.width = controlWidth - 12; labelField.height = 32;
		labelField.x = 6; labelField.y = (controlHeight - labelField.textHeight) / 2 - 2;
	}
}

class AuthInput extends GameTextInput {
	public function new(value:String = "") { super(value, new AuthSkin()); textField.embedFonts = true; }
	override private function textFormatForState():TextFormat return new TextFormat("Nunito Bold", 18, 0x18334B);
	override private function layoutField():Void {
		if (textField == null) return;
		textField.x = 12; textField.y = 9; textField.width = controlWidth - 24; textField.height = controlHeight - 10;
	}
}

class AuthCheckBox extends GameCheckBox {
	public function new() super("Remember me", false, new AuthSkin());
	override private function layoutLabel():Void {
		if (labelField == null) return;
		var format = new TextFormat("Nunito Bold", 17, 0x18334B);
		labelField.defaultTextFormat = format; labelField.setTextFormat(format); labelField.embedFonts = true;
		labelField.x = 38; labelField.y = (controlHeight - labelField.textHeight) / 2 - 2;
	}
	override public function redraw():Void {
		super.redraw();
		graphics.lineStyle(2, 0x18334B); graphics.beginFill(selected ? 0x18334B : 0xFFFFFF);
		graphics.drawRoundRect(12, (controlHeight - 18) / 2, 18, 18, 4, 4); graphics.endFill();
	}
}

/** Reuses the selection model/keyboard behavior, replacing the small dropdown. */
class AuthSelect extends GameSelect<Dynamic> {
	public var onPick:AuthSelect->Void;
	public var onDismissPicker:AuthSelect->Void;
	public function new() super(new AuthSkin());
	override public function activate():Void {
		if (enabled && !disposed && length > 0 && onPick != null) onPick(this);
	}
	override public function close():Void {
		if (onDismissPicker != null) onDismissPicker(this);
		super.close();
	}
	override private function layoutLabel():Void {
		if (labelField == null) return;
		var format = new TextFormat("Nunito Bold", 16, enabled ? 0x18334B : 0x50687A);
		labelField.defaultTextFormat = format; labelField.setTextFormat(format); labelField.embedFonts = true;
		labelField.x = 12; labelField.width = controlWidth - 38; labelField.height = 32;
		labelField.y = (controlHeight - labelField.textHeight) / 2 - 2;
	}
	override public function redraw():Void {
		super.redraw();
		graphics.lineStyle(2, 0x18334B); graphics.moveTo(controlWidth - 24, controlHeight / 2 - 3);
		graphics.lineTo(controlWidth - 18, controlHeight / 2 + 3); graphics.lineTo(controlWidth - 12, controlHeight / 2 - 3);
	}
}
