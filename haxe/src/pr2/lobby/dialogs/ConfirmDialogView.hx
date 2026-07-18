package pr2.lobby.dialogs;

import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Explicit composition of the authored ConfirmPopupGraphic. */
class ConfirmDialogView extends NativeView {
	public final message:TextField;
	public final confirmButton:GameButton;
	public final cancelButton:GameButton;
	public var onConfirm:Null<Void->Void>;
	public var onCancel:Null<Void->Void>;

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
		message.selectable = false;
		message.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0);
		message.htmlText = value;
		addChild(message);

		confirmButton = ownControl(new GameButton("OK"));
		confirmButton.name = "ok_bt";
		confirmButton.x = -124;
		confirmButton.y = 43;
		confirmButton.onPress = function():Void if (onConfirm != null) onConfirm();
		addChild(confirmButton);

		cancelButton = ownControl(new GameButton("Cancel"));
		cancelButton.name = "cancel_bt";
		cancelButton.x = 22;
		cancelButton.y = 43;
		cancelButton.onPress = function():Void if (onCancel != null) onCancel();
		addChild(cancelButton);
	}

	override public function dispose():Void {
		onConfirm = null;
		onCancel = null;
		super.dispose();
	}
}
