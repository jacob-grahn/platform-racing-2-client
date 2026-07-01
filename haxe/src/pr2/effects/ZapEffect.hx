package pr2.effects;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.utils.Assets;
import pr2.audio.SoundEffects;
import pr2.character.Character;
import pr2.runtime.PR2MovieClip;

/**
	Port of `effects.Zap`: an authored flash/bolt effect that follows a character
	and fades out over ten frames.
**/
class ZapEffect extends Sprite {
	public static inline var SOUND_PATH:String = "assets/audio/sfx/sound914.mp3";

	private var animation:PR2MovieClip;
	private var owner:Character;

	public function new(owner:Character, showBolt:Bool = true, playSound:Bool = true, showFlash:Bool = true) {
		super();
		this.owner = owner;
		animation = PR2MovieClip.fromLinkage("ZapGraphic", {maxNestedDepth: 4});
		if (!showBolt) {
			removeTimelineChild("lightning");
		}
		if (!showFlash) {
			removeTimelineChild("bg");
		}
		addChild(animation);
		pos();
		addEventListener(Event.ENTER_FRAME, tick);

		if (playSound && Assets.exists(SOUND_PATH)) {
			SoundEffects.playSound(Assets.getSound(SOUND_PATH));
		}
	}

	private function tick(_:Event):Void {
		pos();
		alpha -= 0.1;
		if (alpha <= 0) {
			remove();
		}
	}

	private function pos():Void {
		if (owner == null) {
			return;
		}
		x = owner.x;
		y = owner.y;
	}

	private function removeTimelineChild(name:String):Void {
		var child:Null<DisplayObject> = animation.getChildByTimelineName(name);
		if (child != null && child.parent != null) {
			child.parent.removeChild(child);
		}
	}

	public function hasTimelineChild(name:String):Bool {
		var child:Null<DisplayObject> = animation == null ? null : animation.getChildByTimelineName(name);
		return child != null && child.parent != null;
	}

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, tick);
		if (animation != null) {
			animation.dispose();
			removeChild(animation);
			animation = null;
		}
		owner = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
