package pr2.levelEditor;

import openfl.events.Event;
import pr2.app.AppStage;
import pr2.lobby.account.ColorPicker;

class EditorBrushColorPickerButton extends EditorSideBarEntry {
	private final picker:ColorPicker;

	public function new(title:String = "", desc:String = "") {
		super("color", title, desc);
		picker = new ColorPicker();
		picker.name = "brushColorPicker";
		picker.width = 30;
		picker.height = 30;
		picker.addEventListener(Event.CHANGE, commitColor);
		addChild(picker);
		updateColor();
	}

	public function updateColor():Void {
		var editor = LevelEditor.editor;
		if (editor != null) {
			picker.setColor(editor.brushColor);
		}
	}

	public function setPickedColor(color:Int):Void {
		picker.setColor(color);
		commitColor();
	}

	public function pickerColor():Int {
		return picker.getColor();
	}

	override public function remove():Void {
		picker.removeEventListener(Event.CHANGE, commitColor);
		picker.remove();
		super.remove();
	}

	private function commitColor(?_):Void {
		var editor = LevelEditor.editor;
		if (editor != null) {
			editor.setBrushColor(picker.getColor());
		}
		if (AppStage.stage != null) {
			AppStage.stage.focus = AppStage.stage;
		}
	}
}
