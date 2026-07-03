package pr2.effects;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.utils.Assets;
import pr2.audio.SoundEffects;
import pr2.runtime.PR2MovieClip;

/**
	Authored mine explosion effect from `effects/MineExplode.as`.
**/
class MineExplosion extends Sprite {
	public static inline var LIFETIME_FRAMES:Int = 14;
	public static inline var SOUND_PATH:String = "assets/audio/sfx/sound971.mp3";

	public var animation(default, null):PR2MovieClip;
	private var framesRemaining:Int = LIFETIME_FRAMES;

	public function new(worldX:Float, worldY:Float, cameraX:Float = 0, cameraY:Float = 0, playSound:Bool = true) {
		super();
		x = worldX;
		y = worldY;
		animation = PR2MovieClip.fromLinkage("MineExplodeAnimation");
		animation.setFrameScript(13, function():Void animation.stop());
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
			removeChild(animation);
			animation = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
