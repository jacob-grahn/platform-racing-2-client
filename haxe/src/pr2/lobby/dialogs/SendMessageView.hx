package pr2.lobby.dialogs;

import openfl.text.TextField;
import openfl.display.DisplayObject;
import openfl.display.Graphics;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameTextInput;
import pr2.ui.controls.GameTextArea;
import pr2.ui.controls.ControlSkin;
import pr2.ui.controls.ControlState;
import pr2.ui.view.NativeView;

/** Native composition of SendMessagePopupGraphic. */
class SendMessageView extends NativeView {
	public final nameInput:GameTextInput;
	public final messageInput:GameTextArea;
	public final charsRemaining:TextField;
	public final codesButton:GameButton;
	public final panel:DisplayObject;
	public final warning:TextField;
	public final toLabel:TextField;
	public final sendButton:GameButton;
	public final cancelButton:GameButton;
	public var onSend:Null<Void->Void>;
	public var onCancel:Null<Void->Void>;
	public var onCodes:Null<Void->Void>;

	public function new(name:String, message:String) {
		super();
		panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -166.5;
		panel.y = -109.9;
		panel.scaleX = 1.2242431640625;
		panel.scaleY = 1.0732421875;
		addChild(panel);
		toLabel = addLabel("To:", -72, -97.25, 18.95, 14.55, 12, false, TextFormatAlign.LEFT);
		nameInput = ownControl(new GameTextInput(name));
		nameInput.x = -44;
		nameInput.y = -100;
		nameInput.setSize(197.996520996094, 22);
		nameInput.textField.name = "nameBox";
		addChild(nameInput);
		messageInput = ownControl(new GameTextArea(309.109497070313, 50.0082397460936));
		messageInput.text = message;
		messageInput.x = -155;
		messageInput.y = -68;
		messageInput.textField.name = "textBox";
		messageInput.maxChars = 1000;
		messageInput.wordWrap = true;
		addChild(messageInput);

		warning = addLabel("NEVER give your password to ANYONE.", -152.25, 39, 197.2, 12.15, 10, false, TextFormatAlign.LEFT);
		charsRemaining = addLabel("1000 / 1000", 85.55, 39.5, 65.5, 12.75, 10, false, TextFormatAlign.RIGHT);
		charsRemaining.name = "messageCharsRemaining";
		codesButton = ownControl(new SendMessageInfoButton());
		codesButton.name = "codes_bt";
		codesButton.x = -154.25;
		codesButton.y = 66.45;
		codesButton.onPress = function():Void if (onCodes != null) onCodes();
		addChild(codesButton);
		sendButton = ownControl(new GameButton("Send"));
		sendButton.name = "send_bt";
		sendButton.x = -115;
		sendButton.y = 60;
		sendButton.setSize(100, 22);
		sendButton.onPress = function():Void if (onSend != null) onSend();
		addChild(sendButton);
		cancelButton = ownControl(new GameButton("Cancel"));
		cancelButton.name = "cancel_bt";
		cancelButton.x = 15;
		cancelButton.y = 60;
		cancelButton.setSize(100, 22);
		cancelButton.onPress = function():Void if (onCancel != null) onCancel();
		addChild(cancelButton);
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

private class SendMessageInfoButton extends GameButton {
	public function new() {
		super("?", new SendMessageInfoSkin());
		setSize(10, 10);
	}

	override public function redraw():Void {
		super.redraw();
		if (labelField == null) return;
		var format = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, hovered || pressed ? 0xFFFF00 : 0, false, null, null, null, null,
			TextFormatAlign.CENTER);
		labelField.defaultTextFormat = format;
		labelField.setTextFormat(format);
		labelField.x = 1.5;
		labelField.y = -0.2;
		labelField.width = 7;
		labelField.height = 10.7;
	}
}

private class SendMessageInfoSkin implements ControlSkin {
	public function new() {}
	public function draw(graphics:Graphics, width:Float, height:Float, state:ControlState):Void {
		graphics.clear();
		graphics.lineStyle(0, 0x666666);
		graphics.beginFill(state == Hovered || state == Pressed ? 0x43A398 : 0xAFAC94);
		graphics.drawCircle(5, 5, 5);
		graphics.endFill();
	}
}
