package pr2.ui.controls;

import openfl.display.Graphics;

interface ControlSkin {
	public function draw(graphics:Graphics, width:Float, height:Float, state:ControlState):Void;
}
