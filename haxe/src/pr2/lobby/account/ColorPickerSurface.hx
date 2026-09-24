package pr2.lobby.account;

import openfl.display.DisplayObject;
import openfl.display.Sprite;

/** Shared event/API contract for classic and landscape color pickers. */
class ColorPickerSurface extends Sprite {
	public var fullViewport(default, null):Bool = false;
	public function new() super();
	public function init():Void {}
	public function setColor(value:Int):Void {}
	public function getColor():Int return 0;
	public function addExclusion(display:DisplayObject):Void {}
	public function remove():Void { if (parent != null) parent.removeChild(this); }
}
