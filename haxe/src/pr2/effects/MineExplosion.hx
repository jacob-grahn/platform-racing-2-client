package pr2.effects;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.utils.Assets;
import pr2.audio.SoundEffects;

/**
	Authored mine explosion effect from `effects/MineExplode.as`.
**/
class MineExplosion extends Sprite {
	public static inline var LIFETIME_FRAMES:Int = 14;
	public static inline var SOUND_PATH:String = "assets/audio/sfx/mine_explosion.mp3";

	public var animation(default, null):NativeEffectAnimation;
	private var framesRemaining:Int = LIFETIME_FRAMES;

	public function new(worldX:Float, worldY:Float, cameraX:Float = 0, cameraY:Float = 0, playSound:Bool = true) {
		super();
		x = worldX;
		y = worldY;
		animation = new NativeEffectAnimation("mine", LIFETIME_FRAMES);
		addChild(animation);
		addEventListener(Event.ENTER_FRAME, tick);

		if (playSound && Assets.exists(SOUND_PATH)) {
			SoundEffects.playGameSound(Assets.getSound(SOUND_PATH), worldX, worldY, cameraX, cameraY);
		}
	}

	private function tick(event:Event):Void {
		framesRemaining--;
		if (framesRemaining <= 0) {
			remove();
		}
	}

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, tick);
		if (animation != null) {
			animation.dispose();
			if (animation.parent != null) animation.parent.removeChild(animation);
			animation = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
