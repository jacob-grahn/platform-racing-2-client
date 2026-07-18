package pr2.lobby.dialogs;

import haxe.Timer;
import openfl.display.DisplayObject;
import openfl.events.MouseEvent;
import pr2.app.AppStage;

class AutoDismissController {
	private static inline var CAPTURE_PRIORITY:Int = 1000;
	private final owner:DisplayObject;
	private final removeOwner:Void->Void;
	private final canDismiss:Void->Bool;
	private var armTimer:Null<Timer>;
	private var armed:Bool = false;
	private var removed:Bool = false;

	public function new(owner:DisplayObject, removeOwner:Void->Void, ?canDismiss:Void->Bool) {
		this.owner = owner;
		this.removeOwner = removeOwner;
		this.canDismiss = canDismiss == null ? function() return true : canDismiss;
		armTimer = Timer.delay(arm, 25);
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		if (armTimer != null) {
			armTimer.stop();
			armTimer = null;
		}
		if (armed && AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown, true);
		}
		armed = false;
	}

	public function stageMouseDownForTests(stageX:Float, stageY:Float):Void {
		if (canDismiss() && !owner.hitTestPoint(stageX, stageY, true)) {
			removeOwner();
		}
	}

	public function dispatchStageMouseDownForTests(stageX:Float, stageY:Float):Void {
		if (armed) {
			stageMouseDownForTests(stageX, stageY);
		}
	}

	public function isArmedForTests():Bool {
		return armed;
	}

	public function armForTests():Void {
		if (removed || armed) {
			return;
		}
		if (armTimer != null) {
			armTimer.stop();
			armTimer = null;
		}
		armed = true;
		if (AppStage.stage != null) {
			AppStage.stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown, true, CAPTURE_PRIORITY);
		}
	}

	private function arm():Void {
		armTimer = null;
		if (removed || armed || AppStage.stage == null) {
			return;
		}
		armed = true;
		AppStage.stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown, true, CAPTURE_PRIORITY);
	}

	private function onStageMouseDown(event:MouseEvent):Void {
		if (isOwnerOrDescendant(event.target)) {
			return;
		}
		stageMouseDownForTests(event.stageX, event.stageY);
	}

	private function isOwnerOrDescendant(target:Dynamic):Bool {
		var current = Std.downcast(target, DisplayObject);
		while (current != null) {
			if (current == owner) return true;
			current = current.parent;
		}
		return false;
	}
}
