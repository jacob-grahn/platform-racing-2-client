package pr2.gameplay;

import openfl.utils.Assets;
import pr2.audio.SoundEffects;
import pr2.level.ServerLevelRenderer;
import pr2.net.CommandHandler;

/**
	Server-pushed race effects from `background.EffectBackground`.
**/
class EffectBackground {
	public static inline var ICE_WAVE_SOUND_PATH:String = "assets/audio/sfx/sound914.mp3";

	public static var instance(default, null):Null<EffectBackground>;

	private final course:Course;
	private final commandHandler:CommandHandler;
	private final playIceWaveSound:Null<Int->Int->Void>;
	private var removed:Bool = false;

	public function new(course:Course, commandHandler:CommandHandler, ?playIceWaveSound:Int->Int->Void) {
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
				mountAttackVisual('Laser`$originX`$originY`' + stringArg(args, 3, "right") + '`' + parseIntArg(args, 4) + '`'
					+ parseIntArg(args, 5));
			case "Slash":
				mountAttackVisual('Slash`$originX`$originY`' + stringArg(args, 3, "right") + '`' + parseIntArg(args, 4));
			case "Mine":
				var rotation = parseIntArg(args, 3);
				var tileWorldX = mineTileWorld(originX);
				var tileWorldY = mineTileWorld(originY);
				if (course.levelRenderer != null) {
					course.levelRenderer.showMineAppear(originX, originY, tileWorldX, tileWorldY, rotation);
				}
			case "Hat":
				course.addLooseHat(originX, originY, parseIntArg(args, 3), parseIntArg(args, 4), parseIntArg(args, 5), parseIntArg(args, 6),
					parseIntArg(args, 7));
			case "IceWave":
				var angle = parseIntArg(args, 3);
				var rot = parseIntArg(args, 4);
				mountAttackVisual('IceWave`$originX`$originY`$angle`$rot`' + parseIntArg(args, 5));
				playIceWave(originX, originY);
			case "Teleport":
				if (course.levelRenderer != null) {
					course.levelRenderer.showTeleportPop(originX, originY);
				}
			default:
		}
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		commandHandler.defineCommand("addEffect", null);
		if (instance == this) {
			instance = null;
		}
	}

	private function mountAttackVisual(payload:String):Void {
		if (course.eggRound != null) {
			course.eggRound.mountAttackVisual(payload);
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

	private static function mineTileWorld(world:Int):Int {
		return Std.int(Math.round((world - ServerLevelRenderer.TILE_SIZE / 2) / ServerLevelRenderer.TILE_SIZE)) * ServerLevelRenderer.TILE_SIZE;
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
