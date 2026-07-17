package pr2.lobby.dialogs;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

/** Native composition of SendMessagePopupGraphic. */
class SendMessageView extends NativeView {
	public final nameInput:GameTextInput;
	public final messageInput:GameTextInput;
	public final charsRemaining:TextField;
	public final codesButton:GameButton;
	public var onSend:Null<Void->Void>;
	public var onCancel:Null<Void->Void>;
	public var onCodes:Null<Void->Void>;

	public function new(name:String, message:String) {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -150;
		panel.y = -145;
		panel.scaleX = 1.1;
		panel.scaleY = 1.5;
		addChild(panel);
		addLabel("-- Send Message --", -110, -131, 220, 18, 14, true, TextFormatAlign.CENTER);
		addLabel("to:", -126, -94, 38, 16, 11, false, TextFormatAlign.RIGHT);
		nameInput = ownControl(new GameTextInput(name));
		nameInput.x = -82;
		nameInput.y = -98;
		nameInput.setSize(190, 22);
		nameInput.textField.name = "nameBox";
		addChild(nameInput);
		addLabel("message:", -126, -59, 68, 16, 11, false, TextFormatAlign.RIGHT);
		messageInput = ownControl(new GameTextInput(message));
		messageInput.x = -52;
		messageInput.y = -63;
		messageInput.setSize(160, 96);
		messageInput.textField.name = "textBox";
		messageInput.textField.multiline = true;
		messageInput.textField.wordWrap = true;
		messageInput.textField.maxChars = 1000;
		addChild(messageInput);

		charsRemaining = addLabel("0 / 1000", 24, 38, 84, 16, 10, false, TextFormatAlign.RIGHT, 0x555555);
		charsRemaining.name = "messageCharsRemaining";
		codesButton = ownControl(new GameButton("Formatting Codes"));
		codesButton.name = "codes_bt";
		codesButton.x = -126;
		codesButton.y = 62;
		codesButton.setSize(112, 22);
		codesButton.onPress = function():Void if (onCodes != null) onCodes();
		addChild(codesButton);
		var send = ownControl(new GameButton("Send"));
		send.name = "send_bt";
		send.x = -4;
		send.y = 62;
		send.setSize(54, 22);
		send.onPress = function():Void if (onSend != null) onSend();
		addChild(send);
		var cancel = ownControl(new GameButton("Cancel"));
		cancel.name = "cancel_bt";
		cancel.x = 56;
		cancel.y = 62;
		cancel.setSize(54, 22);
		cancel.onPress = function():Void if (onCancel != null) onCancel();
		addChild(cancel);
	}

	private function addLabel(value:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign,
		color:Int = 0):TextField {
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, bold, null, null, null, null, align);
		field.text = value;
		addChild(field);
		return field;
	}

	override public function dispose():Void {
		onSend = null;
		onCancel = null;
		onCodes = null;
		super.dispose();
	}
}
