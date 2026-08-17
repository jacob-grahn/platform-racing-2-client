package pr2.gameplay;

import pr2.gameplay.CoordinateFrames.EffectPacketPoint;
import pr2.gameplay.CoordinateFrames.GravityPoint;

class LaserEffectPacket {
	public final position:GravityPoint;
	public final direction:String;
	public final senderRotation:Int;
	public final shooterId:Int;

	public function new(position:GravityPoint, direction:String, senderRotation:Int, shooterId:Int) {
		this.position = position;
		this.direction = direction;
		this.senderRotation = senderRotation;
		this.shooterId = shooterId;
	}
}

class IceWaveEffectPacket {
	public final position:GravityPoint;
	public final angle:Int;
	public final senderRotation:Int;
	public final shooterId:Int;

	public function new(position:GravityPoint, angle:Int, senderRotation:Int, shooterId:Int) {
		this.position = position;
		this.angle = angle;
		this.senderRotation = senderRotation;
		this.shooterId = shooterId;
	}
}

class MineEffectPacket {
	public final position:EffectPacketPoint;
	public final senderRotation:Int;

	public function new(position:EffectPacketPoint, senderRotation:Int) {
		this.position = position;
		this.senderRotation = senderRotation;
	}
}

/** Typed adapters over Flash's unchanged `add_effect` argument layouts. */
class EffectPackets {
	public static function laser(args:Array<String>):LaserEffectPacket {
		return new LaserEffectPacket(
			new GravityPoint(intArg(args, 1), intArg(args, 2)),
			stringArg(args, 3, "right"),
			intArg(args, 4),
			intArg(args, 5)
		);
	}

	public static function iceWave(args:Array<String>):IceWaveEffectPacket {
		return new IceWaveEffectPacket(
			new GravityPoint(intArg(args, 1), intArg(args, 2)),
			intArg(args, 3),
			intArg(args, 4),
			intArg(args, 5)
		);
	}

	public static function mine(args:Array<String>):MineEffectPacket {
		return new MineEffectPacket(new EffectPacketPoint(intArg(args, 1), intArg(args, 2)), intArg(args, 3));
	}

	private static function intArg(args:Array<String>, index:Int):Int {
		if (index >= args.length) return 0;
		var parsed = Std.parseInt(args[index]);
		return parsed == null ? 0 : parsed;
	}

	private static function stringArg(args:Array<String>, index:Int, fallback:String):String {
		return index < args.length && args[index] != null ? args[index] : fallback;
	}
}
