package pr2.mobile;

import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.TouchEvent;
import openfl.geom.Point;

/** One independently captured finger per control; release always follows the finger. */
class MobileHoldControl extends Sprite {
	public var onHold:Bool->Float->Float->Void;
	public var active(default, null):Bool = false;
	private var touchId:Null<Int>;
	private var ownerStage:Stage;
	private var lastTouch:Float = -10;
	public function new() {
		super(); mouseChildren = false; buttonMode = true;
		addEventListener(TouchEvent.TOUCH_BEGIN, touchBegin);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseBegin);
		addEventListener(Event.REMOVED_FROM_STAGE, removed);
	}
	private function capture():Void {
		ownerStage = stage;
		if (ownerStage == null) return;
		ownerStage.addEventListener(TouchEvent.TOUCH_MOVE, touchMove);
		ownerStage.addEventListener(TouchEvent.TOUCH_END, touchEnd);
		ownerStage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		ownerStage.addEventListener(MouseEvent.MOUSE_UP, mouseEnd);
		ownerStage.addEventListener(Event.DEACTIVATE, removed);
		ownerStage.addEventListener(Event.MOUSE_LEAVE, mouseLeave);
	}
	private function update(sx:Float, sy:Float):Void {
		var p = globalToLocal(new Point(sx, sy));
		if (onHold != null) onHold(true, p.x, p.y);
	}
	private function touchBegin(e:TouchEvent):Void {
		lastTouch = haxe.Timer.stamp();
		if (active) return;
		touchId = e.touchPointID; active = true; capture(); update(e.stageX, e.stageY);
		e.stopPropagation();
	}
	private function touchMove(e:TouchEvent):Void { if (active && touchId == e.touchPointID) update(e.stageX, e.stageY); }
	private function touchEnd(e:TouchEvent):Void { if (active && touchId == e.touchPointID) { lastTouch = haxe.Timer.stamp(); release(); } }
	private function mouseBegin(e:MouseEvent):Void {
		if (active || haxe.Timer.stamp() - lastTouch < .8) return;
		touchId = null; active = true; capture(); update(e.stageX, e.stageY); e.stopPropagation();
	}
	private function mouseMove(e:MouseEvent):Void { if (active && touchId == null) update(e.stageX, e.stageY); }
	private function mouseEnd(_:MouseEvent):Void { if (touchId == null) release(); }
	private function mouseLeave(_:Event):Void { if (touchId == null) release(); }
	private function removed(_:Event):Void release();
	public function release():Void {
		var wasActive = active; active = false; touchId = null;
		if (ownerStage != null) {
			ownerStage.removeEventListener(TouchEvent.TOUCH_MOVE, touchMove);
			ownerStage.removeEventListener(TouchEvent.TOUCH_END, touchEnd);
			ownerStage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			ownerStage.removeEventListener(MouseEvent.MOUSE_UP, mouseEnd);
			ownerStage.removeEventListener(Event.DEACTIVATE, removed);
			ownerStage.removeEventListener(Event.MOUSE_LEAVE, mouseLeave);
			ownerStage = null;
		}
		if (wasActive && onHold != null) onHold(false, 0, 0);
	}
	public function dispose():Void {
		release(); onHold = null;
		removeEventListener(TouchEvent.TOUCH_BEGIN, touchBegin);
		removeEventListener(MouseEvent.MOUSE_DOWN, mouseBegin);
		removeEventListener(Event.REMOVED_FROM_STAGE, removed);
	}
}
