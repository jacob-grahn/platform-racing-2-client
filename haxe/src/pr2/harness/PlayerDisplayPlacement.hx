package pr2.harness;

import openfl.display.DisplayObject;

class PlayerDisplayPlacement {
	public static inline var CHARACTER_SCALE:Float = 0.9;

	public static function place(
		playerDisplay:DisplayObject,
		characterDisplay:DisplayObject,
		feetX:Float,
		feetY:Float,
		facingScaleX:Int
	):Void {
		// The character art is feet-anchored: the inner display is offset down by
		// the standing charHeight so its origin lands exactly on the feet. The
		// container must therefore always subtract STANDING_HEIGHT, regardless of
		// crouch state. Crouching is conveyed purely by the crouch animation frame
		// (Flash keeps scaleY = 1 and the feet pinned); using the shorter crouch
		// height here drops the display origin below the feet and sinks the
		// character into the floor.
		playerDisplay.x = feetX - LocalPlayerController.STANDING_WIDTH / 2;
		playerDisplay.y = feetY - LocalPlayerController.STANDING_HEIGHT;
		playerDisplay.scaleY = 1;
		characterDisplay.scaleX = CHARACTER_SCALE * facingScaleX;
		characterDisplay.scaleY = CHARACTER_SCALE;
	}
}
