package pr2.levelEditor;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.runtime.SvgAsset;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native reconstruction of XFL `ChooseLevelsModePopupGraphic`. */
class ChooseLevelsModeView extends NativeView {
	public function new() {
		super();
		var background = SvgAsset.createNormalized("assets/svg/ui/shadow_bg.svg");
		background.name = "background";
		background.x = -122.5;
		background.y = -68.75;
		background.scaleX = 0.900802612304688;
		background.scaleY = 0.719802856445312;
		background.mouseEnabled = false;
		background.mouseChildren = false;
		addChild(background);

		label("title", "-- Choose Mode --", -107.95, -58.2, 216.95, 17.05, 14, true);
		label("prompt", "Which do you want to view?", -107.95, -33.2, 216.95, 14.55, 12, false);
		button("reports_bt", "Level Reports", -97.8, -7.5, 84.9899291992188, 23.5989074707032);
		button("mine_bt", "My Levels", 11.95, -7.5, 84.9899291992188, 23.5989074707032);
		button("cancel_bt", "Cancel", -40, 27, 79.9972534179688, 23.7000122070312);
	}

	private function label(name:String, value:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool):Void {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.mouseEnabled = false;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x000000, bold, null, null, null, null,
			TextFormatAlign.CENTER);
		text.text = value;
		addChild(text);
	}

	private function button(name:String, label:String, x:Float, y:Float, width:Float, height:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, height);
		addChild(control);
	}
}
