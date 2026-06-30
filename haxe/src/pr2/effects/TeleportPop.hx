package pr2.effects;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.utils.Assets;
import pr2.audio.SoundEffects;
import pr2.runtime.PR2MovieClip;

/**
	Port of `effects.TeleportPop`: the 15-frame authored teleport poof and sound.
**/
class TeleportPop extends Sprite {
	public static inline var LIFETIME_FRAMES:Int = 15;
	public static inline var SOUND_PATH:String = "assets/audio/sfx/sound1110.mp3";

	private var animation:PR2MovieClip;
	private var framesRemaining:Int = LIFETIME_FRAMES;

	public function new(worldX:Float, worldY:Float, cameraX:Float = 0, cameraY:Float = 0, playSound:Bool = true) {
		super();
		x = worldX;
		y = worldY;
		animation = PR2MovieClip.fromLinkage("TeleportEffectGraphic", {maxNestedDepth: 3});
		addChild(animation);
		addEventListener(Event.ENTER_FRAME, tick);

		if (playSound && Assets.exists(SOUND_PATH)) {
			SoundEffects.playGameSound(Assets.getSound(SOUND_PATH), worldX, worldY, cameraX, cameraY, 0.66);
		}
	}

	private function tick(_:Event):Void {
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
