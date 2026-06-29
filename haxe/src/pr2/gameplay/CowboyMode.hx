package pr2.gameplay;

import openfl.display.Sprite;
import pr2.runtime.PR2MovieClip;

/** Flash `CowboyMode`: plays the authored animation, then stops on frame 82. */
class CowboyMode extends Sprite {
	private var art:Null<PR2MovieClip>;
	private var stopped:Bool = false;

	public var currentFrame(get, never):Int;

	public function new() {
		super();
		mouseEnabled = false;
		mouseChildren = false;
		art = PR2MovieClip.fromLinkage("CowboyMode", {maxNestedDepth: 4});
		art.setFrameScript(81, stopAnimation);
		addChild(art);
	}

	public function advance():Void {
		if (art != null && !stopped) {
			art.advanceOneFrame();
		}
	}

	private function stopAnimation():Void {
		stopped = true;
		if (art != null) {
			art.stop();
		}
	}

	public function remove():Void {
		if (art != null) {
			art.dispose();
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
