package pr2.gameplay;

/** Exact camera easing used by `gameplay.Course.cameraFollowPlayer`. */
class CameraFollow {
	// gameplay.Course.cameraFollowPlayer eases the camera toward (-c.x, -c.y + 45).
	static inline var Y_OFFSET:Float = 45;

	public var posX(default, null):Float;
	public var posY(default, null):Float;

	public function new(posX:Float, posY:Float) {
		this.posX = posX;
		this.posY = posY;
	}

	public function follow(characterX:Float, characterY:Float):Void {
		posX += (targetX(characterX) - posX) * 0.5;
		posY += (targetY(characterY) - posY) * 0.4;
	}

	/**
		Jump straight to the settled follow position for a character, skipping the
		ease-in. Flash hides its ease-in behind the 3-2-1 countdown (the follow
		listener only starts in `Course.beginRace`/`toggleKeyScroll`), so by the
		time racing begins the player is already centered. Screens without a
		countdown snap here instead of drifting in from an off-center start.
	**/
	public function snapTo(characterX:Float, characterY:Float):Void {
		posX = targetX(characterX);
		posY = targetY(characterY);
	}

	public function scroll(deltaX:Float, deltaY:Float):Void {
		posX += deltaX;
		posY += deltaY;
	}

	static inline function targetX(characterX:Float):Float {
		return -characterX;
	}

	static inline function targetY(characterY:Float):Float {
		return -characterY + Y_OFFSET;
	}
}
