package pr2.ui.controls;

import openfl.display.Graphics;

/** Compact PR2-style horizontal slider track used by native form views. */
class SliderControlSkin implements ControlSkin {
	public function new() {}

	public function draw(graphics:Graphics, width:Float, height:Float, state:ControlState):Void {
		var center = Math.floor(height / 2);
		graphics.clear();
		graphics.lineStyle(1, state == Disabled ? 0x999999 : 0x666666);
		graphics.beginFill(state == Disabled ? 0xDDDDDD : 0xFFFFFF);
		graphics.drawRect(0, center - 2, width, 4);
		graphics.endFill();
	}
}
