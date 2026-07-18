package pr2.levelEditor;

import openfl.display.Sprite;
import pr2.runtime.SvgAsset;
import pr2.ui.view.NativeView;

/** Native sidebar brush-size preview. */
class BrushSizeButtonView extends NativeView {
	public final circle:Sprite;

	public function new() {
		super();
		var background = SvgAsset.create("assets/svg/editor/size_picker_background.svg");
		background.name = "background";
		background.scaleX = 1.36363220214844;
		background.scaleY = 1.36363220214844;
		addChild(background);
		circle = new Sprite();
		circle.name = "circle";
		circle.graphics.beginFill(0x000000);
		circle.graphics.drawCircle(0, 0, 14);
		circle.graphics.endFill();
		circle.x = 15;
		circle.y = 15;
		addChild(circle);
		mouseEnabled = false;
		mouseChildren = false;
	}
}
