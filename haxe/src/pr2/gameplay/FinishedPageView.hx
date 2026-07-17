package pr2.gameplay;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native end-of-race results panel with explicit award fields and actions. */
class FinishedPageView extends NativeView {
	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x606060);
		graphics.drawRoundRect(-142, -118, 284, 260, 14, 14);
		graphics.endFill();
		addLabel("-- Race Complete! --", "titleBox", -112, -103, 224, 24, 17, true, TextFormatAlign.CENTER);
		addLabel("Awards", null, -118, -71, 146, 18, 11, true, TextFormatAlign.LEFT);
		addLabel("EXP", null, 43, -71, 75, 18, 11, true, TextFormatAlign.RIGHT);
		for (index in 1...6) {
			var y = -51 + (index - 1) * 18;
			addLabel("", "bonus" + index, -118, y, 156, 17, 10, false, TextFormatAlign.LEFT);
			addLabel("", "exp" + index, 42, y, 76, 17, 10, false, TextFormatAlign.RIGHT);
		}
		addLabel("Total:", null, 35, 40, 48, 17, 11, true, TextFormatAlign.RIGHT);
		addLabel("+ 0", "expTotal", 86, 40, 42, 17, 11, true, TextFormatAlign.RIGHT);
		addLabel("Rate this level:", null, -118, 83, 105, 18, 10, false, TextFormatAlign.LEFT);
		button("return_bt", "Return to Lobby", -117, 111, 132);
		button("close_bt", "Close", 30, 111, 88);
	}

	private function button(name:String, label:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 24);
		addChild(control);
	}

	private function addLabel(value:String, name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign):Void {
		var field = new TextField();
		if (name != null) field.name = name;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		field.text = value;
		addChild(field);
	}
}
