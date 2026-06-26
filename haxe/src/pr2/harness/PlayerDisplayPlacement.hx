package pr2.harness;

import openfl.display.DisplayObject;

class PlayerDisplayPlacement {
	public static inline var CHARACTER_SCALE:Float = 0.9;

	public static function place(
		playerDisplay:DisplayObject,
		characterDisplay:DisplayObject,
		feetX:Float,
		feetY:Float,
		crouching:Bool,
		facingScaleX:Int
	):Void {
		var height = crouching ? LocalPlayerController.CROUCHING_HEIGHT : LocalPlayerController.STANDING_HEIGHT;
		playerDisplay.x = feetX - LocalPlayerController.STANDING_WIDTH / 2;
		playerDisplay.y = feetY - height;
		playerDisplay.scaleY = 1;
		characterDisplay.scaleX = CHARACTER_SCALE * facingScaleX;
		characterDisplay.scaleY = CHARACTER_SCALE;
	}
}
