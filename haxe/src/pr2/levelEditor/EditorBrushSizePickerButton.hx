package pr2.levelEditor;

import openfl.display.DisplayObject;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class EditorBrushSizePickerButton extends EditorSideBarEntry {
	private final art:PR2MovieClip;
	private var circle:Null<DisplayObject>;

	public function new(title:String = "", desc:String = "") {
		super("size", title, desc);
		art = PR2MovieClip.fromLinkage("SizePickerGraphic", {maxNestedDepth: 4});
		art.mouseEnabled = false;
		art.mouseChildren = false;
		addChild(art);
		circle = Std.downcast(DisplayUtil.findByName(art, "circle"), DisplayObject);
		updateCircle();
	}

	public function openMenu():Void {
		var editor = LevelEditor.editor;
		if (editor != null) {
			editor.openBrushSizeMenu(this);
		}
	}

	public function setPickedSize(size:Float):Void {
		var editor = LevelEditor.editor;
		if (editor != null) {
			editor.setBrushSize(size);
		}
		updateCircle();
	}

	public function updateCircle():Void {
		if (circle == null) {
			return;
		}
		var editor = LevelEditor.editor;
		var size = editor == null ? EditorDrawableLayer.DEFAULT_BRUSH_SIZE : editor.brushSize;
		circle.width = Math.sqrt(size) * 3;
		circle.height = Math.sqrt(size) * 3;
	}

	override public function remove():Void {
		var editor = LevelEditor.editor;
		if (editor != null && editor.activeBrushSizeMenu != null) {
			editor.closeBrushSizeMenu();
		}
		art.dispose();
		super.remove();
	}
}
