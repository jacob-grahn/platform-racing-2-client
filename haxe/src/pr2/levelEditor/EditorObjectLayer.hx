package pr2.levelEditor;

import com.jiggmin.data.Objects;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import pr2.level.ServerLevel.DecodedArtLayer;
import pr2.level.ServerLevel.DecodedArtObject;
import pr2.level.ServerLevel.DecodedTextObject;
import pr2.runtime.PR2MovieClip;

class EditorObjectLayer extends Sprite {
	public final layerNum:Int;
	public final placedObjects:Array<EditorPlacedObject> = [];
	public final textObjects:Array<EditorTextObject> = [];
	public final saveArray:Array<String> = [];
	public final redoArray:Array<String> = [];
	private final placedDisplays:Array<EditorStampDisplay> = [];
	private final initialObjectActions:Array<String> = [];
	private final initialTextActions:Array<String> = [];
	private var selectedStamp:Null<EditorStampDisplay>;
	private var selectedText:Null<EditorTextObject>;

	public function new(layerNum:Int, layerScale:Float) {
		super();
		this.layerNum = layerNum;
		name = 'editorObjectLayer$layerNum';
		scaleX = layerScale;
		scaleY = layerScale;
	}

	public function addStamp(code:Int, stageX:Float, stageY:Float):EditorPlacedObject {
		var size = stampDisplaySize(code);
		var point = globalToLocal(new Point(stageX, stageY));
		var placed = addPlacedStamp(code, Math.round(point.x - size.width / 2), Math.round(point.y - size.height / 2));
		recordAction("o" + code + ";" + placed.x + ";" + placed.y);
		return placed;
	}

	public function loadArtLayer(layer:Null<DecodedArtLayer>):Void {
		clearPlacedObjects();
		clearTextObjects();
		saveArray.resize(0);
		redoArray.resize(0);
		initialObjectActions.resize(0);
		initialTextActions.resize(0);
		if (layer != null) {
			for (object in layer.objects) {
				var action = encodedObjectAction(object);
				initialObjectActions.push(action);
				replayObjectAction(action);
			}
			for (text in layer.texts) {
				var action = encodedTextAction(text);
				initialTextActions.push(action);
				replayTextAction(action);
			}
		}
		notifyHistoryChanged();
	}

	public function addText(text:String, stageX:Float, stageY:Float, color:Int, startEditing:Bool = false):EditorTextObject {
		var point = globalToLocal(new Point(stageX - 5, stageY - 16));
		var placed = new EditorTextObject(text, Std.int(point.x), Std.int(point.y), color, this);
		textObjects.push(placed);
		recordAction("u" + placed.getEscapedText() + ";" + placed.x + ";" + placed.y + ";" + color + ";100;100");
		addChild(placed);
		selectTextObject(placed);
		if (startEditing) {
			placed.startEditing();
		}
		return placed;
	}

	public function recordChangeText(textObject:EditorTextObject):Void {
		var textId = textObjects.indexOf(textObject);
		if (textId >= 0) {
			recordAction("y" + drawObjectIndexForText(textId) + ";" + textObject.getEscapedText() + ";" + textObject.color);
		}
	}

	public function recordMoveText(textObject:EditorTextObject):Void {
		var textId = textObjects.indexOf(textObject);
		if (textId >= 0) {
			recordAction("m" + drawObjectIndexForText(textId) + ";" + textObject.x + ";" + textObject.y);
		}
	}

	public function recordResizeText(textObject:EditorTextObject):Void {
		var textId = textObjects.indexOf(textObject);
		if (textId >= 0) {
			recordAction("r" + drawObjectIndexForText(textId) + ";" + textObject.scaleX + ";" + textObject.scaleY);
		}
	}

	public function removeTextObject(textObject:EditorTextObject, record:Bool = true):Void {
		var textId = textObjects.indexOf(textObject);
		if (textId < 0) {
			return;
		}
		if (selectedText == textObject) {
			selectedText = null;
		}
		if (record) {
			recordAction("d" + drawObjectIndexForText(textId));
		}
		textObjects.splice(textId, 1);
		textObject.remove();
	}

	public function removePlacedDisplay(display:EditorStampDisplay):Void {
		var index = placedDisplays.indexOf(display);
		if (index >= 0) {
			recordAction("d" + drawObjectIndexForStamp(index));
			removePlacedObjectAt(index);
		}
	}

	public function recordMoveStamp(display:EditorStampDisplay):Void {
		var index = placedDisplays.indexOf(display);
		if (index >= 0) {
			recordAction("m" + drawObjectIndexForStamp(index) + ";" + Math.round(display.x) + ";" + Math.round(display.y));
		}
	}

	public function recordResizeStamp(display:EditorStampDisplay):Void {
		var index = placedDisplays.indexOf(display);
		if (index >= 0) {
			recordAction("r" + drawObjectIndexForStamp(index) + ";" + display.scaleX + ";" + display.scaleY);
		}
	}

	public function selectPlacedStamp(display:Null<EditorStampDisplay>):Void {
		if (selectedStamp == display) {
			return;
		}
		if (selectedStamp != null) {
			selectedStamp.setSelected(false);
		}
		selectedStamp = display;
		if (selectedStamp != null) {
			selectedStamp.setSelected(true);
		}
	}

	public function selectTextObject(textObject:Null<EditorTextObject>):Void {
		if (selectedText == textObject) {
			return;
		}
		if (selectedText != null) {
			selectedText.deselect();
		}
		selectedText = textObject;
		if (selectedText != null) {
			selectedText.select();
		}
	}

	public function deselectItem():Void {
		selectPlacedStamp(null);
		selectTextObject(null);
	}

	public function selectTextObjectForTests(index:Int):Void {
		selectTextObject(index >= 0 && index < textObjects.length ? textObjects[index] : null);
	}

	public function selectPlacedStampForTests(index:Int):Void {
		selectPlacedStamp(index >= 0 && index < placedDisplays.length ? placedDisplays[index] : null);
	}

	public function placedStampHasAuthoredHandlesForTests(index:Int):Bool {
		if (index < 0 || index >= placedDisplays.length) {
			return false;
		}
		var display = placedDisplays[index];
		return display.hasAuthoredDeleteButtonForTests() && display.hasAuthoredResizeButtonForTests();
	}

	public function placedStampOutlineBoundsForTests(index:Int):Rectangle {
		return index >= 0 && index < placedDisplays.length ? placedDisplays[index].selectionOutlineBoundsForTests() : new Rectangle();
	}

	public function placedStampResizeHandleScaleXForTests(index:Int):Float {
		return index >= 0 && index < placedDisplays.length ? placedDisplays[index].resizeHandleScaleXForTests() : 0;
	}

	public function dragPlacedStampForTests(index:Int, startStageX:Float, startStageY:Float, endStageX:Float, endStageY:Float):Void {
		if (index < 0 || index >= placedDisplays.length) {
			return;
		}
		var display = placedDisplays[index];
		display.beginDragAt(startStageX, startStageY);
		display.endDragAt(endStageX, endStageY);
	}

	public function resizePlacedStampForTests(index:Int, startStageX:Float, startStageY:Float, endStageX:Float, endStageY:Float):Void {
		if (index < 0 || index >= placedDisplays.length) {
			return;
		}
		var display = placedDisplays[index];
		display.beginResizeAt(startStageX, startStageY);
		display.endResizeAt(endStageX, endStageY);
	}

	public function updateDrawObjectControlsForZoom():Void {
		for (display in placedDisplays) {
			display.refreshControlsForZoom();
		}
		for (textObject in textObjects) {
			textObject.refreshControlsForZoom();
		}
	}

	public function removeObjectsTouchingPoint(stageX:Float, stageY:Float):Bool {
		var removed = false;
		for (i in 0...placedDisplays.length) {
			var index = placedDisplays.length - 1 - i;
			var display = placedDisplays[index];
			if (display != null && touchesStagePoint(display, stageX, stageY)) {
				recordAction("d" + drawObjectIndexForStamp(index));
				removePlacedObjectAt(index);
				removed = true;
			}
		}
		for (i in 0...textObjects.length) {
			var index = textObjects.length - 1 - i;
			var textObject = textObjects[index];
			if (textObject != null && touchesStagePoint(textObject, stageX, stageY)) {
				removeTextObject(textObject);
				removed = true;
			}
		}
		return removed;
	}

	public function undo():Bool {
		if (saveArray.length == 0) {
			return false;
		}
		var action = saveArray.pop();
		if (action != null) {
			redoArray.push(action);
		}
		rebuildObjects();
		notifyHistoryChanged();
		return true;
	}

	public function redo():Bool {
		if (redoArray.length == 0) {
			return false;
		}
		var action = redoArray.pop();
		if (action != null) {
			saveArray.push(action);
		}
		rebuildObjects();
		notifyHistoryChanged();
		return true;
	}

	public function getSaveString():String {
		var entries:Array<String> = [];
		var lastX = 0;
		var lastY = 0;
		var lastCode = 0;
		for (placed in placedObjects) {
			var relX = placed.x - lastX;
			var relY = placed.y - lastY;
			lastX = placed.x;
			lastY = placed.y;
			var entry = relX + ";" + relY;
			var widthPerc = Std.int(placed.scaleX * 100);
			var heightPerc = Std.int(placed.scaleY * 100);
			var scaled = widthPerc != 100 || heightPerc != 100;
			if (placed.code != lastCode) {
				lastCode = placed.code;
				entry += ";" + placed.code;
				if (scaled) {
					entry += ";" + widthPerc + ";" + heightPerc;
				}
			} else if (scaled) {
				entry += ";" + widthPerc + ";" + heightPerc;
			}
			entries.push(entry);
		}
		for (textObject in textObjects) {
			if (textObject == null || textObject.text == "" || textObject.text == " ") {
				continue;
			}
			var currentX = Std.int(textObject.x);
			var currentY = Std.int(textObject.y);
			var relX = currentX - lastX;
			var relY = currentY - lastY;
			lastX = currentX;
			lastY = currentY;
			var widthPerc = Std.int(textObject.scaleX * 100);
			var heightPerc = Std.int(textObject.scaleY * 100);
			entries.push(relX + ";" + relY + ";t;" + textObject.getEscapedText() + ";" + textObject.color + ";" + widthPerc + ";" + heightPerc);
		}
		return entries.join(",");
	}

	public function getActionString():String {
		return saveArray.join(",");
	}

	public function remove():Void {
		if (parent != null) {
			parent.removeChild(this);
		}
		clearPlacedObjects();
		clearTextObjects();
		saveArray.resize(0);
		redoArray.resize(0);
		initialObjectActions.resize(0);
		initialTextActions.resize(0);
	}

	private function recordAction(action:String):Void {
		saveArray.push(action);
		redoArray.resize(0);
		notifyHistoryChanged();
	}

	private function notifyHistoryChanged():Void {
		var editor = LevelEditor.editor;
		if (editor != null && editor.activeObjectLayer == this && editor.menu != null) {
			editor.menu.updateUndoRedoState();
		}
	}

	private function rebuildObjects():Void {
		clearPlacedObjects();
		clearTextObjects();
		for (action in initialObjectActions) {
			replayObjectAction(action);
		}
		for (action in initialTextActions) {
			replayTextAction(action);
		}
		for (action in saveArray) {
			replayObjectAction(action);
		}
	}

	private function replayObjectAction(action:String):Void {
		if (action == null || action.length == 0) {
			return;
		}
		switch (action.charAt(0)) {
			case "o":
				var parts = action.substr(1).split(";");
				if (parts.length >= 3) {
					var placed = addPlacedStamp(parseIntPart(parts, 0), parseIntPart(parts, 1), parseIntPart(parts, 2));
					if (parts.length >= 5) {
						placed.scaleX = parseFloatPart(parts, 3) / 100;
						placed.scaleY = parseFloatPart(parts, 4) / 100;
						syncPlacedDisplay(placedObjects.length - 1);
					}
				}
			case "m":
				var parts = action.split(";");
				var stampIndex = stampIndexForAction(parts);
				if (stampIndex >= 0 && stampIndex < placedObjects.length && parts.length >= 3) {
					var placed = placedObjects[stampIndex];
					placed.x = Math.round(parseFloatPart(parts, 1));
					placed.y = Math.round(parseFloatPart(parts, 2));
					syncPlacedDisplay(stampIndex);
				} else {
					replayTextAction(action);
				}
			case "r":
				var parts = action.split(";");
				var stampIndex = stampIndexForAction(parts);
				if (stampIndex >= 0 && stampIndex < placedObjects.length && parts.length >= 3) {
					var placed = placedObjects[stampIndex];
					placed.scaleX = parseFloatPart(parts, 1);
					placed.scaleY = parseFloatPart(parts, 2);
					syncPlacedDisplay(stampIndex);
				} else {
					replayTextAction(action);
				}
			case "d":
				var stampIndex = stampIndexForAction(action.split(";"));
				if (stampIndex >= 0 && stampIndex < placedObjects.length) {
					removePlacedObjectAt(stampIndex);
				} else {
					replayTextAction(action);
				}
			default:
				replayTextAction(action);
		}
	}

	private function replayTextAction(action:String):Void {
		if (action == null || action.length == 0) {
			return;
		}
		var parts = action.split(";");
		switch (action.charAt(0)) {
			case "u":
				if (parts.length < 4) {
					return;
				}
				var text = parts[0].substr(1);
				var placed = new EditorTextObject(text, parseIntPart(parts, 1), parseIntPart(parts, 2), parseIntPart(parts, 3), this);
				if (parts.length >= 6) {
					placed.resizeTo(parseFloatPart(parts, 4) / 100, parseFloatPart(parts, 5) / 100, false);
				}
				textObjects.push(placed);
				addChild(placed);
			case "y":
				var textObject = textObjectForAction(parts);
				if (textObject != null && parts.length >= 3) {
					textObject.setText(EditorTextObject.parseText(parts[1]));
					textObject.setColor(parseIntPart(parts, 2));
				}
			case "m":
				var textObject = textObjectForAction(parts);
				if (textObject != null && parts.length >= 3) {
					textObject.moveToLocal(parseFloatPart(parts, 1), parseFloatPart(parts, 2), false);
				}
			case "r":
				var textObject = textObjectForAction(parts);
				if (textObject != null && parts.length >= 3) {
					textObject.resizeTo(parseFloatPart(parts, 1), parseFloatPart(parts, 2), false);
				}
			case "d":
				var index = parseActionIndex(parts[0]) - placedObjects.length;
				if (index >= 0 && index < textObjects.length) {
					var removed = textObjects.splice(index, 1)[0];
					if (selectedText == removed) {
						selectedText = null;
					}
					removed.remove();
				}
			default:
		}
	}

	private function textObjectForAction(parts:Array<String>):Null<EditorTextObject> {
		var index = parseActionIndex(parts[0]);
		index -= placedObjects.length;
		return index >= 0 && index < textObjects.length ? textObjects[index] : null;
	}

	private function stampIndexForAction(parts:Array<String>):Int {
		var index = parseActionIndex(parts[0]);
		return index >= 0 && index < placedObjects.length ? index : -1;
	}

	private function drawObjectIndexForStamp(stampIndex:Int):Int {
		return stampIndex;
	}

	private function drawObjectIndexForText(textIndex:Int):Int {
		return placedObjects.length + textIndex;
	}

	private static function parseActionIndex(command:String):Int {
		var parsed = Std.parseInt(command.substr(1));
		return parsed == null ? -1 : parsed;
	}

	private static function parseIntPart(parts:Array<String>, index:Int):Int {
		var parsed = index < parts.length ? Std.parseInt(parts[index]) : null;
		return parsed == null ? 0 : parsed;
	}

	private static function parseFloatPart(parts:Array<String>, index:Int):Float {
		var parsed = index < parts.length ? Std.parseFloat(parts[index]) : Math.NaN;
		return Math.isNaN(parsed) ? 0 : parsed;
	}

	private function removePlacedObjectAt(index:Int):Void {
		if (index < 0 || index >= placedObjects.length) {
			return;
		}
		var display = placedDisplays[index];
		if (selectedStamp == display) {
			selectedStamp = null;
		}
		placedObjects.splice(index, 1);
		placedDisplays.splice(index, 1);
		if (display != null) {
			display.remove();
		}
	}

	private function addPlacedStamp(code:Int, x:Int, y:Int, scaleX:Float = 1, scaleY:Float = 1):EditorPlacedObject {
		var placed = new EditorPlacedObject(code, x, y, scaleX, scaleY);
		var display = createStampDisplay(placed, stampDisplaySize(code));
		placedObjects.push(placed);
		placedDisplays.push(display);
		addChild(display);
		return placed;
	}

	private function syncPlacedDisplay(index:Int):Void {
		if (index < 0 || index >= placedObjects.length || index >= placedDisplays.length) {
			return;
		}
		placedDisplays[index].syncFromModel();
	}

	private function clearPlacedObjects():Void {
		selectPlacedStamp(null);
		while (placedObjects.length > 0) {
			removePlacedObjectAt(placedObjects.length - 1);
		}
	}

	private function clearTextObjects():Void {
		if (selectedText != null) {
			selectedText.deselect(false);
			selectedText = null;
		}
		for (textObject in textObjects.copy()) {
			textObject.remove();
		}
		textObjects.resize(0);
	}

	private function addLoadedStamp(object:DecodedArtObject):Void {
		addPlacedStamp(object.code, Math.round(object.x), Math.round(object.y), object.scaleX, object.scaleY);
	}

	private static function encodedObjectAction(object:DecodedArtObject):String {
		var action = "o" + object.code + ";" + Math.round(object.x) + ";" + Math.round(object.y);
		var widthPerc = Std.int(object.scaleX * 100);
		var heightPerc = Std.int(object.scaleY * 100);
		if (widthPerc != 100 || heightPerc != 100) {
			action += ";" + widthPerc + ";" + heightPerc;
		}
		return action;
	}

	private static function encodedTextAction(text:DecodedTextObject):String {
		return "u" + text.text + ";" + Math.round(text.x) + ";" + Math.round(text.y) + ";" + text.color + ";"
			+ Std.int(text.scaleX * 100) + ";" + Std.int(text.scaleY * 100);
	}

	private function touchesStagePoint(display:DisplayObject, stageX:Float, stageY:Float):Bool {
		var point = globalToLocal(new Point(stageX, stageY));
		return display.getBounds(this).contains(point.x, point.y);
	}

	private function createStampDisplay(placed:EditorPlacedObject, size:StampSize):EditorStampDisplay {
		return new EditorStampDisplay(this, placed, size);
	}

	public static function createStampContent(placed:EditorPlacedObject, size:StampSize):Sprite {
		var holder = new Sprite();
		var display = Objects.getFromCode(placed.code);
		if (display != null) {
			holder.addChild(display);
		} else {
			holder.graphics.lineStyle(1, 0x666666);
			holder.graphics.beginFill(0xEEEEEE, 0.5);
			holder.graphics.drawRect(0, 0, size.width, size.height);
			holder.graphics.endFill();
		}
		return holder;
	}

	private static function stampDisplaySize(code:Int):StampSize {
		var display = Objects.getFromCode(code);
		if (display == null) {
			return new StampSize(30, 30);
		}
		// Bitmap exports retain high-resolution source bounds but are scaled to
		// the authored Flash size. Placement centers the displayed footprint.
		var size = new StampSize(Math.max(1, Math.abs(display.width)), Math.max(1, Math.abs(display.height)));
		var clip = Std.downcast(display, PR2MovieClip);
		if (clip != null) {
			clip.dispose();
		}
		return size;
	}
}
