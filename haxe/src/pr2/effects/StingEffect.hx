package pr2.effects;

import openfl.utils.Assets;
import pr2.audio.SoundEffects;
import pr2.character.Character;

class StingEffect extends FollowFadeEffect {
	public static inline var SOUND_PATH:String = "assets/audio/sfx/sting.wav";

	public function new(owner:Character, direction:String = "") {
		super(owner, "StingGraphic", 0.05);
		if (direction == "right") {
			removeTimelineChild("leftSting");
		} else if (direction == "left") {
			removeTimelineChild("rightSting");
		}
		if (Assets.exists(SOUND_PATH)) {
			SoundEffects.playGameSound(Assets.getSound(SOUND_PATH), x, y, 0, 0, 0.66);
		}
	}
}
