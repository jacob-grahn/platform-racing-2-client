package pr2.mobile;

import openfl.display.Sprite;
import openfl.display.Graphics;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.mobile.MobileAuthControls.AuthButton;
import pr2.ui.controls.ControlSkin;
import pr2.ui.controls.ControlState;
import pr2.ui.controls.NativeControl;

/** Shared presentation primitives for landscape lobby surfaces. */
class LobbyView extends Sprite {
	public var controls:Array<NativeControl> = [];
	public function new() super();
	public function panel(x:Float, y:Float, w:Float, h:Float):Void {
		graphics.lineStyle(); graphics.beginFill(0x0A1F33, .4);
		graphics.drawRoundRect(x, y + 4, w, h, 20, 20); graphics.endFill();
		graphics.lineStyle(3, 0x18334B); graphics.beginFill(0xF3F8FA);
		graphics.drawRoundRect(x + 1.5, y + 1.5, w - 3, h - 3, 20, 20); graphics.endFill();
	}
	public function label(value:String, x:Float, y:Float, w:Float, h:Float, size:Int = 16, heading:Bool = false, color:Int = 0x18334B):TextField {
		var text = new TextField();
		text.defaultTextFormat = new TextFormat(heading ? "Lilita One" : "Nunito Bold", size, color);
		text.embedFonts = true; text.selectable = false; text.mouseEnabled = false;
		text.x = x; text.y = y; text.width = w; text.height = h;
		text.multiline = true; text.wordWrap = true; text.text = value;
		addChild(text); return text;
	}
	public function button(value:String, x:Float, y:Float, w:Float, action:Void->Void, primary:Bool = false, h:Float = 44):AuthButton {
		var b = new LobbyActionButton(value, primary); b.skin = new LobbyButtonSkin(primary);
		b.name = value; b.x = x; b.y = y; b.setSize(w, h); b.onPress = action;
		controls.push(b); addChild(b); return b;
	}
	public function singleLine(value:String, x:Float, y:Float, w:Float, h:Float, size:Int = 16, heading:Bool = false, color:Int = 0x18334B):TextField {
		var text = label(value, x, y, w, h, size, heading, color);
		text.wordWrap = false; text.multiline = false;
		var remaining = value;
		while (text.textWidth > w - 4 && remaining.length > 0) {
			remaining = remaining.substr(0, remaining.length - 1); text.text = remaining + "…";
		}
		return text;
	}
	public function own<T:NativeControl>(control:T):T { controls.push(control); addChild(control); return control; }
	public function clear():Void {
		for (c in controls) c.dispose(); controls = [];
		while (numChildren > 0) removeChildAt(0); graphics.clear();
	}
	public function remove():Void { clear(); if (parent != null) parent.removeChild(this); }
}

private class LobbyActionButton extends AuthButton {
	public function new(label:String, primary:Bool) super(label, primary);
	override private function layoutLabel():Void {
		super.layoutLabel();
		if (labelField == null) return;
		var size = 20;
		while (labelField.textWidth > controlWidth - 14 && size > 14) {
			var f = labelField.defaultTextFormat; f.size = --size;
			labelField.defaultTextFormat = f; labelField.setTextFormat(f);
		}
		labelField.y = (controlHeight - labelField.textHeight) / 2 - 2;
	}
}

private class LobbyButtonSkin implements ControlSkin {
	private var primary:Bool;
	public function new(primary:Bool) this.primary = primary;
	public function draw(g:Graphics, w:Float, h:Float, state:ControlState):Void {
		g.clear(); g.lineStyle(); g.beginFill(0x0A1F33, .35);
		g.drawRoundRect(0, 4, w, h, 20, 20); g.endFill();
		g.lineStyle(3, state == Focused ? 0x0B519E : 0x18334B);
		g.beginFill(state == Disabled ? 0xD5E2E9 : state == Pressed ? 0xE6F1F8 : primary || state == Selected ? 0xD1ED62 : 0xFFFFFF);
		g.drawRoundRect(1.5, state == Pressed ? 3.5 : 1.5, w - 3, h - 3, 20, 20); g.endFill();
	}
}
