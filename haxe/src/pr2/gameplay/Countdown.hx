package pr2.gameplay;

import openfl.display.Sprite;
import openfl.utils.Assets;
import pr2.audio.SoundEffects;
import pr2.lobby.account.Settings;
import pr2.runtime.PR2MovieClip;

typedef CountdownEffectPlayer = String->Float->Void;

/**
	Port of the Flash 3-2-1 race countdown.

	`CountdownGraphic`'s authored timeline animates the "3 2 1 Go" sequence and
	carries frame scripts at frames 9/24/39 (`count`) and 54 (`finish`); frame 62
	stops and self-removes. Flash's `CountdownGraphic` dispatched those as events
	and `gameplay.Course` listened (`onCountdownCount`/`onCountdownFinish`): a
	`ReadySound` per count and a `GoSound` on finish, each scaled by the saved
	sound level, with the finish also kicking off gameplay. This class fuses both
	roles — it attaches the frame scripts, plays the effects, and invokes an
	injected `onFinish` for the gameplay-start hook Course ran (`localPlayer.init`,
	`startGameplay`, `countdownFinished = true`).
**/
class Countdown extends Sprite {
	// GoSound -> sound431, ReadySound -> sound432 (AssetCatalog DOMSoundItems).
	static inline var READY_SOUND:String = "assets/audio/sfx/countdown_ready.mp3";
	static inline var GO_SOUND:String = "assets/audio/sfx/countdown_go.mp3";

	private var art:Null<PR2MovieClip>;
	private var onFinish:Null<Void->Void>;
	private var onPlayEffect:Null<CountdownEffectPlayer>;

	/** Number of "count" ticks seen (3 by the time the race starts). */
	public var counts(default, null):Int = 0;
	public var finished(default, null):Bool = false;

	public function new(?onFinish:Void->Void, ?onPlayEffect:CountdownEffectPlayer) {
		super();
		this.onFinish = onFinish;
		this.onPlayEffect = onPlayEffect;
		mouseEnabled = false;
		mouseChildren = false;
		art = PR2MovieClip.fromLinkage("CountdownGraphic", {maxNestedDepth: 3});
		// Mirror CountdownGraphic.addFrameScript(8, frame9, 23, frame24, 38,
		// frame39, 53, frame54, 61, frame62) — frame indices are zero-based.
		art.setFrameScript(8, handleCount);
		art.setFrameScript(23, handleCount);
		art.setFrameScript(38, handleCount);
		art.setFrameScript(53, handleFinish);
		art.setFrameScript(61, handleEnd);
		addChild(art);
	}

	/** Step the countdown one frame. Production lets PR2MovieClip auto-play, so
		this is only needed to drive the timeline deterministically (tests). */
	public function advance():Void {
		if (art != null) {
			art.advanceOneFrame();
		}
	}

	private function handleCount():Void {
		counts++;
		playEffect(READY_SOUND, 0.4);
	}

	private function handleFinish():Void {
		finished = true;
		playEffect(GO_SOUND, 0.5);
		if (onFinish != null) {
			onFinish();
		}
	}

	private function handleEnd():Void {
		if (art != null) {
			art.stop();
		}
		remove();
	}

	private function playEffect(path:String, volume:Float):Void {
		var scaledVolume = volume * (Settings.soundLevel / 100);
		if (onPlayEffect != null) {
			onPlayEffect(path, scaledVolume);
			return;
		}
		if (!Assets.exists(path)) {
			return;
		}
		SoundEffects.playSound(Assets.getSound(path), scaledVolume);
	}

	public function remove():Void {
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
