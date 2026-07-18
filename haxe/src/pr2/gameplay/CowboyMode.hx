package pr2.gameplay;

import openfl.display.Sprite;
import pr2.effects.NativeEffectAnimation;

/** Flash `CowboyMode`: plays the authored animation, then stops on frame 82. */
class CowboyMode extends Sprite {
	private var art:Null<NativeEffectAnimation>;

	public var currentFrame(get, never):Int;

	public function new() {
		super();
		mouseEnabled = false;
		mouseChildren = false;
		art = new NativeEffectAnimation("cowboy", 82);
		addChild(art);
	}

	public function advance():Void {
		if (art != null) art.advanceOneFrame();
	}

	public function remove():Void {
		if (art != null) {
			art.dispose();
			if (art.parent != null) art.parent.removeChild(art);
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function get_currentFrame():Int {
		return art == null ? 0 : art.currentFrame;
	}
}
