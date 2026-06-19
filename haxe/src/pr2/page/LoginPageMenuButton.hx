package pr2.page;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.runtime.FontResolver;

class LoginPageMenuButton extends Sprite {
	private static inline var HIT_WIDTH:Float = 116;
	private static inline var HIT_HEIGHT:Float = 20;

	private var label:String;
	private var clickHandler:Void->Void;
	private var frontText:TextField;
	private var shadowText:TextField;

	public function new(label:String, clickHandler:Void->Void) {
		super();
		this.label = label;
		this.clickHandler = clickHandler;

		buttonMode = true;
		useHandCursor = true;
		mouseChildren = false;
		alpha = 0.75;
		drawHitArea();

		shadowText = buildTextField(0xFFFFFF);
		shadowText.x = -HIT_WIDTH / 2 + 1;
		shadowText.y = 1;
		addChild(shadowText);

		frontText = buildTextField(0x333333);
		frontText.x = -HIT_WIDTH / 2;
		addChild(frontText);
		setLabel(label);

		addEventListener(MouseEvent.MOUSE_OVER, onOver);
		addEventListener(MouseEvent.MOUSE_OUT, onOut);
		addEventListener(MouseEvent.CLICK, onClick);
	}

	public function remove():Void {
		removeEventListener(MouseEvent.MOUSE_OVER, onOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onOut);
		removeEventListener(MouseEvent.CLICK, onClick);
	}

	private function buildTextField(color:Int):TextField {
		var text = new TextField();
		text.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, 12, color, false, false, false, null, null, CENTER);
		text.selectable = false;
		text.mouseEnabled = false;
		text.autoSize = TextFieldAutoSize.NONE;
		text.width = HIT_WIDTH;
		text.height = HIT_HEIGHT;
		return text;
	}

	private function setLabel(value:String):Void {
		frontText.text = value;
		shadowText.text = value;
	}

	private function drawHitArea():Void {
		graphics.beginFill(0xFFFFFF, 0);
		graphics.drawRect(-HIT_WIDTH / 2, 0, HIT_WIDTH, HIT_HEIGHT);
		graphics.endFill();
	}

	private function onOver(_:MouseEvent):Void {
		alpha = 1;
		setLabel("- " + label + " -");
	}

	private function onOut(_:MouseEvent):Void {
		alpha = 0.75;
		setLabel(label);
	}

	private function onClick(_:MouseEvent):Void {
		clickHandler();
	}
}
