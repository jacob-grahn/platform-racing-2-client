package pr2.mobile;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.runtime.FontResolver;

/** Large, code-drawn PR2-style button used by the mobile lobby shell. */
class MobileButton extends Sprite {
	public var selected(default, set):Bool = false;
	private var labelField:TextField;
	private var buttonWidth:Float;
	private var buttonHeight:Float;
	private var accent:Int;
	private var callback:Void->Void;
	private var pressed:Bool = false;
	private var gameStyle:Bool;

	public function new(label:String, width:Float, height:Float, callback:Void->Void, accent:Int = 0x4D78B7, gameStyle:Bool = false, fontSize:Int = 20) {
		super();
		this.buttonWidth = width;
		this.buttonHeight = height;
		this.callback = callback;
		this.accent = accent;
		this.gameStyle = gameStyle;
		buttonMode = true;
		mouseChildren = false;

		labelField = new TextField();
		labelField.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, Std.int(Math.max(14, Math.min(21, height * 0.34))), 0xFFFFFF, true, false, false,
			null, null, TextFormatAlign.CENTER);
		labelField.width = width;
		labelField.height = height;
		labelField.y = Math.max(1, (height - labelField.textHeight) * 0.5 - 2);
		labelField.selectable = false;
		labelField.mouseEnabled = false;
		labelField.text = label;
		if (gameStyle) {
			labelField.defaultTextFormat = new TextFormat("Lilita One", fontSize, 0x18334B, false, false, false, null, null, TextFormatAlign.CENTER);
			labelField.embedFonts = true;
			labelField.setTextFormat(labelField.defaultTextFormat);
			labelField.y = (height - labelField.textHeight) / 2 - 2;
		}
		addChild(labelField);

		addEventListener(MouseEvent.MOUSE_DOWN, onDown);
		addEventListener(MouseEvent.MOUSE_UP, onUp);
		addEventListener(MouseEvent.MOUSE_OUT, onOut);
		addEventListener(MouseEvent.CLICK, onClick);
		draw();
	}

	public function setLabel(value:String):Void {
		labelField.text = value;
	}

	private function set_selected(value:Bool):Bool {
		selected = value;
		draw();
		return value;
	}

	private function onDown(_:MouseEvent):Void {
		pressed = true;
		draw();
	}

	private function onUp(_:MouseEvent):Void {
		pressed = false;
		draw();
	}

	private function onOut(_:MouseEvent):Void {
		pressed = false;
		draw();
	}

	private function onClick(_:MouseEvent):Void {
		if (callback != null) callback();
	}

	private function draw():Void {
		graphics.clear();
		if (gameStyle) {
			graphics.beginFill(0x0A1F33, 0.4);
			graphics.drawRoundRect(0, 4, buttonWidth, buttonHeight, 20, 20);
			graphics.endFill();
			graphics.lineStyle(3, 0x18334B);
			graphics.beginFill(pressed ? 0xE6F1F8 : accent);
			graphics.drawRoundRect(1.5, pressed ? 3.5 : 1.5, buttonWidth - 3, buttonHeight - 3, 20, 20);
			graphics.endFill();
			return;
		}
		var fill = selected ? accent : 0x35445F;
		if (pressed) fill = selected ? 0x365C91 : 0x29364D;
		graphics.lineStyle(2, selected ? 0xBBD5FF : 0x8292AE, 1);
		graphics.beginFill(fill, 1);
		graphics.drawRoundRect(1, 1, buttonWidth - 2, buttonHeight - 2, 12, 12);
		graphics.endFill();
		graphics.lineStyle(1, 0xFFFFFF, selected ? 0.28 : 0.12);
		graphics.moveTo(8, 4);
		graphics.lineTo(buttonWidth - 8, 4);
	}

	public function remove():Void {
		removeEventListener(MouseEvent.MOUSE_DOWN, onDown);
		removeEventListener(MouseEvent.MOUSE_UP, onUp);
		removeEventListener(MouseEvent.MOUSE_OUT, onOut);
		removeEventListener(MouseEvent.CLICK, onClick);
		callback = null;
		if (parent != null) parent.removeChild(this);
	}
}
