package pr2.effects;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import pr2.character.Character;
import pr2.runtime.SvgAsset;

/** Shared authored animation that follows a character and fades itself out. */
class FollowFadeEffect extends Sprite {
	private var animation:Null<Sprite>;
	private final timelineChildren:Map<String, DisplayObject> = [];
	private var owner:Null<Character>;
	private final fadePerFrame:Float;

	public function new(owner:Character, linkage:String, fadePerFrame:Float) {
		super();
		this.owner = owner;
		this.fadePerFrame = fadePerFrame;
		animation = buildAnimation(linkage);
		addChild(animation);
		positionOnOwner();
		addEventListener(Event.ENTER_FRAME, tick);
	}

	function removeTimelineChild(name:String):Void {
		var child = timelineChildren.get(name);
		if (child != null && child.parent != null) child.parent.removeChild(child);
	}

	public function hasTimelineChild(name:String):Bool {
		var child = timelineChildren.get(name);
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
			if (animation.parent == this) removeChild(animation);
			animation = null;
		}
		timelineChildren.clear();
		if (parent != null) parent.removeChild(this);
	}

	private function buildAnimation(linkage:String):Sprite {
		var root = new Sprite();
		switch (linkage) {
			case "ZapGraphic":
				addSvg(root, "bg", "assets/svg/effects/lightning_flash.svg", -550, -401, 6.3218231201171875, 2.285614013671875);
				addSvg(root, "lightning", "assets/svg/effects/lightning_strike.svg", -0.2, 1.35, 1, 1);
			case "StingGraphic":
				addSvg(root, "rightSting", "assets/svg/effects/sting_ray.svg", 10, -20, 0.4640350341796875, 0.463531494140625);
				addSvg(root, "leftSting", "assets/svg/effects/sting_ray.svg", -10, -20, -0.4640350341796875, 0.463531494140625);
			default:
				throw 'Unsupported native follow/fade effect: $linkage';
		}
		return root;
	}

	private function addSvg(root:Sprite, name:String, path:String, x:Float, y:Float, scaleX:Float, scaleY:Float):Void {
		var child = SvgAsset.create(path);
		child.name = name;
		child.x = x;
		child.y = y;
		child.scaleX = scaleX;
		child.scaleY = scaleY;
		root.addChild(child);
		timelineChildren.set(name, child);
	}
}
