package pr2.harness;

import openfl.display.DisplayObject;

class PlayerDisplayPlacement {
	public static inline var CHARACTER_SCALE:Float = 0.9;

	public static function place(
		playerDisplay:DisplayObject,
		characterDisplay:DisplayObject,
		feetX:Float,
		feetY:Float,
		facingScaleX:Int,
		rotationDegrees:Float = 0
	):Void {
		// The character art is feet-anchored: the inner display is offset down by
		// the standing charHeight so its origin lands exactly on the feet. The
		// container must therefore always subtract STANDING_HEIGHT, regardless of
		// crouch state. Crouching is conveyed purely by the crouch animation frame
		// (Flash keeps scaleY = 1 and the feet pinned); using the shorter crouch
		// height here drops the display origin below the feet and sinks the
		// character into the floor.
		var pivotX = LocalPlayerController.STANDING_WIDTH / 2;
		var pivotY = LocalPlayerController.STANDING_HEIGHT;
		var radians = rotationDegrees * Math.PI / 180;
		var cos = Math.cos(radians);
		var sin = Math.sin(radians);
		playerDisplay.x = feetX - (pivotX * cos - pivotY * sin);
		playerDisplay.y = feetY - (pivotX * sin + pivotY * cos);
		playerDisplay.rotation = rotationDegrees;
		playerDisplay.scaleY = 1;
		characterDisplay.scaleX = CHARACTER_SCALE * facingScaleX;
		characterDisplay.scaleY = CHARACTER_SCALE;
	}
}
