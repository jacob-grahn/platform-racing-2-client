package pr2.levelEditor;

import openfl.text.TextField;
import pr2.level.BlockType;
import pr2.page.EditorBlockOptions;
import pr2.runtime.FlComponents;
import pr2.runtime.FlSlider;
import pr2.runtime.FlSliderEvent;
import pr2.util.DisplayUtil;

class EditorStatBlockOptionsPopup extends EditorBlockOptionsPopup {
	private var slider:Null<FlSlider>;
	private var statBox:Null<TextField>;

	public function new(editor:LevelEditor, block:EditorBlockObject) {
		super(editor, block, "StatBlockOptionsGraphic");
		slider = Std.downcast(DisplayUtil.findByName(art, "slider"), FlSlider);
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
			slider.minimum = 5;
			slider.maximum = 100;
			slider.snapInterval = 5;
			slider.addEventListener(FlSliderEvent.CHANGE, updateStatDisplay);
			slider.addEventListener(FlSliderEvent.THUMB_DRAG, updateStatDisplay);
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
			slider.removeEventListener(FlSliderEvent.CHANGE, updateStatDisplay);
			slider.removeEventListener(FlSliderEvent.THUMB_DRAG, updateStatDisplay);
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
