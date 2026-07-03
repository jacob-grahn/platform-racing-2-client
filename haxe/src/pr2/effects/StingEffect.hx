package pr2.effects;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.utils.Assets;
import pr2.audio.SoundEffects;
import pr2.character.Character;
import pr2.runtime.PR2MovieClip;

class StingEffect extends Sprite {
	public static inline var SOUND_PATH:String = "assets/audio/sfx/stingSound.wav";

	private var animation:PR2MovieClip;
	private var owner:Character;

	public function new(owner:Character, direction:String = "") {
		super();
		this.owner = owner;
		animation = PR2MovieClip.fromLinkage("StingGraphic", {maxNestedDepth: 4});
		if (direction == "right") {
			removeTimelineChild("leftSting");
		} else if (direction == "left") {
			removeTimelineChild("rightSting");
		}
		addChild(animation);
		pos();
		addEventListener(Event.ENTER_FRAME, tick);
		if (Assets.exists(SOUND_PATH)) {
			SoundEffects.playGameSound(Assets.getSound(SOUND_PATH), x, y, 0, 0, 0.66);
		}
	}

	private function tick(_:Event):Void {
		pos();
		alpha -= 0.05;
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
		owner = null;
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
