package pr2.levelEditor;

import openfl.text.TextField;
import pr2.level.BlockType;
import pr2.page.EditorBlockOptions;
import openfl.events.Event;
import pr2.ui.controls.GameSlider;

class EditorStatBlockOptionsPopup extends EditorBlockOptionsPopup {
	private var slider:Null<GameSlider>;
	private var statBox:Null<TextField>;

	public function new(editor:LevelEditor, block:EditorBlockObject) {
		super(editor, block, "StatBlockOptionsGraphic");
		slider = Std.downcast(art.childNamed("slider"), GameSlider);
		statBox = Std.downcast(art.childNamed("statBox"), TextField);
		var titleBox = Std.downcast(art.childNamed("titleBox"), TextField);
		var descBox = Std.downcast(art.childNamed("descBox"), TextField);
		var happy = block.type == BlockType.Happy;
		if (titleBox != null) {
			titleBox.text = happy ? "-- Happy Block --" : "-- Sad Block --";
		}
		if (descBox != null) {
			descBox.text = "All the stats of players that bump this block will be " + (happy ? "increased" : "decreased") + " by:";
		}
		if (slider != null) {
			slider.addEventListener(Event.CHANGE, updateStatDisplay);
		}
		setStatMagnitude(Std.int(Math.abs(EditorBlockOptions.statChange(block.type, block.options))));
	}

	public function setStatMagnitude(value:Int):Void {
		if (slider != null) {
			slider.value = value;
			updateStatDisplay();
		} else if (statBox != null) {
			statBox.text = Std.string(value);
		}
	}

	override public function remove():Void {
		if (slider != null) {
			slider.removeEventListener(Event.CHANGE, updateStatDisplay);
		}
		var magnitude = slider == null ? Std.int(Math.abs(EditorBlockOptions.statChange(block.type, block.options))) : Std.int(Math.round(slider.value));
		block.setOptions(EditorBlockOptions.applyStatChange(block.type, block.type == BlockType.Sad ? -magnitude : magnitude));
		super.remove();
	}

	private function updateStatDisplay(?_):Void {
		if (slider != null && statBox != null) {
			statBox.text = Std.string(Std.int(Math.round(slider.value)));
		}
	}
}
