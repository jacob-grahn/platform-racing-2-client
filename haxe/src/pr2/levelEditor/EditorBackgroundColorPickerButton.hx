package pr2.levelEditor;

import openfl.events.Event;
import pr2.lobby.account.ColorPicker;
import pr2.ui.StageFocus;

class EditorBackgroundColorPickerButton extends EditorSideBarEntry {
	private final picker:ColorPicker;

	public function new(title:String = "", desc:String = "") {
		super("color", title, desc);
		picker = new ColorPicker();
		picker.name = "colorPicker";
		picker.direction = ColorPicker.LEFT;
		picker.width = 30;
		picker.height = 30;
		picker.addEventListener(Event.CHANGE, liveCommitColor);
		picker.addEventListener(Event.CLOSE, closeCommitColor);
		addChild(picker);
		updateColor();
	}

	public function updateColor():Void {
		var editor = LevelEditor.editor;
		if (editor != null) {
			picker.setColor(editor.color);
		}
	}

	public function setPickedColor(color:Int):Void {
		picker.setColor(color);
		liveCommitColor();
	}

	public function pickerColor():Int {
		return picker.getColor();
	}

	override public function remove():Void {
		picker.removeEventListener(Event.CHANGE, liveCommitColor);
		picker.removeEventListener(Event.CLOSE, closeCommitColor);
		picker.remove();
		super.remove();
	}

	private function liveCommitColor(?_):Void {
		var editor = LevelEditor.editor;
		if (editor != null) {
			editor.setColor(picker.getColor());
		}
	}

	private function closeCommitColor(?_):Void {
		liveCommitColor();
		StageFocus.reset();
	}
}
