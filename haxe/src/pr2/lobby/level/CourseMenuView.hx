package pr2.lobby.level;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native course confirmation/countdown menu. */
class CourseMenuView extends NativeView {
	public final countdown:TextField;

	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-72, -50, 144, 100, 11, 11);
		graphics.endFill();
		countdown = new TextField();
		countdown.x = -50;
		countdown.y = -39;
		countdown.width = 100;
		countdown.height = 33;
		countdown.selectable = false;
		countdown.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 22, 0x222222, true, null, null, null, null,
			TextFormatAlign.CENTER);
		countdown.text = "--";
		addChild(countdown);
		button("play_bt", "Play", -62, 9);
		button("cancel_bt", "Cancel", 5, 9);
	}

	private function button(name:String, label:String, x:Float, y:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(57, 25);
		addChild(control);
	}
}
