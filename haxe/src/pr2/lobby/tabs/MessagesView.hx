package pr2.lobby.tabs;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native private-message tab shell and scrollable message holder. */
class MessagesView extends NativeView {
	public function new() {
		super();
		graphics.beginFill(0xF0F0F0, 0.96);
		graphics.lineStyle(1, 0x777777);
		graphics.drawRoundRect(8, 8, 266, 342, 12, 12);
		graphics.endFill();
		var heading = new TextField();
		heading.x = 20;
		heading.y = 17;
		heading.width = 120;
		heading.height = 22;
		heading.selectable = false;
		heading.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 15, 0x222222, true, null, null, null, null,
			TextFormatAlign.LEFT);
		heading.text = "Messages";
		addChild(heading);
		button("sendMessage_bt", "New Message", 126, 15, 82);
		button("deleteAll_bt", "Delete All", 213, 15, 55);
		var holder = new Sprite();
		holder.name = "var_295";
		holder.x = 18;
		holder.y = 49;
		addChild(holder);
	}

	private function button(name:String, label:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 24);
		addChild(control);
	}
}
