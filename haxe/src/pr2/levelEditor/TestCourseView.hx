package pr2.levelEditor;

import pr2.ui.controls.GameButton;
import pr2.runtime.SvgAsset;
import pr2.ui.view.NativeView;

/** Native in-course overlay actions. */
class TestCourseView extends NativeView {
	public function new() {
		super();
		var background = SvgAsset.create("assets/svg/editor/test_course_background.svg");
		background.name = "background";
		addChild(background);
		button("restart_bt", "Restart", 94, 169);
		button("back_bt", "Back", 153, 169);
	}

	private function button(name:String, label:String, x:Float, y:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(54, 22);
		addChild(control);
	}
}
