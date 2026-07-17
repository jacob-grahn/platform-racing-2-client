package pr2.levelEditor;

import pr2.ui.controls.GameSlider;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

/** Native numeric brush-size slider and input. */
class BrushSizeMenuView extends NativeView {
	public final slider:GameSlider;
	public final textInput:GameTextInput;

	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-85, -35, 170, 70, 10, 10);
		graphics.endFill();
		slider = ownControl(new GameSlider(1, 255, 1, 1));
		slider.name = "slider";
		slider.x = -54;
		slider.y = -18;
		slider.setSize(108, 22);
		addChild(slider);
		textInput = ownControl(new GameTextInput("1"));
		textInput.name = "textBox";
		textInput.x = 40;
		textInput.y = -18;
		textInput.setSize(36, 22);
		addChild(textInput);
	}
}
