package pr2.lobby.tabs;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameTextArea;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

/** Exact native composition of XFL `ChatGraphic` (`MovieClips/Symbol 1217`). */
class ChatView extends NativeView {
	public final roomInput:GameTextInput;
	public final chatInputControl:GameTextInput;
	public final transcriptArea:GameTextArea;
	public final roomBox:TextField;
	public final chatInput:TextField;
	public final textBox:TextField;

	public function new() {
		super();
		transcriptArea = ownControl(new GameTextArea(100 * 1.87985229492188, 44 * 6.88603210449219));
		transcriptArea.name = "textArea";
		transcriptArea.x = 0;
		transcriptArea.y = 25;
		transcriptArea.editable = false;
		transcriptArea.wordWrap = true;
		textBox = transcriptArea.textField;
		textBox.name = "textBox";
		addChild(transcriptArea);

		roomInput = ownControl(new GameTextInput());
		roomInput.name = "roomInput";
		roomInput.setSize(100 * 1.0001220703125, 22);
		roomInput.maxChars = 16;
		roomInput.restrict = "^`";
		roomBox = roomInput.textField;
		roomBox.name = "roomBox";
		addChild(roomInput);

		addButton("joinRoom_bt", "Join Room", 103, 0, 100 * 0.660003662109375);
		var info = new InfoButton();
		info.x = 175;
		info.y = 6;
		addChild(info);

		chatInputControl = ownControl(new GameTextInput());
		chatInputControl.name = "chatInputControl";
		chatInputControl.x = 0;
		chatInputControl.y = 331;
		chatInputControl.setSize(100 * 1.45013427734375, 22);
		chatInputControl.maxChars = 150;
		chatInputControl.restrict = "^`";
		chatInput = chatInputControl.textField;
		chatInput.name = "chatInput";
		addChild(chatInputControl);
		addButton("send_bt", "Send", 148, 331, 100 * 0.400009155273438);

		addRule("No swearing.", 0, 356, 65.55);
		addRule("No flooding.", 70, 356, 60.5);
		addRule("Be nice :)", 136, 356, 49.15);
	}

	private function addButton(name:String, label:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 22);
		addChild(control);
	}

	private function addRule(value:String, x:Float, y:Float, width:Float):Void {
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = 12.15;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0x666666);
		field.text = value;
		addChild(field);
	}
}

private class InfoButton extends Sprite {
	public function new() {
		super();
		name = "infoButton";
		buttonMode = useHandCursor = true;
		graphics.beginFill(0xFFFFFF, 0);
		graphics.drawRect(0, 0, 15, 16);
		graphics.endFill();
		var text = new TextField();
		text.x = 2.1;
		text.y = -0.2;
		text.width = 6.1;
		text.height = 10.65;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0x000000);
		text.text = "?";
		addChild(text);
	}
}
