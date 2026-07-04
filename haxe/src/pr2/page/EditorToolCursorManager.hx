package pr2.page;

import com.jiggmin.data.Objects;
import openfl.display.DisplayObject;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.ColorTransform;
import openfl.ui.Keyboard;
import pr2.lobby.Memory;
import pr2.level.ObjectCodes;
import pr2.page.LevelEditor.EditorBlockLayer;
import pr2.runtime.PR2MovieClip;
import pr2.ui.CustomCursor;

typedef EditorToolSelection = {
	final sidebar:String;
	final toolId:String;
}

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
				new EditorGraphicCursor(this, sidebar, toolId, PR2MovieClip.fromLinkage("ObjectDeleterButtonGraphic", {maxNestedDepth: 4}));
			case ["stamps", "text"]:
				new EditorGraphicCursor(this, sidebar, toolId, PR2MovieClip.fromLinkage("TextToolCursorGraphic", {maxNestedDepth: 4}), true, true);
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

class EditorToolCursor extends CustomCursor {
	public final manager:EditorToolCursorManager;
	public final sidebar:String;
	public final toolId:String;
	public final ignoresTemporaryDelete:Bool;

	public function new(manager:EditorToolCursorManager, sidebar:String, toolId:String, ignoresTemporaryDelete:Bool = false) {
		super();
		this.manager = manager;
		this.sidebar = sidebar;
		this.toolId = toolId;
		this.ignoresTemporaryDelete = ignoresTemporaryDelete;
	}

	override function keyDownHandler(e:KeyboardEvent):Void {
		if (e.keyCode == Keyboard.COMMAND || e.keyCode == Keyboard.CONTROL) {
			manager.beginTemporaryDelete();
		}
	}

	override function keyUpHandler(e:KeyboardEvent):Void {
		if (e.keyCode == Keyboard.COMMAND || e.keyCode == Keyboard.CONTROL) {
			manager.endTemporaryDelete();
		}
	}
}

class EditorBrushCursor extends EditorToolCursor {
	public final eraseMode:Bool;

	private var circle:PR2MovieClip;
	private var size:Float = 4;
	private var zoom:Float = 1;

	public function new(manager:EditorToolCursorManager, sidebar:String, toolId:String, eraseMode:Bool) {
		super(manager, sidebar, toolId, true);
		this.eraseMode = eraseMode;
		disposable = false;
		circle = PR2MovieClip.fromLinkage("Circle", {maxNestedDepth: 2});
		applyCursorGraphic(circle);
		setSize(size);
	}

	public function setSize(nextSize:Float):Void {
		size = Math.max(1, nextSize);
		if (circle != null) {
			circle.width = size * zoom;
			circle.height = size * zoom;
		}
	}

	public function setZoom(nextZoom:Float):Void {
		zoom = Math.max(0.01, nextZoom);
		setSize(size);
	}

	public function setColor(color:Int):Void {
		if (circle == null) {
			return;
		}
		var transform = new ColorTransform();
		transform.color = color & 0xFFFFFF;
		circle.transform.colorTransform = transform;
	}

	public function updateVisibilityForStagePoint(stageX:Float, stageY:Float):Void {
		visible = !manager.isOverEditorMenu(stageX, stageY);
	}

	override function mouseMoveHandler(e:MouseEvent):Void {
		super.mouseMoveHandler(e);
		updateVisibilityForStagePoint(e.stageX, e.stageY);
	}

	override public function remove():Void {
		if (circle != null) {
			circle.dispose();
			circle = null;
		}
		super.remove();
	}
}

class EditorGraphicCursor extends EditorToolCursor {
	private var graphic:Null<DisplayObject>;
	private final scaleWithObjectLayer:Bool;
	private final cursorId:Int;

	public function new(manager:EditorToolCursorManager, sidebar:String, toolId:String, graphic:DisplayObject, hideSystemMouse:Bool = false,
			ignoresTemporaryDelete:Bool = false, scaleWithObjectLayer:Bool = false, cursorId:Int = -1) {
		super(manager, sidebar, toolId, ignoresTemporaryDelete);
		this.graphic = graphic;
		this.scaleWithObjectLayer = scaleWithObjectLayer;
		this.cursorId = cursorId;
		applyCursorGraphic(graphic);
		if (hideSystemMouse) {
			hideMouse();
		}
		if (scaleWithObjectLayer) {
			updateObjectLayerScale();
			addEventListener(Event.ENTER_FRAME, updateObjectLayerScale);
		}
	}

	override public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, updateObjectLayerScale);
		var clip = Std.downcast(graphic, PR2MovieClip);
		if (clip != null) {
			clip.dispose();
		}
		graphic = null;
		super.remove();
	}

	override public function getID():Int {
		return cursorId;
	}

	private function updateObjectLayerScale(?_:Event):Void {
		if (!scaleWithObjectLayer) {
			return;
		}
		scaleX = manager.objectCursorScaleX();
		scaleY = manager.objectCursorScaleY();
	}
}
