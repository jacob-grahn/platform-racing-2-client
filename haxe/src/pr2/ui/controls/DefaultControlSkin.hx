package pr2.ui.controls;

import openfl.display.Graphics;

/** Deliberately simple fallback; production views can inject parity skins. */
class DefaultControlSkin implements ControlSkin {
	public function new() {}

	public function draw(graphics:Graphics, width:Float, height:Float, state:ControlState):Void {
		var fill = switch state {
			case Disabled: 0xD0D0D0;
			case Pressed, Selected: 0xB8CBE0;
			case Focused, Hovered: 0xE8F2FC;
			case Normal: 0xF4F4F4;
		};
		graphics.clear();
		graphics.lineStyle(state == Focused ? 2 : 1, 0x555555);
		graphics.beginFill(fill);
		graphics.drawRoundRect(0, 0, width, height, 4, 4);
		graphics.endFill();
	}
}
