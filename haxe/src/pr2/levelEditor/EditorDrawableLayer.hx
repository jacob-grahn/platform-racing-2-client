package pr2.levelEditor;

import openfl.display.Sprite;
import openfl.geom.Point;
import pr2.level.ServerLevel.DecodedDrawAction;
import pr2.level.ServerLevelDecoder;
import pr2.level.ServerLevelRenderer;

class EditorDrawableLayer extends Sprite {
	public static inline var DEFAULT_BRUSH_SIZE:Float = 4;
	private static inline var BRUSH_RESTART_DISTANCE:Float = 400;

	public final layerNum:Int;
	public final layerScale:Float;
	public final saveArray:Array<String> = [];
	public final redoArray:Array<String> = [];
	public final drawActions:Array<DecodedDrawAction> = [];
	public final rasterCanvas:Sprite;
	public final brushCanvas:Sprite;
	private var color:Int = 0;
	private var brushSize:Float = DEFAULT_BRUSH_SIZE;
	private var mode:String = "draw";
	private var brushX:Float = 0;
	private var brushY:Float = 0;
	private var strokeStartX:Float = 0;
	private var strokeStartY:Float = 0;
	private var drawing:Bool = false;
	private var drawRasterizeCount:Int = 0;
	private var eraseCleanupCount:Int = 0;

	public function new(layerNum:Int, layerScale:Float) {
		super();
		this.layerNum = layerNum;
		this.layerScale = layerScale;
		name = 'editorDrawableLayer$layerNum';
		// Flash's DrawableBackground.setScale() stores the parallax factor but,
		// unlike Background.setScale(), deliberately leaves drawing unscaled.
		// Only this plane's camera offset uses the scale.
		rasterCanvas = new Sprite();
		brushCanvas = new Sprite();
		addChild(rasterCanvas);
		addChild(brushCanvas);
		brushCanvas.graphics.lineStyle(brushSize, color);
	}

	public function beginStroke(stageX:Float, stageY:Float, nextMode:String, nextSize:Float, nextColor:Int):Void {
		recordColor(nextColor);
		setBrushSize(nextSize);
		setMode(nextMode);
		var start = roundedLocalPoint(stageX, stageY);
		moveTo(start.x, start.y);
		strokeStartX = start.x;
		strokeStartY = start.y;
		drawing = true;
	}

	public function extendStroke(stageX:Float, stageY:Float):Bool {
		if (!drawing) {
			return false;
		}
		var point = roundedLocalPoint(stageX, stageY);
		if (point.x != brushX || point.y != brushY) {
			lineTo(point.x, point.y);
		}
		return Math.abs(strokeStartX - point.x) > BRUSH_RESTART_DISTANCE || Math.abs(strokeStartY - point.y) > BRUSH_RESTART_DISTANCE;
	}

	public function finishStroke():Void {
		if (!drawing) {
			return;
		}
		drawing = false;
		if (mode == "erase") {
			erase();
		} else {
			rasterizeDrawStroke();
		}
		notifyHistoryChanged();
	}

	public function isDrawing():Bool {
		return drawing;
	}

	public function drawRasterizeCountForTests():Int {
		return drawRasterizeCount;
	}

	public function eraseCleanupCountForTests():Int {
		return eraseCleanupCount;
	}

	public function getSaveString():String {
		return saveArray.join(",");
	}

	public function loadDrawString(drawString:String):Void {
		saveArray.resize(0);
		redoArray.resize(0);
		drawActions.resize(0);
		if (drawString != null && drawString != "") {
			for (entry in drawString.split(",")) {
				if (entry != "") {
					saveArray.push(entry);
				}
			}
		}
		for (action in ServerLevelDecoder.decodeDrawActions(getSaveString())) {
			drawActions.push(action);
		}
		drawing = false;
		rebuildBrushState();
		rasterize();
		notifyHistoryChanged();
	}

	public function undo():Bool {
		if (saveArray.length == 0) {
			return false;
		}
		var action = saveArray.pop();
		redoArray.push(action);
		while (saveArray.length > 0 && saveArray[saveArray.length - 1].charAt(0) != "d") {
			redoArray.push(saveArray.pop());
		}
		rebuildFromSaveArray();
		notifyHistoryChanged();
		return true;
	}

	public function redo():Bool {
		if (redoArray.length == 0) {
			return false;
		}
		while (redoArray.length > 0) {
			var action = redoArray.pop();
			saveArray.push(action);
			if (action.charAt(0) == "d") {
				break;
			}
		}
		rebuildFromSaveArray();
		notifyHistoryChanged();
		return true;
	}

	public function remove():Void {
		if (parent != null) {
			parent.removeChild(this);
		}
		clearChildren(rasterCanvas);
		clearChildren(brushCanvas);
		saveArray.resize(0);
		redoArray.resize(0);
		drawActions.resize(0);
	}

	private function recordColor(nextColor:Int):Void {
		if (color != nextColor) {
			color = nextColor;
			brushCanvas.graphics.lineStyle(brushSize, color);
			recordAction(new DecodedDrawAction("c", [color]), "c" + StringTools.hex(color, 6).toLowerCase());
		}
	}

	private function setBrushSize(nextSize:Float):Void {
		if (brushSize != nextSize) {
			brushSize = nextSize;
			brushCanvas.graphics.lineStyle(brushSize, color);
			recordAction(new DecodedDrawAction("t", [brushSize]), "t" + brushSize);
		}
	}

	private function setMode(nextMode:String):Void {
		if (mode != nextMode) {
			mode = nextMode;
			recordAction(new DecodedDrawAction("m", [], mode), "m" + mode);
		}
	}

	private function moveTo(x:Float, y:Float):Void {
		brushX = x;
		brushY = y;
		var action = new DecodedDrawAction("d", [x, y]);
		recordAction(action, "d" + x + ";" + y);
		brushCanvas.graphics.moveTo(x, y);
		brushCanvas.graphics.lineTo(x - 0.15, y);
		brushCanvas.graphics.moveTo(x, y);
	}

	private function lineTo(x:Float, y:Float):Void {
		var dx = x - brushX;
		var dy = y - brushY;
		brushX = x;
		brushY = y;
		var action = drawActions[drawActions.length - 1];
		action.values.push(dx);
		action.values.push(dy);
		saveArray[saveArray.length - 1] += ";" + dx + ";" + dy;
		brushCanvas.graphics.lineTo(x, y);
	}

	private function rasterize():Void {
		clearChildren(rasterCanvas);
		ServerLevelRenderer.renderLayerStrokes(rasterCanvas, drawActions);
		brushCanvas.graphics.clear();
		brushCanvas.graphics.lineStyle(brushSize, color);
	}

	private function rasterizeDrawStroke():Void {
		drawRasterizeCount++;
		rasterize();
	}

	private function erase():Void {
		eraseCleanupCount++;
		rasterize();
	}

	private function roundedLocalPoint(stageX:Float, stageY:Float):Point {
		var point = globalToLocal(new Point(stageX, stageY));
		point.x = Math.round(point.x);
		point.y = Math.round(point.y);
		return point;
	}

	private function recordAction(action:DecodedDrawAction, encoded:String):Void {
		drawActions.push(action);
		saveArray.push(encoded);
		redoArray.resize(0);
	}

	private function rebuildFromSaveArray():Void {
		drawActions.resize(0);
		for (action in ServerLevelDecoder.decodeDrawActions(getSaveString())) {
			drawActions.push(action);
		}
		rebuildBrushState();
		rasterize();
	}

	private function rebuildBrushState():Void {
		color = 0;
		brushSize = DEFAULT_BRUSH_SIZE;
		mode = "draw";
		for (action in drawActions) {
			switch (action.kind) {
				case "c":
					if (action.values.length > 0) {
						color = Std.int(action.values[0]);
					}
				case "t":
					if (action.values.length > 0) {
						brushSize = action.values[0];
					}
				case "m":
					mode = action.text;
				default:
			}
		}
	}

	private function notifyHistoryChanged():Void {
		var editor = LevelEditor.editor;
		if (editor != null && editor.activeDrawLayer == this && editor.menu != null) {
			editor.menu.updateUndoRedoState();
		}
	}

	private static function clearChildren(sprite:Sprite):Void {
		sprite.graphics.clear();
		while (sprite.numChildren > 0) {
			sprite.removeChildAt(0);
		}
	}
}
