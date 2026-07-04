package pr2.lobby.dialogs;

import pr2.ui.StageFocus;

class AutoDismissPopup extends InfoPopup {
	private var autoDismiss:Null<AutoDismissController>;

	public function new() {
		super();
		autoDismiss = new AutoDismissController(this, remove);
	}

	public function autoDismissArmedForTests():Bool {
		return autoDismiss != null && autoDismiss.isArmedForTests();
	}

	public function armAutoDismissForTests():Void {
		if (autoDismiss != null) {
			autoDismiss.armForTests();
		}
	}

	public function stageMouseDownForTests(stageX:Float, stageY:Float):Void {
		if (autoDismiss != null) {
			autoDismiss.dispatchStageMouseDownForTests(stageX, stageY);
		}
	}

	override public function remove():Void {
		if (autoDismiss != null) {
			autoDismiss.remove();
			autoDismiss = null;
		}
		StageFocus.reset();
		super.remove();
	}
}
