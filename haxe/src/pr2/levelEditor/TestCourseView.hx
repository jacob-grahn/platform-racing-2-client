package pr2.levelEditor;

import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native in-course overlay actions. */
class TestCourseView extends NativeView {
	public function new() {
		super();
		button("back_bt", "Back", -260, -187);
		button("restart_bt", "Restart", 174, -187);
	}

	private function button(name:String, label:String, x:Float, y:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(80, 25);
		addChild(control);
	}
}
