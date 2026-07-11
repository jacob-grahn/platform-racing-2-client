package pr2.levelEditor;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Point;
import pr2.runtime.FlSlider;
import pr2.runtime.FlSliderEvent;
import pr2.runtime.FlTextInput;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class EditorBrushSizePickerMenu extends Sprite {
	public final editor:LevelEditor;
	public final target:EditorBrushSizePickerButton;
	public final art:PR2MovieClip;
	private var slider:Null<FlSlider>;
	private var textInput:Null<FlTextInput>;

	public function new(editor:LevelEditor, target:EditorBrushSizePickerButton) {
		super();
		this.editor = editor;
		this.target = target;
		art = PR2MovieClip.fromLinkage("SizePickerMenuGraphic", {maxNestedDepth: 6});
		addChild(art);
		var origin = editor.globalToLocal(target.localToGlobal(new Point(0, 0)));
		x = origin.x - 85;
		y = origin.y - 35;
		slider = Std.downcast(DisplayUtil.findByName(art, "slider"), FlSlider);
		textInput = Std.downcast(DisplayUtil.findByName(art, "textBox"), FlTextInput);
		if (slider != null) {
			slider.minimum = 1;
			slider.maximum = 255;
			slider.snapInterval = 1;
			slider.addEventListener(FlSliderEvent.CHANGE, slideChange);
			slider.addEventListener(FlSliderEvent.THUMB_DRAG, slideChange);
		}
		if (textInput != null) {
			textInput.restrict = "0-9";
			textInput.maxChars = 3;
			textInput.addEventListener(Event.CHANGE, textChange);
		}
		setSize(editor.brushSize);
	}

	public function setSize(size:Float):Void {
		if (Math.isNaN(size)) {
			size = EditorDrawableLayer.DEFAULT_BRUSH_SIZE;
		}
		size = Math.max(1, Math.min(255, Math.round(size)));
		editor.setBrushSize(size);
		target.updateCircle();
		if (textInput != null) {
			textInput.text = Std.string(Std.int(editor.brushSize));
		}
		if (slider != null) {
			slider.value = editor.brushSize;
		}
	}

	public function remove():Void {
		if (slider != null) {
			slider.removeEventListener(FlSliderEvent.CHANGE, slideChange);
			slider.removeEventListener(FlSliderEvent.THUMB_DRAG, slideChange);
			slider = null;
		}
		if (textInput != null) {
			textInput.removeEventListener(Event.CHANGE, textChange);
			textInput = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
		art.dispose();
		editor.brushSizeMenuRemoved(this);
		if (editor.stage != null) {
			editor.stage.focus = editor.stage;
		}
	}

	private function slideChange(event:FlSliderEvent):Void {
		setSize(event.value);
	}

	private function textChange(_:Event):Void {
		if (textInput == null) {
			return;
		}
		var parsed = Std.parseFloat(textInput.text);
		setSize(Math.isNaN(parsed) ? EditorDrawableLayer.DEFAULT_BRUSH_SIZE : parsed);
	}
}
