package pr2.effects;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import pr2.character.Character;
import pr2.runtime.PR2MovieClip;

/** Shared authored animation that follows a character and fades itself out. */
class FollowFadeEffect extends Sprite {
	private var animation:Null<PR2MovieClip>;
	private var owner:Null<Character>;
	private final fadePerFrame:Float;

	public function new(owner:Character, linkage:String, fadePerFrame:Float) {
		super();
		this.owner = owner;
		this.fadePerFrame = fadePerFrame;
		animation = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 4});
		addChild(animation);
		positionOnOwner();
		addEventListener(Event.ENTER_FRAME, tick);
	}

	function removeTimelineChild(name:String):Void {
		var child:Null<DisplayObject> = animation == null ? null : animation.getChildByTimelineName(name);
		if (child != null && child.parent != null) child.parent.removeChild(child);
	}

	public function hasTimelineChild(name:String):Bool {
		var child:Null<DisplayObject> = animation == null ? null : animation.getChildByTimelineName(name);
		return child != null && child.parent != null;
	}

	private function tick(_:Event):Void {
		positionOnOwner();
		alpha -= fadePerFrame;
		if (alpha <= 0) remove();
	}

	private function positionOnOwner():Void {
		if (owner == null) return;
		x = owner.x;
		y = owner.y;
	}

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, tick);
		owner = null;
		if (animation != null) {
			animation.dispose();
			if (animation.parent == this) removeChild(animation);
			animation = null;
		}
		if (parent != null) parent.removeChild(this);
	}
}
