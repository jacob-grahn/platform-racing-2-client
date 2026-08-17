package pr2.gameplay;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.utils.Assets;
import pr2.display.Removable;
import pr2.audio.SoundEffects;
import pr2.effects.MineAppear;
import pr2.level.LevelRenderer;
import pr2.net.CommandHandler;
import pr2.character.PhysicsParticle;

/**
	Server-pushed race effects from `background.EffectBackground`.
**/
class EffectBackground extends Sprite {
	public static inline var ICE_WAVE_SOUND_PATH:String = "assets/audio/sfx/ice_wave.mp3";
	public static inline var LASER_SOUND_PATH:String = "assets/audio/sfx/laser_fire.mp3";

	public static var instance(default, null):Null<EffectBackground>;

	private final course:Course;
	private final commandHandler:CommandHandler;
	private final playIceWaveSound:Null<Int->Int->Void>;
	private var removed:Bool = false;

	public function new(course:Course, commandHandler:CommandHandler, ?playIceWaveSound:Int->Int->Void) {
		super();
		this.course = course;
		this.commandHandler = commandHandler;
		this.playIceWaveSound = playIceWaveSound;
		instance = this;
		commandHandler.defineCommand("addEffect", addEffect);
	}

	public function addEffect(args:Array<String>):Void {
		if (removed || args.length == 0) {
			return;
		}
		var type = args[0];
		var originX = parseIntArg(args, 1);
		var originY = parseIntArg(args, 2);
		switch (type) {
			case "Laser":
				var packet = EffectPackets.laser(args);
				mountLaser(packet);
				playLaser(packet.position.x, packet.position.y);
			case "Slash":
				course.mountSlashEffect(originX, originY, stringArg(args, 3, "right"), parseIntArg(args, 4));
			case "Mine":
				var packet = EffectPackets.mine(args);
				// Mine packets use the sender's rotated map frame. Resolve the
				// canonical tile first, then project its centre into this client's
				// independently rotated display frame.
				var canonicalCenter = CoordinateFrames.canonicalFromMinePacket(packet.position, packet.senderRotation);
				var tileWorldX = mineTileWorld(canonicalCenter.x);
				var tileWorldY = mineTileWorld(canonicalCenter.y);
				if (course.levelRenderer != null) {
					var receiverRotation = course.levelRenderer.courseRotationDegrees;
					var displayCenter = CoordinateFrames.displayFromCanonical(canonicalCenter, receiverRotation);
					course.levelRenderer.showMineAppear(displayCenter.x, displayCenter.y, tileWorldX, tileWorldY, receiverRotation, true,
						function():Void course.placeRuntimeMine(tileWorldX, tileWorldY));
				}
			case "Hat":
				course.addLooseHat(originX, originY, parseIntArg(args, 3), parseIntArg(args, 4), parseIntArg(args, 5), parseIntArg(args, 6),
					parseIntArg(args, 7));
			case "IceWave":
				var packet = EffectPackets.iceWave(args);
				mountIceWave(packet);
				playIceWave(packet.position.x, packet.position.y);
			case "Teleport":
				if (course.levelRenderer != null) {
					course.levelRenderer.showTeleportPop(originX, originY);
				}
			case "SnakeStart" | "SnakeStep" | "SnakeStop":
				course.applySnakeNetwork(args);
			default:
		}
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		clear();
		commandHandler.defineCommand("addEffect", null);
		if (instance == this) {
			instance = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	public function clear():Void {
		while (numChildren > 0) {
			var child:DisplayObject = getChildAt(numChildren - 1);
			var physicsParticle = Std.downcast(child, PhysicsParticle);
			if (physicsParticle != null) {
				physicsParticle.remove();
				continue;
			}
			var mineAppear = Std.downcast(child, MineAppear);
			if (mineAppear != null) {
				mineAppear.remove();
				continue;
			}
			var removable = Std.downcast(child, Removable);
			if (removable != null) {
				removable.remove();
			} else {
				removeChild(child);
			}
		}
	}

	private function mountLaser(packet:EffectPackets.LaserEffectPacket):Void {
		if (course.eggRound != null) {
			var receiverRotation = course.levelRenderer == null ? 0 : course.levelRenderer.courseRotationDegrees;
			course.eggRound.mountLaserPacket(packet, receiverRotation);
		}
	}

	private function mountIceWave(packet:EffectPackets.IceWaveEffectPacket):Void {
		if (course.eggRound != null) {
			var receiverRotation = course.levelRenderer == null ? 0 : course.levelRenderer.courseRotationDegrees;
			course.eggRound.mountIceWavePacket(packet, receiverRotation);
		}
	}

	private function playIceWave(worldX:Int, worldY:Int):Void {
		if (playIceWaveSound != null) {
			playIceWaveSound(worldX, worldY);
			return;
		}
		if (course.levelRenderer == null || !Assets.exists(ICE_WAVE_SOUND_PATH)) {
			return;
		}
		var offset = course.levelRenderer.cameraOffset();
		SoundEffects.playGameSound(Assets.getSound(ICE_WAVE_SOUND_PATH), worldX, worldY, offset.x, offset.y, 1.5);
	}

	private function playLaser(worldX:Int, worldY:Int):Void {
		if (course.levelRenderer == null || !Assets.exists(LASER_SOUND_PATH)) {
			return;
		}
		var offset = course.levelRenderer.cameraOffset();
		SoundEffects.playGameSound(Assets.getSound(LASER_SOUND_PATH), worldX, worldY, offset.x, offset.y, 1.5);
	}

	private static function mineTileWorld(world:Float):Int {
		return Std.int(Math.round((world - LevelRenderer.TILE_SIZE / 2) / LevelRenderer.TILE_SIZE)) * LevelRenderer.TILE_SIZE;
	}

	private static function parseIntArg(args:Array<String>, index:Int):Int {
		if (index >= args.length) {
			return 0;
		}
		var parsed = Std.parseInt(args[index]);
		return parsed == null ? 0 : parsed;
	}

	private static function stringArg(args:Array<String>, index:Int, fallback:String):String {
		return index < args.length && args[index] != null ? args[index] : fallback;
	}
}
