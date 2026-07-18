package pr2.ui.view;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;

/** Explicit native composition of UploadingPopupGraphic, shared by upload/load flows. */
class ProgressPopupView extends NativeView {
	public final message:TextField;
	public final closeButton:GameButton;
	public var onClose:Null<Void->Void>;

	public function new(messageText:String = "Uploading...") {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.name = "background";
		panel.x = -125;
		panel.y = -52;
		panel.scaleX = 0.919113159179688;
		panel.scaleY = 0.544708251953125;
		addChild(panel);

		message = new TextField();
		message.name = "textBox";
		message.x = -98;
		message.y = -38.15;
		message.width = 196;
		message.height = 14.55;
		message.selectable = false;
		message.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0, null, null, null, null, null, TextFormatAlign.CENTER);
		message.text = messageText;
		addChild(message);

		closeButton = ownControl(new GameButton("Close"));
		closeButton.name = "close_bt";
		closeButton.x = -50;
		closeButton.y = 19;
		closeButton.setSize(100, 22);
		closeButton.onPress = function():Void if (onClose != null) onClose();
		addChild(closeButton);
	}

	public function setText(value:String):Void message.text = value;

	override public function dispose():Void {
		onClose = null;
		super.dispose();
	}
}
