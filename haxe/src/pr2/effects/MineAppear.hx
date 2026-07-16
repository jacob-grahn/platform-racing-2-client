package pr2.effects;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.utils.Assets;
import pr2.animation.AnimationClock;
import pr2.audio.SoundEffects;

/**
	Authored mine placement effect from `effects.MineAppear`.
**/
class MineAppear extends Sprite {
	public static inline var LIFETIME_FRAMES:Int = 33;
	public static inline var SOUND_PATH:String = "assets/audio/sfx/mine_appear.mp3";

	public var animation(default, null):Null<MineAppearAnimation>;
	private final clock:AnimationClock;
	private var onComplete:Null<Void->Void>;
	private var completed:Bool = false;

	public function new(worldX:Float, worldY:Float, rotationDegrees:Float, cameraX:Float = 0, cameraY:Float = 0, ?onComplete:Void->Void,
			playSound:Bool = true) {
		super();
		x = worldX;
		y = worldY;
		rotation = rotationDegrees;
		this.onComplete = onComplete;
		clock = new AnimationClock();
		animation = new MineAppearAnimation(function():Void remove(true));
		clock.add(animation.playback);
		addChild(animation);
		addEventListener(Event.ENTER_FRAME, tick);

		if (playSound && Assets.exists(SOUND_PATH)) {
			SoundEffects.playGameSound(Assets.getSound(SOUND_PATH), worldX, worldY, cameraX, cameraY);
		}
	}

	private function tick(event:Event):Void {
		clock.advance();
	}

	public function remove(runComplete:Bool = false):Void {
		removeEventListener(Event.ENTER_FRAME, tick);
		if (runComplete && !completed && onComplete != null) {
			completed = true;
			onComplete();
		}
		onComplete = null;
		if (animation != null) {
			animation.dispose();
			animation = null;
		}
		clock.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
