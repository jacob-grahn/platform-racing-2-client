package pr2.gameplay;

/** A point in the shared, unrotated block-map coordinate system. */
class CanonicalPoint {
	public final x:Int;
	public final y:Int;

	public inline function new(x:Int, y:Int) {
		this.x = x;
		this.y = y;
	}
}

/** A point in one participant's gravity-local physics coordinate system. */
class GravityPoint {
	public final x:Int;
	public final y:Int;

	public inline function new(x:Int, y:Int) {
		this.x = x;
		this.y = y;
	}
}

/** A point serialized by an effect packet, before packet-specific decoding. */
class EffectPacketPoint {
	public final x:Int;
	public final y:Int;

	public inline function new(x:Int, y:Int) {
		this.x = x;
		this.y = y;
	}
}

/** A point ready to mount on the unrotated character/effect presentation plane. */
class DisplayPoint {
	public final x:Int;
	public final y:Int;

	public inline function new(x:Int, y:Int) {
		this.x = x;
		this.y = y;
	}
}

/**
	Named coordinate-space boundaries for Flash's rotation-local physics model.

	Flash rewrites character physics coordinates whenever gravity rotates. Blocks
	remain in canonical map space, while projectiles retain their sender's gravity
	frame and are reprojected for each receiver.
**/
class CoordinateFrames {
	public static function canonicalFromGravity(point:GravityPoint, rotation:Int):CanonicalPoint {
		return canonicalFromGravityValues(point.x, point.y, rotation);
	}

	public static function canonicalFromGravityValues(x:Float, y:Float, rotation:Int):CanonicalPoint {
		var converted = RotationMath.rotatePoint(x, y, rotation);
		return new CanonicalPoint(converted.x, converted.y);
	}

	public static function gravityFromCanonical(point:CanonicalPoint, rotation:Int):GravityPoint {
		return gravityFromCanonicalValues(point.x, point.y, rotation);
	}

	public static function gravityFromCanonicalValues(x:Float, y:Float, rotation:Int):GravityPoint {
		var converted = RotationMath.rotatePoint(x, y, -rotation);
		return new GravityPoint(converted.x, converted.y);
	}

	public static function gravityBetween(point:GravityPoint, senderRotation:Int, receiverRotation:Int):GravityPoint {
		var converted = RotationMath.rotatePoint(point.x, point.y, -(receiverRotation - senderRotation));
		return new GravityPoint(converted.x, converted.y);
	}

	public static function displayFromGravity(point:GravityPoint, senderRotation:Int, receiverRotation:Int):DisplayPoint {
		return displayFromGravityValues(point.x, point.y, senderRotation, receiverRotation);
	}

	/** Scalar entry point for hot loops whose mutable physics state is stored as fields. */
	public static function displayFromGravityValues(x:Float, y:Float, senderRotation:Int, receiverRotation:Int):DisplayPoint {
		var converted = RotationMath.rotatePoint(x, y, -(receiverRotation - senderRotation));
		return new DisplayPoint(converted.x, converted.y);
	}

	/** Mine packets uniquely encode a canonical tile centre with positive sender rotation. */
	public static function canonicalFromMinePacket(point:EffectPacketPoint, senderRotation:Int):CanonicalPoint {
		var converted = RotationMath.rotatePoint(point.x, point.y, -senderRotation);
		return new CanonicalPoint(converted.x, converted.y);
	}

	public static function displayFromCanonical(point:CanonicalPoint, receiverRotation:Int):DisplayPoint {
		var converted = gravityFromCanonical(point, receiverRotation);
		return new DisplayPoint(converted.x, converted.y);
	}
}
