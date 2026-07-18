package pr2.ui.view;

import openfl.events.Event;
import pr2.Constants;

/** Exact dialogs.Popup fade/overlay lifecycle for centered native popup roots. */
class NativePopupView extends NativeView {
	public static inline var LOADED:String = "loaded";
	public static inline var REMOVED:String = "removed";
	public var fadeOutStarted(default, null):Bool = false;

	public function new(addOverlay:Bool = true, animateLifecycle:Bool = true) {
		super();
		if (addOverlay) {
			graphics.beginFill(0x000000, 0.55);
			graphics.drawRect(-Constants.STAGE_WIDTH / 2, -Constants.STAGE_HEIGHT / 2, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
			graphics.endFill();
		}
		alpha = animateLifecycle ? 0 : 1;
		if (animateLifecycle) addEventListener(Event.ENTER_FRAME, fadeIn);
	}

	public function startFadeOut():Void {
		if (fadeOutStarted || disposed) return;
		fadeOutStarted = true;
		removeEventListener(Event.ENTER_FRAME, fadeIn);
		addEventListener(Event.ENTER_FRAME, fadeOut);
	}

	private function fadeIn(_:Event):Void {
		alpha += 0.15;
		if (alpha >= 1) {
			alpha = 1;
			removeEventListener(Event.ENTER_FRAME, fadeIn);
			dispatchEvent(new Event(LOADED));
		}
	}

	private function fadeOut(_:Event):Void {
		alpha -= 0.15;
		if (alpha <= 0) {
			dispose();
			dispatchEvent(new Event(REMOVED));
		}
	}

	override public function dispose():Void {
		removeEventListener(Event.ENTER_FRAME, fadeIn);
		removeEventListener(Event.ENTER_FRAME, fadeOut);
		super.dispose();
	}
}
