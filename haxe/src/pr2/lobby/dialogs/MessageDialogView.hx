package pr2.lobby.dialogs;

import openfl.text.TextField;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameTextArea;
import pr2.ui.view.NativeView;

/** Explicit native composition of MessagePopupGraphic. */
class MessageDialogView extends NativeView {
	public final message:TextField;
	public final messageArea:GameTextArea;
	public final okButton:GameButton;
	public var onClose:Null<Void->Void>;

	public function new(value:String) {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -166.5;
		panel.y = -75;
		panel.scaleX = 1.2242431640625;
		panel.scaleY = 0.785232543945312;
		addChild(panel);

		messageArea = ownControl(new GameTextArea(100, 44));
		messageArea.name = "textBox_control";
		messageArea.x = -155;
		messageArea.y = -65;
		messageArea.scaleX = 3.09109497070313;
		messageArea.scaleY = 2.27197265625;
		messageArea.editable = false;
		message = messageArea.textField;
		message.name = "textBox";
		messageArea.htmlText = value;
		addChild(messageArea);

		okButton = ownControl(new GameButton("OK"));
		okButton.name = "ok_bt";
		okButton.x = -50;
		okButton.y = 43;
		okButton.onPress = function():Void if (onClose != null) onClose();
		addChild(okButton);
	}

	override public function dispose():Void {
		onClose = null;
		super.dispose();
	}
}
