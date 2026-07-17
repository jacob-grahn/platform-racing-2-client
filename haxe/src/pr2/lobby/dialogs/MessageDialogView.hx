package pr2.lobby.dialogs;

import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Explicit native composition of MessagePopupGraphic. */
class MessageDialogView extends NativeView {
	public final message:TextField;
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

		message = new TextField();
		message.name = "textBox";
		message.x = -155;
		message.y = -65;
		message.width = 309.109497070313;
		message.height = 147.65;
		message.multiline = true;
		message.wordWrap = true;
		message.selectable = true;
		message.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0);
		message.htmlText = value;
		addChild(message);

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
