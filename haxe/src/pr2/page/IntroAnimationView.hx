package pr2.page;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.utils.Assets;
import pr2.animation.TimelineClip;
import pr2.lobby.account.Settings;

typedef IntroSoundPlayer = String->Float->Null<SoundChannel>;

/** Typed owner for the supported semantic Lottie intro timelines. */
class IntroAnimationView extends Sprite {
	public var currentFrame(get, never):Int;
	public var totalFrames(get, never):Int;
	public final logoHolder:Sprite;
	public final timeline:TimelineClip;
	private var soundChannel:Null<SoundChannel>;
	private static inline var JIGGMIN_SOUND = "assets/audio/sfx/logo_theme.mp3";
	private final playSound:IntroSoundPlayer;

	public function new(kind:String, ?playSound:IntroSoundPlayer) {
		super();
		if (kind != "jiggmin" && kind != "kongregate") throw 'Unsupported intro $kind';
		this.playSound = playSound == null ? playAssetSound : playSound;
		name = kind + "Intro";
		timeline = new TimelineClip('assets/intro/$kind.lottie.json');
		timeline.markerHandler = onMarker;
		addChild(timeline);
		var attachment = timeline.attachment("logo_mc");
		if (attachment != null) {
			logoHolder = attachment;
		} else {
			logoHolder = new Sprite();
			addChild(logoHolder);
		}
		timeline.addEventListener(Event.COMPLETE, onComplete);
		timeline.emitCurrentMarkers();
	}

	public function stop():Void timeline.stop();

	public function dispose():Void {
		timeline.removeEventListener(Event.COMPLETE, onComplete);
		timeline.markerHandler = null;
		timeline.dispose();
		if (soundChannel != null) soundChannel.stop();
		soundChannel = null;
		if (parent != null) parent.removeChild(this);
	}

	private function onComplete(_:Event):Void {
		dispatchEvent(new Event(Event.COMPLETE));
	}

	private function onMarker(marker:String):Void {
		if (marker != "sound:logo_theme") return;
		if (soundChannel != null) soundChannel.stop();
		soundChannel = playSound(JIGGMIN_SOUND, Settings.soundLevel / 100);
	}

	private static function playAssetSound(path:String, volume:Float):Null<SoundChannel> {
		if (!Assets.exists(path) || volume <= 0) return null;
		return Assets.getSound(path).play(0, 0, new SoundTransform(volume));
	}

	private inline function get_currentFrame():Int return timeline.currentFrame;
	private inline function get_totalFrames():Int return timeline.totalFrames;
}
