package pr2.ui.controls;

import openfl.display.Graphics;

/**
	Transparent control skin for sliders. `GameSlider` renders the exact authored
	track and thumb SVGs as children; drawing another track here would leave a
	dark outline visible behind the authored component.
**/
class SliderControlSkin implements ControlSkin {
	public function new() {}

	public function draw(graphics:Graphics, width:Float, height:Float, state:ControlState):Void {
		graphics.clear();
	}
}
