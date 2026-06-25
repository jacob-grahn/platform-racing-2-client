package pr2.audio;

import haxe.Timer;
import openfl.events.Event;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.net.URLRequest;
import pr2.lobby.account.Settings;
import pr2.ui.MuteButton;
import pr2.audio.MusicCatalog.MusicTrack;

/** Runtime counterpart of GameSound; selection is separate from UI so the
	level editor and authored race dropdown can share identical playback rules. */
class GameMusic {
	public static inline var BASE_PATH:String = "/music/new";
	public var selected(default, null):MusicTrack;
	private var channel:Null<SoundChannel>;
	private var settingsTimer:Timer;

	public function new() {
		selected = {id: "0", label: "None", file: ""};
		settingsTimer = new Timer(500);
		settingsTimer.run = refresh;
	}

	public function setSong(song:MusicTrack):Void {
		selected = song;
		restart();
	}

	public function refresh():Void {
		if (channel == null && canPlay()) restart();
		else if (channel != null) channel.soundTransform = new SoundTransform(Settings.musicLevel / 100);
	}

	public function stop():Void {
		if (channel != null) {
			channel.removeEventListener(Event.SOUND_COMPLETE, onComplete);
			channel.stop();
			channel = null;
		}
	}

	public function remove():Void {
		settingsTimer.stop();
		stop();
	}

	private function restart():Void {
		stop();
		if (!canPlay()) return;
		var sound = new Sound(new URLRequest(BASE_PATH + "/" + selected.file));
		channel = sound.play(0, 9999, new SoundTransform(Settings.musicLevel / 100));
		if (channel != null) channel.addEventListener(Event.SOUND_COMPLETE, onComplete);
	}

	private function canPlay():Bool return Settings.musicLevel > 0 && !MuteButton.muted && selected.id != "0" && selected.file != "";
	private function onComplete(_:Event):Void restart();
}
