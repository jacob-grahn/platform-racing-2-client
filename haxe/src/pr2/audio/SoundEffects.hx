package pr2.audio;

import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import pr2.lobby.account.Settings;

typedef SpatialMix = {
	var volume:Float;
	var pan:Float;
}

/** Flash-compatible effect playback. Each call creates its own channel, so
	short effects overlap; callers retain looping channels and stop them. */
class SoundEffects {
	public static inline var HEARING_DISTANCE:Float = 700;

	public static function playSound(sound:Sound, volume:Float = 1, pan:Float = 0, loops:Int = 0):Null<SoundChannel> {
		if (volume <= 0.0001) return null;
		return sound.play(0, loops, new SoundTransform(volume, pan));
	}

	public static function playGameSound(sound:Sound, x:Float, y:Float, cameraX:Float, cameraY:Float,
		volume:Float = 1, pan:Float = 0, loops:Int = 0):Null<SoundChannel> {
		var mix = spatialMix(x, y, cameraX, cameraY, volume, pan, Settings.soundLevel);
		return playSound(sound, mix.volume, mix.pan, loops);
	}

	public static function spatialMix(x:Float, y:Float, cameraX:Float, cameraY:Float, volume:Float = 1,
		pan:Float = 0, soundLevel:Int = 100):SpatialMix {
		var relativeX = x + cameraX;
		var relativeY = y + cameraY;
		var distance = Math.min(HEARING_DISTANCE, Math.sqrt(relativeX * relativeX + relativeY * relativeY));
		return {
			volume: volume * ((HEARING_DISTANCE - distance) / HEARING_DISTANCE) * (soundLevel / 100),
			pan: Math.max(-1, Math.min(1, relativeX / HEARING_DISTANCE))
		};
	}
}
