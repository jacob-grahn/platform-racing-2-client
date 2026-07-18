package pr2.lobby.level;

import openfl.display.DisplayObject;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native course confirmation/countdown menu. */
class CourseMenuView extends NativeView {
	public final countdown:TextField;
	public final panel:DisplayObject;
	public final playButton:GameButton;
	public final cancelButton:GameButton;

	public function new() {
		super();
		panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.scaleX = 0.514739990234375;
		panel.scaleY = 0.308868408203125;
		addChild(panel);
		countdown = new TextField();
		countdown.name = "textBox";
		countdown.x = 33.6;
		countdown.y = 39.05;
		countdown.width = 69.35;
		countdown.height = 12.15;
		countdown.selectable = false;
		countdown.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0, false, null, null, null, null,
			TextFormatAlign.CENTER);
		countdown.text = "--";
		addChild(countdown);
		cancelButton = button("cancel_bt", "Cancel", 6, 6);
		playButton = button("play_bt", "Play", 72.9, 6);
	}

	private function button(name:String, label:String, x:Float, y:Float):GameButton {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(60.0021362304688, 22);
		addChild(control);
		return control;
	}
}
