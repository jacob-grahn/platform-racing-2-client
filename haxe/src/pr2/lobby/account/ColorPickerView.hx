package pr2.lobby.account;

import openfl.display.Sprite;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

/** Exact native composition of the authored ColorPickerPopupGraphic shell. */
class ColorPickerView extends NativeView {
	public final panel:Sprite;
	public final okButton:GameButton;
	public final cancelButton:GameButton;
	public final textInput:GameTextInput;

	public function new() {
		super();
		panel = new Sprite();
		panel.name = "panel";
		panel.scaleX = 0.919113159179688;
		panel.scaleY = 1.36125183105469;
		panel.addChild(NativeAssets.svg(StaticSvg.QuantityPanel));
		addChild(panel);

		textInput = ownControl(new GameTextInput());
		textInput.name = "textBox";
		textInput.x = 115;
		textInput.y = 150;
		textInput.setSize(100 * 1.19999694824219, 22);
		addChild(textInput);
		okButton = button("ok_bt", "OK", 74);
		cancelButton = button("cancel_bt", "Cancel", 162);
	}

	private function button(name:String, value:String, x:Float):GameButton {
		var control = ownControl(new GameButton(value));
		control.name = name;
		control.x = x;
		control.y = 225;
		control.setSize(100 * 0.750152587890625, 22);
		addChild(control);
		return control;
	}
}
