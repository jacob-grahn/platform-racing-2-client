package pr2.gameplay.player;

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
		// Match Flash Character: the display object's registration point and x/y
		// are the character's feet. The authored CharacterGraphic is already drawn
		// relative to that registration point, so camera and network code never
		// need to substitute a top-left display coordinate for Character.x/y.
		playerDisplay.x = feetX;
		playerDisplay.y = feetY;
		playerDisplay.rotation = rotationDegrees;
		playerDisplay.scaleY = 1;
		characterDisplay.x = 0;
		characterDisplay.y = 0;
		characterDisplay.scaleX = CHARACTER_SCALE * facingScaleX;
		characterDisplay.scaleY = CHARACTER_SCALE;
	}
}
