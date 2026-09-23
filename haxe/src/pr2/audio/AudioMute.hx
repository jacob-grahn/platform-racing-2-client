package pr2.audio;

import openfl.media.SoundMixer;
import openfl.media.SoundTransform;

/** Shared master mute state for either presentation. */
class AudioMute {
	public static var muted(default, null):Bool = false;
	public static function setMuted(value:Bool):Void {
		muted = value;
		SoundMixer.soundTransform = new SoundTransform(muted ? 0 : 1);
	}
}
