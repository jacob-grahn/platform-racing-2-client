package pr2.gameplay;

import openfl.display.Sprite;

/** Presentation boundary; Course and GamePage retain simulation/session ownership. */
class GameHud extends Sprite {
	public var fullViewport(default, null):Bool = false;
	public var quitButton(default, null):QuitButton;
	public function new() super();
	public function mount(course:Course):Void {}
	public function setDone():Void {}
	public function setResultsOpen(value:Bool):Void {}
	public function placeEvent(display:openfl.display.DisplayObject):Void {
		display.x = pr2.Constants.STAGE_WIDTH / 2;
		display.y = pr2.Constants.STAGE_HEIGHT / 2;
	}
	public function remove():Void { if (parent != null) parent.removeChild(this); }
}
