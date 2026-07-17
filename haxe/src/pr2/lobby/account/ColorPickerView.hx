package pr2.lobby.account;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

/** Native shell for the procedural palette, HSV spectrum, preview, and actions. */
class ColorPickerView extends NativeView {
	public final okButton:GameButton;
	public final cancelButton:GameButton;
	public final textInput:GameTextInput;

	public function new() {
		super();
		graphics.beginFill(0xF2F2F2, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(0, 0, 250, 230, 12, 12);
		graphics.endFill();
		var heading = new TextField();
		heading.x = 110;
		heading.y = 136;
		heading.width = 125;
		heading.height = 17;
		heading.selectable = false;
		heading.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0x222222, true, null, null, null, null,
			TextFormatAlign.CENTER);
		heading.text = "Hex Color";
		addChild(heading);
		textInput = ownControl(new GameTextInput());
		textInput.name = "textBox";
		textInput.x = 115;
		textInput.y = 153;
		textInput.setSize(120, 24);
		addChild(textInput);
		okButton = button("ok_bt", "OK", 114, 214, 54);
		cancelButton = button("cancel_bt", "Cancel", 174, 214, 62);
	}

	private function button(name:String, value:String, x:Float, y:Float, width:Float):GameButton {
		var control = ownControl(new GameButton(value));
		control.name = name;
		control.x = x;
		control.y = y - 10;
		control.setSize(width, 22);
		addChild(control);
		return control;
	}
}
