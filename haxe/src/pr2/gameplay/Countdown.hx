package pr2.gameplay;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.utils.Assets;
import pr2.audio.SoundEffects;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.lobby.account.Settings;

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

	private var art:Null<Sprite>;
	private var text:Null<TextField>;
	private var frame:Int = 1;
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
		art = new Sprite();
		text = new TextField();
		text.x = -120;
		text.y = -70;
		text.width = 240;
		text.height = 140;
		text.selectable = false;
		text.mouseEnabled = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 92, 0xFFFFFF, true, null, null, null, null,
			TextFormatAlign.CENTER);
		text.filters = [new openfl.filters.GlowFilter(0x000000, 0.9, 8, 8, 2)];
		art.addChild(text);
		art.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		applyVisual();
		addChild(art);
	}

	/** Step the countdown one frame. Production lets PR2MovieClip auto-play, so
		this is only needed to drive the timeline deterministically (tests). */
	public function advance():Void {
		advanceOneFrame();
	}

	private function onEnterFrame(_:Event):Void advanceOneFrame();

	private function advanceOneFrame():Void {
		if (art == null) return;
		frame++;
		if (frame == 9 || frame == 24 || frame == 39) handleCount();
		if (frame == 54) handleFinish();
		applyVisual();
		if (frame >= 62) handleEnd();
	}

	private function applyVisual():Void {
		if (text == null) return;
		var phase = frame <= 15 ? 0 : frame <= 30 ? 1 : frame <= 45 ? 2 : 3;
		var local = frame - phase * 15;
		text.text = phase == 0 ? "3" : phase == 1 ? "2" : phase == 2 ? "1" : "Go!";
		var progress = Math.min(1, local / 9);
		var scale = 1 + 8 * (1 - progress) * (1 - progress);
		text.scaleX = text.scaleY = scale;
		text.alpha = local > 12 ? Math.max(0, (15 - local) / 3) : 1;
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
			art.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			if (art.parent != null) art.parent.removeChild(art);
			art = null;
		}
		text = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
