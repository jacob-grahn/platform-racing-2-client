package pr2.mobile;

import pr2.gameplay.player.LocalPlayerInput;

/** Touch direction mapping kept independent of drawing and keyboard state. */
class MobileRaceInput {
	public static function joystick(input:LocalPlayerInput, dx:Float, dy:Float):Void {
		input.left = dx < -.25; input.right = dx > .25;
		input.down = dy > .25; input.jumpHold = dy < -.25;
	}
}
