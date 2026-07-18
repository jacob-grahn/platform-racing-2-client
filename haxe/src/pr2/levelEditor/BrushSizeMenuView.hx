package pr2.levelEditor;

import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.runtime.SvgAsset;
import pr2.ui.controls.GameSlider;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

/** Native numeric brush-size slider and input. */
class BrushSizeMenuView extends NativeView {
	public final slider:GameSlider;
	public final textInput:GameTextInput;

	public function new() {
		super();
		var background = SvgAsset.createNormalized("assets/svg/ui/shadow_bg.svg");
		background.name = "background";
		background.x = -96.9;
		background.y = -61.4;
		background.scaleX = 0.705459594726562;
		background.scaleY = 0.62823486328125;
		addChild(background);
		var title = new TextField();
		title.name = "title";
		title.x = -50.95;
		title.y = -49;
		title.width = 102.35;
		title.height = 14.55;
		title.scaleX = 1.00047302246094;
		title.selectable = false;
		title.mouseEnabled = false;
		title.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0x000000, true);
		title.text = "-- Brush Size --";
		addChild(title);
		slider = ownControl(new GameSlider(1, 100, 1, 1));
		slider.name = "slider";
		slider.x = -75;
		slider.y = 29;
		slider.setSize(187.5, 22);
		addChild(slider);
		textInput = ownControl(new GameTextInput("25"));
		textInput.name = "textBox";
		textInput.x = -29;
		textInput.y = -13;
		textInput.setSize(57.9376220703125, 22);
		textInput.maxChars = 3;
		textInput.textField.restrict = "0-9";
		addChild(textInput);
	}
}
