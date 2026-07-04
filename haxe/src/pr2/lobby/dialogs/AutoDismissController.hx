package pr2.lobby.dialogs;

import haxe.Timer;
import openfl.display.DisplayObject;
import openfl.events.MouseEvent;
import pr2.app.AppStage;

class AutoDismissController {
	private final owner:DisplayObject;
	private final removeOwner:Void->Void;
	private var armTimer:Null<Timer>;
	private var armed:Bool = false;
	private var removed:Bool = false;

	public function new(owner:DisplayObject, removeOwner:Void->Void) {
		this.owner = owner;
		this.removeOwner = removeOwner;
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
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
		}
		armed = false;
	}

	public function stageMouseDownForTests(stageX:Float, stageY:Float):Void {
		if (!owner.hitTestPoint(stageX, stageY, true)) {
			removeOwner();
		}
	}

	private function arm():Void {
		armTimer = null;
		if (removed || armed || AppStage.stage == null) {
			return;
		}
		armed = true;
		AppStage.stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
	}

	private function onStageMouseDown(event:MouseEvent):Void {
		stageMouseDownForTests(event.stageX, event.stageY);
	}
}
