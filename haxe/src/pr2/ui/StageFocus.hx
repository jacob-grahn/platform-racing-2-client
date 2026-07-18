package pr2.ui;

import pr2.app.AppStage;
import openfl.display.InteractiveObject;

class StageFocus {
	public static var resetHook:Void->Void = null;
	public static var focusHook:InteractiveObject->Void = null;

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

	public static function focus(target:InteractiveObject):Void {
		if (focusHook != null) {
			focusHook(target);
			return;
		}
		if (AppStage.stage != null) AppStage.stage.focus = target;
	}

	public static function resetHooks():Void {
		resetHook = null;
		focusHook = null;
	}
}
