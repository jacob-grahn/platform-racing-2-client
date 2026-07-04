package pr2.lobby.dialogs;

import openfl.events.Event;
import openfl.geom.ColorTransform;
import pr2.app.AppStage;
import pr2.display.Removable;
import pr2.runtime.PR2MovieClip;
import pr2.ui.StageFocus;

/**
	Port of Flash `dialogs.Popup`: the base modal overlay.

	Adds a dimming overlay, centers itself on the 550x400 stage, fades in, and
	tracks itself in a global open-popup list. `startFadeOut` fades back out and
	removes. Dialogs add their graphic on top of the overlay. The `LOADED` /
	`REMOVED` events fire at the end of each fade so callers can chain behavior.
**/
class Popup extends Removable {
	public static inline var LOADED:String = "loaded";
	public static inline var REMOVED:String = "removed";

	private static var openPopups:Array<Popup> = [];

	public var fadeOutStarted:Bool = false;

	public function new(addOverlay:Bool = true) {
		super();
		if (addOverlay) {
			var overlay = PR2MovieClip.fromLinkage("Square", {maxNestedDepth: 1});
			overlay.width = 550;
			overlay.height = 400;
			var ct = new ColorTransform();
			ct.color = 0;
			overlay.transform.colorTransform = ct;
			overlay.alpha = 0.55;
			addChild(overlay);
		}
		x = 550 / 2;
		y = 400 / 2;
		alpha = 0;
		if (AppStage.stage != null) {
			AppStage.stage.addChild(this);
		}
		addEventListener(Event.ENTER_FRAME, fadeIn);
		openPopups.push(this);
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
			remove();
			dispatchEvent(new Event(REMOVED));
		}
	}

	public function startFadeOut():Void {
		fadeOutStarted = true;
		removeEventListener(Event.ENTER_FRAME, fadeIn);
		addEventListener(Event.ENTER_FRAME, fadeOut);
	}

	public static function getOpen():Array<Popup> {
		return openPopups;
	}

	override public function remove():Void {
		if (isRemoved()) return;
		openPopups.remove(this);
		removeEventListener(Event.ENTER_FRAME, fadeIn);
		removeEventListener(Event.ENTER_FRAME, fadeOut);
		StageFocus.reset();
		super.remove();
	}
}
