package pr2.gameplay;

typedef RotatedPoint = {
	final x:Int;
	final y:Int;
}

class RotationMath {
	/** Matches Data.rotatePoint, including AS3 int assignment truncation. */
	public static function rotatePoint(posX:Float, posY:Float, rotation:Float):RotatedPoint {
		if (rotation > 180) {
			rotation = -360 + rotation;
		} else if (rotation < -180) {
			rotation = 360 + rotation;
		}

		var x = as3Int(posX);
		var y = as3Int(posY);
		if (rotation == 90) {
			x = as3Int(posY);
			y = as3Int(-posX);
		} else if (Math.abs(rotation) == 180) {
			x = as3Int(-posX);
			y = as3Int(-posY);
		} else if (rotation == -90) {
			x = as3Int(-posY);
			y = as3Int(posX);
		}
		return {x: x, y: y};
	}

	/** Matches Flash DisplayObject rotation normalization for course layers. */
	public static function normalizeDisplayRotation(rotation:Int):Int {
		var normalized = rotation % 360;
		if (normalized > 180) {
			normalized -= 360;
		} else if (normalized < -180) {
			normalized += 360;
		}
		return normalized;
	}

	private static function as3Int(value:Float):Int {
		if (!Math.isFinite(value) || value == 0) {
			return 0;
		}
		var truncated = value < 0 ? Math.ceil(value) : Math.floor(value);
		var wrapped = truncated % 4294967296.0;
		if (wrapped < 0) {
			wrapped += 4294967296.0;
		}
		if (wrapped >= 2147483648.0) {
			wrapped -= 4294967296.0;
		}
		return Std.int(wrapped);
	}
}
