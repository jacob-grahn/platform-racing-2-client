package pr2.levelEditor;

import openfl.display.Sprite;
import pr2.ui.view.NativeView;

/** Native sidebar brush-size preview. */
class BrushSizeButtonView extends NativeView {
	public final circle:Sprite;

	public function new() {
		super();
		graphics.beginFill(0x66788C);
		graphics.lineStyle(1, 0x333333);
		graphics.drawRoundRect(0, 0, 28, 28, 6, 6);
		graphics.endFill();
		circle = new Sprite();
		circle.name = "circle";
		circle.graphics.beginFill(0xFFFFFF);
		circle.graphics.drawCircle(0, 0, 14);
		circle.graphics.endFill();
		circle.x = 14;
		circle.y = 14;
		addChild(circle);
		mouseEnabled = false;
		mouseChildren = false;
	}
}
