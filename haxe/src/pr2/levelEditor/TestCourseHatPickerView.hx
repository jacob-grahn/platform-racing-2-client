package pr2.levelEditor;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native hat selector with explicit left/right controls and live hat id. */
class TestCourseHatPickerView extends NativeView {
	private final hatField:TextField;
	private final epicRing:Sprite;

	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.94);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-64, -25, 128, 50, 10, 10);
		graphics.endFill();
		button("left", "‹", -58, -12);
		button("right", "›", 35, -12);
		epicRing = new Sprite();
		epicRing.graphics.lineStyle(3, 0x9D68D6);
		epicRing.graphics.drawCircle(0, 0, 18);
		addChild(epicRing);
		hatField = new TextField();
		hatField.name = "hat";
		hatField.x = -22;
		hatField.y = -10;
		hatField.width = 44;
		hatField.height = 22;
		hatField.selectable = false;
		hatField.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0x222222, true, null, null, null, null,
			TextFormatAlign.CENTER);
		addChild(hatField);
	}

	public function setHat(id:Int):Void {
		hatField.text = "Hat " + id;
		epicRing.visible = id == 16;
	}

	private function button(name:String, label:String, x:Float, y:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(23, 24);
		addChild(control);
	}
}
