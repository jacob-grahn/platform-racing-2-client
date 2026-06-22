package pr2.audio;

import haxe.Timer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.utils.Assets;

/** The two-layer Noodle Town menu track, including frame-rate fades and the
	original random crossfade behavior. */
class MenuMusic extends Sprite {
	private var channel1:Null<SoundChannel>;
	private var channel2:Null<SoundChannel>;
	private var percentage1:Float = 1;
	private var percentage2:Float = 0;
	private var crossfadeRate:Float = 0;
	private var volume:Float = 0;
	private var targetVolume:Float = 1;
	private var crossfadeTimer:Null<Timer>;

	public function new() super();

	public function startPlaying():Void {
		if (channel1 != null) return;
		if (Math.random() > 0.5) { percentage1 = 0; percentage2 = 1; }
		else { percentage1 = 1; percentage2 = 0; }
		channel1 = Assets.getSound("assets/audio/sfx/sound104.wav").play(0, 9999);
		channel2 = Assets.getSound("assets/audio/sfx/sound103.wav").play(0, 9999);
		applyVolume(volume);
		scheduleCrossfade();
	}

	public function setTargetVolume(value:Float):Void {
		targetVolume = Math.max(0, Math.min(1, value));
		removeEventListener(Event.ENTER_FRAME, volumeFadeTick);
		addEventListener(Event.ENTER_FRAME, volumeFadeTick);
	}

	public function stop():Void {
		if (channel1 != null) channel1.stop();
		if (channel2 != null) channel2.stop();
		channel1 = channel2 = null;
		removeEventListener(Event.ENTER_FRAME, crossfadeTick);
		removeEventListener(Event.ENTER_FRAME, volumeFadeTick);
		if (crossfadeTimer != null) crossfadeTimer.stop();
		crossfadeTimer = null;
	}

	public function remove():Void stop();

	private function scheduleCrossfade():Void {
		if (crossfadeTimer != null) crossfadeTimer.stop();
		crossfadeTimer = Timer.delay(startCrossfade, Std.int(Math.random() * 80000));
	}

	private function startCrossfade():Void {
		crossfadeRate = Math.random() * 0.004 + 0.002;
		if (percentage1 > percentage2) crossfadeRate = -crossfadeRate;
		addEventListener(Event.ENTER_FRAME, crossfadeTick);
		scheduleCrossfade();
	}

	private function crossfadeTick(_:Event):Void {
		percentage1 += crossfadeRate;
		percentage2 -= crossfadeRate;
		if (percentage1 <= 0) { percentage1 = 0; percentage2 = 1; removeEventListener(Event.ENTER_FRAME, crossfadeTick); }
		if (percentage2 <= 0) { percentage1 = 1; percentage2 = 0; removeEventListener(Event.ENTER_FRAME, crossfadeTick); }
		applyVolume(volume);
	}

	private function volumeFadeTick(_:Event):Void {
		volume += volume < targetVolume ? 0.05 : -0.05;
		if (Math.abs(volume - targetVolume) <= 0.05) {
			volume = targetVolume;
			removeEventListener(Event.ENTER_FRAME, volumeFadeTick);
		}
		applyVolume(volume);
		if (volume <= 0 && targetVolume <= 0) stop();
	}

	private function applyVolume(value:Float):Void {
		volume = value;
		if (channel1 != null) channel1.soundTransform = new SoundTransform(volume * percentage1);
		if (channel2 != null) channel2.soundTransform = new SoundTransform(volume * percentage2);
	}
}
