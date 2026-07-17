package pr2.lobby.tabs;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native lobby chat surface with named room, transcript, input, and actions. */
class ChatView extends NativeView {
	public function new() {
		super();
		graphics.beginFill(0xF0F0F0, 0.96);
		graphics.lineStyle(1, 0x777777);
		graphics.drawRoundRect(8, 8, 266, 342, 12, 12);
		graphics.endFill();
		label("Chat Room", null, 20, 18, 75, 18, 11, true, TextFormatAlign.LEFT);
		input("roomBox", 91, 15, 103, 22, false);
		button("joinRoom_bt", "Join", 199, 15, 48);
		var info = new Sprite();
		info.name = "infoButton";
		info.x = 255;
		info.y = 26;
		info.buttonMode = true;
		info.graphics.beginFill(0x5B83B2);
		info.graphics.drawCircle(0, 0, 9);
		info.graphics.endFill();
		var iText = label("i", null, -5, -8, 10, 16, 11, true, TextFormatAlign.CENTER);
		info.addChild(iText);
		addChild(info);
		var transcript = input("textBox", 20, 48, 242, 240, true);
		transcript.type = TextFieldType.DYNAMIC;
		transcript.selectable = true;
		input("chatInput", 20, 301, 181, 26, false);
		button("send_bt", "Send", 207, 301, 55);
	}

	private function input(name:String, x:Float, y:Float, width:Float, height:Float, multiline:Bool):TextField {
		var field = new TextField();
		field.name = name;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.type = TextFieldType.INPUT;
		field.multiline = multiline;
		field.wordWrap = multiline;
		field.background = true;
		field.backgroundColor = 0xFFFFFF;
		field.border = true;
		field.borderColor = 0x888888;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 11, 0x222222);
		addChild(field);
		return field;
	}

	private function button(name:String, label:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 24);
		addChild(control);
	}

	private function label(value:String, name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign):TextField {
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
		return field;
	}
}
