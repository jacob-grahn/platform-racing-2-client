package pr2.levelEditor;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Point;
import pr2.lobby.dialogs.AutoDismissController;
import pr2.ui.controls.GameSlider;
import pr2.ui.controls.GameTextInput;
import pr2.util.DisplayUtil;

class EditorBrushSizePickerMenu extends Sprite {
	public final editor:LevelEditor;
	public final target:EditorBrushSizePickerButton;
	public final art:BrushSizeMenuView;
	private var slider:Null<GameSlider>;
	private var textInput:Null<GameTextInput>;
	private var autoDismiss:Null<AutoDismissController>;
	private var removed:Bool = false;

	public function new(editor:LevelEditor, target:EditorBrushSizePickerButton) {
		super();
		this.editor = editor;
		this.target = target;
		art = new BrushSizeMenuView();
		addChild(art);
		var origin = editor.globalToLocal(target.localToGlobal(new Point(0, 0)));
		x = origin.x - 85;
		y = origin.y - 35;
		slider = art.slider;
		textInput = art.textInput;
		if (slider != null) {
			slider.addEventListener(Event.CHANGE, slideChange);
		}
		if (textInput != null) {
			textInput.textField.restrict = "0-9";
			textInput.textField.maxChars = 3;
			textInput.textField.addEventListener(Event.CHANGE, textChange);
		}
		setSize(editor.brushSize);
		autoDismiss = new AutoDismissController(this, remove);
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
		if (removed) {
			return;
		}
		removed = true;
		if (autoDismiss != null) {
			autoDismiss.remove();
			autoDismiss = null;
		}
		if (slider != null) {
			slider.removeEventListener(Event.CHANGE, slideChange);
			slider = null;
		}
		if (textInput != null) {
			textInput.textField.removeEventListener(Event.CHANGE, textChange);
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

	private function slideChange(_:Event):Void {
		if (slider != null) setSize(slider.value);
	}

	private function textChange(_:Event):Void {
		if (textInput == null) {
			return;
		}
		var parsed = Std.parseFloat(textInput.text);
		setSize(Math.isNaN(parsed) ? EditorDrawableLayer.DEFAULT_BRUSH_SIZE : parsed);
	}
}
