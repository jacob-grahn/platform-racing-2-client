package pr2.audio;

import openfl.utils.Assets;
import pr2.generated.assets.AssetTypes.FrameDef;
import pr2.lobby.account.Settings;

/**
	Playback for Flash timeline event sounds.

	Event/default-sync sounds start once when their keyframe is entered and then
	run independently of the timeline. Seeking, envelopes, and non-event sync
	modes are handled by later runtime parity work.
**/
class TimelineSound {
	public static function playEventFrame(frame:FrameDef):Void {
		if (frame.soundName == null || Settings.soundLevel <= 0) {
			return;
		}

		var path = assetPath(frame.soundName);
		var sound = Assets.getSound(path);
		if (sound != null) {
			SoundEffects.playSound(sound, Settings.soundLevel / 100);
		}
	}

	public static function assetPath(libraryName:String):String {
		var slash = libraryName.lastIndexOf("/");
		var fileName = slash < 0 ? libraryName : libraryName.substr(slash + 1);
		return "assets/audio/sfx/" + fileName;
	}

	private function new() {}
}
