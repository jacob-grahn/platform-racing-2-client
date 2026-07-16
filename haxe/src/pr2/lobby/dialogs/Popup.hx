package pr2.lobby.dialogs;

import openfl.events.Event;
import openfl.display.Shape;
import pr2.app.AppStage;
import pr2.display.Removable;
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
	private var overlay:Null<Shape>;

	public function new(addOverlay:Bool = true) {
		super();
		if (addOverlay) {
			overlay = new Shape();
			overlay.graphics.beginFill(0x000000);
			overlay.graphics.drawRect(0, 0, 550, 400);
			overlay.graphics.endFill();
			overlay.x = -275;
			overlay.y = -200;
			overlay.alpha = 0.55;
			addChild(overlay);
		}
		x = 550 / 2;
		y = 400 / 2;
		alpha = 0;
		if (AppStage.stage != null) {
			AppStage.stage.addChild(this);
			AppStage.stage.addEventListener(Event.RESIZE, onStageResize);
		}
		layoutForStage();
		addEventListener(Event.ENTER_FRAME, fadeIn);
		openPopups.push(this);
	}

	/** Keep authored dialogs centered and comfortably sized in the mobile shell. */
	private function onStageResize(_:Event):Void layoutForStage();

	private function layoutForStage():Void {
		if (AppStage.stage == null) return;
		var stageW = AppStage.stage.stageWidth;
		var stageH = AppStage.stage.stageHeight;
		var density = Math.max(1, Math.min(stageW / 550, stageH / 400));
		scaleX = scaleY = density;
		x = stageW / 2;
		y = stageH / 2;
		if (overlay != null) {
			overlay.width = stageW / density;
			overlay.height = stageH / density;
			overlay.x = -overlay.width / 2;
			overlay.y = -overlay.height / 2;
		}
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
		if (AppStage.stage != null) AppStage.stage.removeEventListener(Event.RESIZE, onStageResize);
		removeEventListener(Event.ENTER_FRAME, fadeIn);
		removeEventListener(Event.ENTER_FRAME, fadeOut);
		StageFocus.reset();
		super.remove();
	}
}
