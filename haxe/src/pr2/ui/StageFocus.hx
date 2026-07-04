package pr2.ui;

import pr2.app.AppStage;

class StageFocus {
	public static var resetHook:Void->Void = null;

	private function new() {}

	public static function reset():Void {
		if (resetHook != null) {
			resetHook();
			return;
		}
		if (AppStage.stage != null) {
			AppStage.stage.focus = AppStage.stage;
		}
	}

	public static function resetHooks():Void {
		resetHook = null;
	}
}
