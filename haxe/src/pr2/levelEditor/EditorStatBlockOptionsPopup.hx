package pr2.levelEditor;

import openfl.text.TextField;
import pr2.level.BlockType;
import pr2.page.EditorBlockOptions;
import pr2.runtime.FlComponents;
import openfl.events.Event;
import pr2.ui.controls.GameSlider;
import pr2.util.DisplayUtil;

class EditorStatBlockOptionsPopup extends EditorBlockOptionsPopup {
	private var slider:Null<GameSlider>;
	private var statBox:Null<TextField>;

	public function new(editor:LevelEditor, block:EditorBlockObject) {
		super(editor, block, "StatBlockOptionsGraphic");
		slider = Std.downcast(DisplayUtil.findByName(art, "slider"), GameSlider);
		statBox = FlComponents.asTextField(DisplayUtil.findByName(art, "statBox"));
		var titleBox = FlComponents.asTextField(DisplayUtil.findByName(art, "titleBox"));
		var descBox = FlComponents.asTextField(DisplayUtil.findByName(art, "descBox"));
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
