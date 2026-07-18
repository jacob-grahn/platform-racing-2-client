package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native composition of PlayerGuestPopupGraphic. */
class PlayerGuestView extends NativeView {
	public final nameBox:TextField;
	public final groupLabel:TextField;
	public final panel:DisplayObject;
	public final closeButton:GameButton;
	public var onClose:Null<Void->Void>;

	public function new(name:String) {
		super();
		panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -116.2;
		panel.y = -65.9;
		panel.scaleX = 0.854537963867188;
		panel.scaleY = 0.68524169921875;
		addChild(panel);
		nameBox = new TextField();
		nameBox.name = "nameBox";
		nameBox.x = -94;
		nameBox.y = -52.5;
		nameBox.width = 188.1;
		nameBox.height = 17.05;
		nameBox.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 14, 0, false, null, null, null, null,
			TextFormatAlign.CENTER);
		nameBox.text = "-- " + name + " --";
		addChild(nameBox);
		groupLabel = new TextField();
		groupLabel.x = -40.85;
		groupLabel.y = -25.05;
		groupLabel.width = 80.75;
		groupLabel.height = 14.55;
		groupLabel.selectable = false;
		var groupFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0);
		groupFormat.letterSpacing = -0.05;
		groupLabel.defaultTextFormat = groupFormat;
		groupLabel.text = "Group: Guest";
		addChild(groupLabel);
		closeButton = ownControl(new GameButton("Close"));
		closeButton.name = "close_bt";
		closeButton.x = -50;
		closeButton.y = 30.05;
		closeButton.setSize(100, 22);
		closeButton.onPress = function():Void if (onClose != null) onClose();
		addChild(closeButton);
	}

	override public function dispose():Void {
		onClose = null;
		super.dispose();
	}
}
