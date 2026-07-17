package pr2.lobby.dialogs;

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
	public var onClose:Null<Void->Void>;

	public function new(name:String) {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -110;
		panel.y = -65;
		panel.scaleX = 0.81;
		panel.scaleY = 0.65;
		addChild(panel);
		nameBox = new TextField();
		nameBox.name = "nameBox";
		nameBox.x = -90;
		nameBox.y = -47;
		nameBox.width = 180;
		nameBox.height = 18;
		nameBox.selectable = false;
		nameBox.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 14, 0, true, null, null, null, null,
			TextFormatAlign.CENTER);
		nameBox.text = "-- " + name + " --";
		addChild(nameBox);
		var close = ownControl(new GameButton("Close"));
		close.name = "close_bt";
		close.x = -45;
		close.y = 17;
		close.setSize(90, 22);
		close.onPress = function():Void if (onClose != null) onClose();
		addChild(close);
	}

	override public function dispose():Void {
		onClose = null;
		super.dispose();
	}
}
