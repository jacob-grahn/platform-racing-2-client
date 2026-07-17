package pr2.levelEditor;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native level-source chooser for personal and reported levels. */
class ChooseLevelsModeView extends NativeView {
	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-155, -85, 310, 170, 14, 14);
		graphics.endFill();
		var title = new TextField();
		title.x = -135;
		title.y = -68;
		title.width = 270;
		title.height = 24;
		title.selectable = false;
		title.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 15, 0x222222, true, null, null, null, null,
			TextFormatAlign.CENTER);
		title.text = "-- Load Levels --";
		addChild(title);
		button("mine_bt", "My Levels", -112, -19, 104);
		button("reports_bt", "Reported Levels", 8, -19, 104);
		button("cancel_bt", "Cancel", -45, 39, 90);
	}

	private function button(name:String, label:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 25);
		addChild(control);
	}
}
