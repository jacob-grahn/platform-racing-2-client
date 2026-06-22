package pr2.gameplay;

/** Exact camera easing used by `gameplay.Course.cameraFollowPlayer`. */
class CameraFollow {
	public var posX(default, null):Float;
	public var posY(default, null):Float;

	public function new(posX:Float, posY:Float) {
		this.posX = posX;
		this.posY = posY;
	}

	public function follow(characterX:Float, characterY:Float):Void {
		posX += (-characterX - posX) * 0.5;
		posY += (-characterY + 45 - posY) * 0.4;
	}
}
