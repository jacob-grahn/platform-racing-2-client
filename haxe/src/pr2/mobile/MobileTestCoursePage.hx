package pr2.mobile;

import pr2.levelEditor.TestCoursePage;

/** Offline test run with the same touch controls used in mobile races. */
class MobileTestCoursePage extends TestCoursePage {
	private var hud:Null<MobileGameHud>;

	public function new(variables:Map<String, String>, mod:Bool = false, report:Bool = false, ?draftSignature:String) {
		super(variables, mod, report, draftSignature);
		fullViewport = true;
	}

	override public function initialize():Void {
		super.initialize();
		if (art != null) art.visible = false;
		if (statsSelect != null) statsSelect.visible = false;
		if (hatPicker != null) hatPicker.visible = false;
		hud = new MobileGameHud(clickBack, function() return false);
		hud.configureEditorTest(clickRestart, toggleStats, toggleHats);
		addChild(hud);
		if (course != null) hud.mount(course);
	}

	override public function clickRestart():Void {
		super.clickRestart();
		if (statsSelect != null) statsSelect.visible = false;
		if (hatPicker != null) hatPicker.visible = false;
		if (hud != null && course != null) hud.mount(course);
	}

	private function toggleStats():Void {
		if (statsSelect != null) statsSelect.visible = !statsSelect.visible;
		if (hatPicker != null) hatPicker.visible = false;
	}
	private function toggleHats():Void {
		if (hatPicker != null) hatPicker.visible = !hatPicker.visible;
		if (statsSelect != null) statsSelect.visible = false;
	}

	override public function remove():Void {
		if (hud != null) { hud.remove(); hud = null; }
		super.remove();
	}
}
