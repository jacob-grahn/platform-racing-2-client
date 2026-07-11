package pr2.effects;

import openfl.utils.Assets;
import pr2.audio.SoundEffects;
import pr2.character.Character;

/**
	Port of `effects.Zap`: an authored flash/bolt effect that follows a character
	and fades out over ten frames.
**/
class ZapEffect extends FollowFadeEffect {
	public static inline var SOUND_PATH:String = "assets/audio/sfx/sound914.mp3";

	public function new(owner:Character, showBolt:Bool = true, playSound:Bool = true, showFlash:Bool = true) {
		super(owner, "ZapGraphic", 0.1);
		if (!showBolt) {
			removeTimelineChild("lightning");
		}
		if (!showFlash) {
			removeTimelineChild("bg");
		}
		if (playSound && Assets.exists(SOUND_PATH)) {
			SoundEffects.playSound(Assets.getSound(SOUND_PATH));
		}
	}
}
