package pr2.levelEditor;

import com.jiggmin.data.Objects;
import pr2.lobby.Memory;
import pr2.ui.CustomCursor;

class EditorToolCursorManager {
	public var current(default, null):Null<EditorToolCursor>;

	private final editor:LevelEditor;
	private var temporarySelection:Null<EditorToolSelection>;

	public function new(editor:LevelEditor) {
		this.editor = editor;
	}

	public function select(sidebar:String, toolId:String, manual:Bool = true):Void {
		if (manual) {
			temporarySelection = null;
		}
		var next = createCursor(sidebar, toolId);
		if (next == null) {
			CustomCursor.unsetInstance();
			current = null;
			return;
		}
		current = next;
		CustomCursor.change(next);
		applyBrushState();
	}

	public function setBrushSize(_:Float):Void {
		applyBrushState();
	}

	public function setBrushColor(_:Int):Void {
		applyBrushState();
	}

	public function setZoom(_:Float):Void {
		applyBrushState();
	}

	public function setBrushDrawing(drawing:Bool):Void {
		var brush = Std.downcast(current, EditorBrushCursor);
		if (brush != null) {
			brush.setDrawing(drawing);
		}
	}

	public function pause():Void {
		CustomCursor.pauseCurrent();
	}

	public function init():Void {
		CustomCursor.initCurrent();
	}

	public function remove():Void {
		CustomCursor.unsetInstance();
		current = null;
		temporarySelection = null;
	}

	public function isOverEditorMenu(stageX:Float, stageY:Float):Bool {
		return editor.isPointOverMenu(stageX, stageY);
	}

	public function objectCursorScaleX():Float {
		return editor.scaleX * (editor.activeObjectLayer == null ? 1 : editor.activeObjectLayer.scaleX);
	}

	public function objectCursorScaleY():Float {
		return editor.scaleY * (editor.activeObjectLayer == null ? 1 : editor.activeObjectLayer.scaleY);
	}

	public function beginTemporaryDelete():Void {
		if (current == null || current.ignoresTemporaryDelete || current.toolId == "delete" || editor.selectedToolId == "delete") {
			return;
		}
		if (temporarySelection == null) {
			temporarySelection = {sidebar: editor.selectedToolSidebar, toolId: editor.selectedToolId};
			Memory.set("leCursorTempInstanceType", Type.getClassName(Type.getClass(current)));
			Memory.set("leCursorTempInstanceID", current.getID());
			Memory.set("leCursorTempSidebar", editor.selectedToolSidebar);
			Memory.set("leCursorTempToolId", editor.selectedToolId);
		}
		var deleteSidebar = current.sidebar == "blocks" ? "blocks" : "stamps";
		editor.selectEditorToolFromCursor(deleteSidebar, "delete");
		select(deleteSidebar, "delete", false);
	}

	public function endTemporaryDelete():Void {
		if (temporarySelection == null && Memory.has("leCursorTempSidebar") && Memory.has("leCursorTempToolId")) {
			temporarySelection = {sidebar: Memory.getString("leCursorTempSidebar"), toolId: Memory.getString("leCursorTempToolId")};
		}
		if (temporarySelection == null) {
			return;
		}
		var restore = temporarySelection;
		temporarySelection = null;
		clearTemporaryDeleteMemory();
		editor.selectEditorToolFromCursor(restore.sidebar, restore.toolId);
		select(restore.sidebar, restore.toolId, false);
	}

	private function clearTemporaryDeleteMemory():Void {
		Memory.remove("leCursorTempInstanceType");
		Memory.remove("leCursorTempInstanceID");
		Memory.remove("leCursorTempSidebar");
		Memory.remove("leCursorTempToolId");
	}

	private function applyBrushState():Void {
		var brush = Std.downcast(current, EditorBrushCursor);
		if (brush == null) {
			return;
		}
		brush.setSize(editor.brushSize);
		brush.setZoom(editor.zoom);
		brush.setColor(brush.eraseMode ? 0xFFFFFF : editor.brushColor);
	}

	private function createCursor(sidebar:String, toolId:String):Null<EditorToolCursor> {
		return switch [sidebar, toolId] {
			case ["tools", "brush"]:
				new EditorBrushCursor(this, sidebar, toolId, false);
			case ["tools", "eraser"]:
				new EditorBrushCursor(this, sidebar, toolId, true);
			case ["stamps", "delete"] | ["blocks", "delete"]:
				new EditorGraphicCursor(this, sidebar, toolId, new EditorNativeGraphic("ObjectDeleterButtonGraphic"));
			case ["stamps", "text"]:
				new EditorGraphicCursor(this, sidebar, toolId, new EditorNativeGraphic("TextToolCursorGraphic"), true, true);
			case ["stamps", id] if (StringTools.startsWith(id, "stamp")):
				var code = Std.parseInt(id.substr("stamp".length));
				code == null ? null : objectCursor(sidebar, toolId, code, true);
			case ["blocks", id]:
				var spec = EditorBlockLayer.specForTool(id);
				spec == null ? null : objectCursor(sidebar, toolId, spec.code, false);
			default:
				null;
		}
	}

	private function objectCursor(sidebar:String, toolId:String, code:Int, scaleWithObjectLayer:Bool):Null<EditorToolCursor> {
		try {
			var graphic = Objects.getFromCode(code);
			if (graphic == null) {
				return null;
			}
			graphic.alpha = 0.5;
			return new EditorGraphicCursor(this, sidebar, toolId, graphic, false, false, scaleWithObjectLayer, code);
		} catch (_:Dynamic) {
			return null;
		}
	}
}
