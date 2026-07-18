package pr2.gameplay;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.effects.NativeEffectAnimation;

/** Flash `HappyHour`: plays the authored animation, then removes itself. */
class HappyHour extends Sprite {
	private var art:Null<NativeEffectAnimation>;
	private var frame:Int = 1;
	private var removed:Bool = false;
	private var onRemoved:Null<HappyHour->Void>;

	public var currentFrame(get, never):Int;

	public function new(?onRemoved:HappyHour->Void) {
		super();
		this.onRemoved = onRemoved;
		mouseEnabled = false;
		mouseChildren = false;
		art = new NativeEffectAnimation("happy_hour", 100);
		art.addEventListener(Event.ENTER_FRAME, onFrame);
		addChild(art);
	}

	public function advance():Void {
		if (art == null) return;
		art.advanceOneFrame();
		processCurrentFrame();
	}

	private function onFrame(_:Event):Void processCurrentFrame();
	private function processCurrentFrame():Void {
		if (art == null || removed) return;
		frame = art.currentFrame;
		if (frame >= 100) finishAnimation();
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
			art.removeEventListener(Event.ENTER_FRAME, onFrame);
			art.dispose();
			if (art.parent != null) art.parent.removeChild(art);
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
		return art == null ? 0 : frame;
	}
}
