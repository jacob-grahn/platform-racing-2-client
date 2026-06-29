package pr2.gameplay;

import openfl.display.Sprite;
import pr2.runtime.PR2MovieClip;

/** Flash `HappyHour`: plays the authored animation, then removes itself. */
class HappyHour extends Sprite {
	private var art:Null<PR2MovieClip>;
	private var removed:Bool = false;
	private var onRemoved:Null<HappyHour->Void>;

	public var currentFrame(get, never):Int;

	public function new(?onRemoved:HappyHour->Void) {
		super();
		this.onRemoved = onRemoved;
		mouseEnabled = false;
		mouseChildren = false;
		art = PR2MovieClip.fromLinkage("HappyHour", {maxNestedDepth: 4});
		art.setFrameScript(99, finishAnimation);
		addChild(art);
	}

	public function advance():Void {
		if (art != null && !removed) {
			art.advanceOneFrame();
		}
	}

	private function finishAnimation():Void {
		remove();
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
		if (onRemoved != null) {
			onRemoved(this);
			onRemoved = null;
		}
	}

	private function get_currentFrame():Int {
		return art == null ? 0 : art.currentFrame;
	}
}
