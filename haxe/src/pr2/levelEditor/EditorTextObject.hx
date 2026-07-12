package pr2.levelEditor;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
import pr2.lobby.account.ColorPicker;
import pr2.runtime.PR2MovieClip;
import pr2.runtime.FontResolver;

class EditorTextObject extends Sprite {
	public static var lastColor:Int = 0;

	public var color(default, null):Int;
	public var text(default, null):String;
	private final owner:EditorObjectLayer;
	private final displayField:TextField;
	private final selectionOutline:Sprite;
	private final deleteButton:PR2MovieClip;
	private final resizeHandle:PR2MovieClip;
	private var editButton:Null<PR2MovieClip>;
	private var editField:Null<TextField>;
	private var colorPicker:Null<ColorPicker>;
	private var originalText:String;
	private var originalColor:Int;
	private var selected:Bool = false;
	private var dragging:Bool = false;
	private var dragMoved:Bool = false;
	private var dragOffsetX:Float = 0;
	private var dragOffsetY:Float = 0;
	private var dragStartX:Float = 0;
	private var dragStartY:Float = 0;
	private var resizing:Bool = false;
	private var resizeStartScaleX:Float = 1;
	private var resizeStartScaleY:Float = 1;
	private var resizeBaseWidth:Float = 100;
	private var resizeBaseHeight:Float = 20;

	public function new(text:String, x:Int, y:Int, color:Int, owner:EditorObjectLayer) {
		super();
		this.x = x;
		this.y = y;
		this.color = color;
		this.owner = owner;
		this.text = "";
		originalText = "";
		originalColor = color;

		displayField = createTextField();
		displayField.selectable = false;
		addChild(displayField);
		selectionOutline = new Sprite();
		selectionOutline.name = "selectionOutline";
		addChild(selectionOutline);
		deleteButton = PR2MovieClip.fromLinkage("DeleteButton", {maxNestedDepth: 4});
		deleteButton.name = "DeleteButton";
		deleteButton.addEventListener(MouseEvent.MOUSE_DOWN, deleteButtonPressed);
		addChild(deleteButton);
		resizeHandle = createResizeHandle();
		addChild(resizeHandle);
		showEditButton();
		addColorPicker();
		setText(parseText(text));
		addEventListener(MouseEvent.MOUSE_DOWN, selectForEditing);
		addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
	}

	public function select():Void {
		if (selected) {
			return;
		}
		selected = true;
		originalText = text;
		originalColor = color;
		addStageDeleteListener();
		addStageDeselectListener();
	}

	public function deselect(recordChange:Bool = true):Void {
		if (!selected) {
			return;
		}
		finishEditing();
		removeStageDeleteListener();
		removeStageDeselectListener();
		selected = false;
		if (recordChange && parent != null && (text != originalText || color != originalColor)) {
			owner.recordChangeText(this);
		}
	}

	public function startEditing():Void {
		if (editField != null) {
			return;
		}
		displayField.visible = false;
		hideEditButton();
		resizeHandle.visible = false;
		editField = createTextField();
		editField.type = TextFieldType.INPUT;
		editField.selectable = true;
		editField.autoSize = TextFieldAutoSize.NONE;
		editField.background = true;
		editField.border = true;
		editField.maxChars = 500;
		editField.width = Math.max(displayField.width, 100);
		editField.height = Math.max(displayField.height, 20);
		editField.text = text;
		editField.width = Math.max(editField.textWidth + 8, 100);
		editField.height = Math.max(editField.textHeight + 5, 20);
		editField.addEventListener(Event.CHANGE, editTextChanged);
		addChild(editField);
		positionInternals();
		if (stage != null) {
			stage.focus = editField;
		}
	}

	public function finishEditing():Void {
		if (editField == null) {
			return;
		}
		setText(editField.text);
		editField.removeEventListener(Event.CHANGE, editTextChanged);
		removeChild(editField);
		editField = null;
		displayField.visible = true;
		showEditButton();
		resizeHandle.visible = true;
		positionInternals();
		if (stage != null) {
			stage.focus = stage;
		}
		if (StringTools.trim(text) == "") {
			owner.removeTextObject(this);
			return;
		}
	}

	public function isEditing():Bool {
		return editField != null;
	}

	public function setEditingText(nextText:String):Void {
		if (editField == null) {
			setText(nextText);
			return;
		}
		editField.text = nextText == null ? "" : nextText;
		editTextChanged(null);
	}

	public function setText(nextText:String):Void {
		text = nextText == null ? "" : nextText;
		displayField.text = text;
		displayField.height = Math.max(displayField.textHeight + 5, 20);
		positionInternals();
	}

	public function setColor(nextColor:Int):Void {
		color = nextColor;
		displayField.textColor = color;
		if (editField != null) {
			editField.textColor = color;
		}
	}

	public function moveToLocal(nextX:Float, nextY:Float, record:Bool = true):Void {
		var roundedX = Math.round(nextX);
		var roundedY = Math.round(nextY);
		if (x == roundedX && y == roundedY) {
			return;
		}
		x = roundedX;
		y = roundedY;
		if (record) {
			owner.recordMoveText(this);
		}
	}

	public function resizeTo(nextScaleX:Float, nextScaleY:Float, record:Bool = true):Void {
		var roundedScaleX = Math.round(nextScaleX * 100) / 100;
		var roundedScaleY = Math.round(nextScaleY * 100) / 100;
		if (scaleX == roundedScaleX && scaleY == roundedScaleY) {
			return;
		}
		scaleX = roundedScaleX;
		scaleY = roundedScaleY;
		positionInternals();
		if (record) {
			owner.recordResizeText(this);
		}
	}

	public function beginResizeAt(stageX:Float, stageY:Float):Void {
		if (isEditing() || resizing) {
			return;
		}
		resizing = true;
		resizeStartScaleX = scaleX;
		resizeStartScaleY = scaleY;
		resizeBaseWidth = Math.max(displayField.width, 1);
		resizeBaseHeight = Math.max(displayField.height, 1);
		if (parent != null && parent.numChildren > 1) {
			parent.setChildIndex(this, parent.numChildren - 1);
		}
	}

	public function resizeDragTo(stageX:Float, stageY:Float):Void {
		if (!resizing) {
			return;
		}
		var point = owner.globalToLocal(new Point(stageX, stageY));
		scaleX = (point.x - x) / resizeBaseWidth;
		scaleY = (point.y - y) / resizeBaseHeight;
		positionInternals();
	}

	public function endResizeAt(stageX:Float, stageY:Float):Void {
		if (!resizing) {
			return;
		}
		resizeDragTo(stageX, stageY);
		resizing = false;
		var changed = scaleX != resizeStartScaleX || scaleY != resizeStartScaleY;
		resizeTo(scaleX, scaleY, false);
		positionInternals();
		if (changed) {
			owner.recordResizeText(this);
		}
	}

	public function beginDragAt(stageX:Float, stageY:Float):Void {
		if (isEditing() || dragging) {
			return;
		}
		owner.selectTextObject(this);
		var point = owner.globalToLocal(new Point(stageX, stageY));
		dragging = true;
		dragMoved = false;
		dragOffsetX = x - point.x;
		dragOffsetY = y - point.y;
		dragStartX = x;
		dragStartY = y;
		alpha = 0.75;
		if (parent != null && parent.numChildren > 1) {
			parent.setChildIndex(this, parent.numChildren - 1);
		}
	}

	public function dragTo(stageX:Float, stageY:Float):Void {
		if (!dragging) {
			return;
		}
		var point = owner.globalToLocal(new Point(stageX, stageY));
		var nextX = point.x + dragOffsetX;
		var nextY = point.y + dragOffsetY;
		if (x != nextX || y != nextY) {
			dragMoved = true;
		}
		x = nextX;
		y = nextY;
	}

	public function endDragAt(stageX:Float, stageY:Float):Void {
		if (!dragging) {
			return;
		}
		dragTo(stageX, stageY);
		dragging = false;
		alpha = 1;
		var changed = dragMoved || x != dragStartX || y != dragStartY;
		moveToLocal(x, y, changed);
		if (!changed) {
			startEditing();
		}
	}

	public function getEscapedText():String {
		return escapeText(text);
	}

	public function remove():Void {
		removeEventListener(MouseEvent.MOUSE_DOWN, selectForEditing);
		removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
		removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
		removeStageDeleteListener();
		removeStageDeselectListener();
		removeStageDragListeners();
		removeStageResizeListeners();
		resizeHandle.removeEventListener(MouseEvent.MOUSE_DOWN, resizeHandlePressed);
		deleteButton.removeEventListener(MouseEvent.MOUSE_DOWN, deleteButtonPressed);
		hideEditButton();
		if (editField != null) {
			editField.removeEventListener(Event.CHANGE, editTextChanged);
			removeChild(editField);
			editField = null;
		}
		removeColorPicker();
		resizeHandle.dispose();
		deleteButton.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	public function hasAuthoredDeleteButtonForTests():Bool {
		return deleteButton != null && deleteButton.name == "DeleteButton";
	}

	public function hasAuthoredResizeButtonForTests():Bool {
		return resizeHandle != null && resizeHandle.name == "ResizeButton";
	}

	public function hasAuthoredEditButtonForTests():Bool {
		return editButton != null && editButton.name == "EditTextButton";
	}

	public function hasColorPickerForTests():Bool {
		return colorPicker != null && colorPicker.name == "ColorPicker";
	}

	public function selectionOutlineBoundsForTests():Rectangle {
		return selectionOutline.getBounds(this);
	}

	public function refreshControlsForZoom():Void {
		positionInternals();
	}

	public function resizeHandleScaleXForTests():Float {
		return resizeHandle.scaleX;
	}

	public function editButtonScaleXForTests():Float {
		return editButton == null ? 0 : editButton.scaleX;
	}

	public function colorPickerScaleXForTests():Float {
		return colorPicker == null ? 0 : colorPicker.scaleX;
	}

	public function displayFieldVisibleForTests():Bool {
		return displayField.visible;
	}

	public function editFieldMaxCharsForTests():Int {
		return editField == null ? 0 : editField.maxChars;
	}

	public function editFieldWidthForTests():Float {
		return editField == null ? 0 : editField.width;
	}

	public function handleDeleteKeyForTests(keyCode:Int):Void {
		handleDeleteKey(keyCode, null);
	}

	public function chooseColorForTests(nextColor:Int):Void {
		if (colorPicker != null) {
			colorPicker.setColor(nextColor);
		}
	}

	public function displayBoundsForTests():Rectangle {
		var target = editField != null ? editField : displayField;
		return new Rectangle(0, 0, target.width, target.height);
	}

	private function selectForEditing(event:MouseEvent):Void {
		owner.selectTextObject(this);
		if (isEditing()) {
			event.stopImmediatePropagation();
			return;
		}
		beginDragAt(event.stageX, event.stageY);
		if (stage != null) {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, dragMouseMoved);
			stage.addEventListener(MouseEvent.MOUSE_UP, dragMouseReleased);
			stage.focus = stage;
		}
		event.stopImmediatePropagation();
	}

	private function dragMouseMoved(event:MouseEvent):Void {
		dragTo(event.stageX, event.stageY);
		event.stopImmediatePropagation();
	}

	private function dragMouseReleased(event:MouseEvent):Void {
		removeStageDragListeners();
		endDragAt(event.stageX, event.stageY);
		event.stopImmediatePropagation();
	}

	private function resizeHandlePressed(event:MouseEvent):Void {
		beginResizeAt(event.stageX, event.stageY);
		if (stage != null) {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, resizeMouseMoved);
			stage.addEventListener(MouseEvent.MOUSE_UP, resizeMouseReleased);
			stage.focus = stage;
		}
		event.stopImmediatePropagation();
	}

	private function resizeMouseMoved(event:MouseEvent):Void {
		resizeDragTo(event.stageX, event.stageY);
		event.stopImmediatePropagation();
	}

	private function resizeMouseReleased(event:MouseEvent):Void {
		removeStageResizeListeners();
		endResizeAt(event.stageX, event.stageY);
		event.stopImmediatePropagation();
	}

	private function removeStageDragListeners():Void {
		if (stage == null) {
			return;
		}
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragMouseMoved);
		stage.removeEventListener(MouseEvent.MOUSE_UP, dragMouseReleased);
	}

	private function removeStageResizeListeners():Void {
		if (stage == null) {
			return;
		}
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, resizeMouseMoved);
		stage.removeEventListener(MouseEvent.MOUSE_UP, resizeMouseReleased);
	}

	private function addStageDeleteListener():Void {
		if (stage != null) {
			stage.addEventListener(KeyboardEvent.KEY_DOWN, deleteKeyPressed);
		}
	}

	private function addedToStage(_:Event):Void {
		if (selected) {
			addStageDeleteListener();
			addStageDeselectListener();
		}
	}

	private function removedFromStage(_:Event):Void {
		removeStageDeleteListener();
		removeStageDeselectListener();
	}

	private function addStageDeselectListener():Void {
		if (stage != null) {
			stage.addEventListener(MouseEvent.MOUSE_DOWN, stageMousePressed);
		}
	}

	private function removeStageDeselectListener():Void {
		if (stage != null) {
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, stageMousePressed);
		}
	}

	private function stageMousePressed(event:MouseEvent):Void {
		var current = Std.downcast(event.target, DisplayObject);
		while (current != null) {
			if (current == this) {
				return;
			}
			current = current.parent;
		}
		owner.selectTextObject(null);
	}

	private function removeStageDeleteListener():Void {
		if (stage != null) {
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, deleteKeyPressed);
		}
	}

	private function deleteKeyPressed(event:KeyboardEvent):Void {
		handleDeleteKey(event.keyCode, event);
	}

	private function handleDeleteKey(keyCode:Int, event:Null<KeyboardEvent>):Void {
		if (keyCode != Keyboard.DELETE && keyCode != Keyboard.BACKSPACE) {
			return;
		}
		if (!isEditing() || (editField != null && editField.text == "")) {
			owner.removeTextObject(this);
			if (event != null) {
				event.stopImmediatePropagation();
			}
		}
	}

	private function editTextChanged(_:Event):Void {
		if (editField != null) {
			displayField.text = editField.text;
			displayField.height = Math.max(displayField.textHeight + 5, 20);
			editField.height = Math.max(editField.textHeight + 5, 20);
			editField.width = Math.max(editField.textWidth + 8, 100);
			positionInternals();
		}
	}

	private function showEditButton():Void {
		if (editButton != null) {
			return;
		}
		editButton = PR2MovieClip.fromLinkage("EditTextButton", {maxNestedDepth: 4});
		editButton.name = "EditTextButton";
		editButton.buttonMode = true;
		editButton.mouseChildren = false;
		editButton.addEventListener(MouseEvent.MOUSE_DOWN, editButtonPressed);
		addChild(editButton);
		positionInternals();
	}

	private function hideEditButton():Void {
		if (editButton == null) {
			return;
		}
		editButton.removeEventListener(MouseEvent.MOUSE_DOWN, editButtonPressed);
		editButton.dispose();
		editButton = null;
	}

	private function addColorPicker():Void {
		removeColorPicker();
		colorPicker = new ColorPicker();
		colorPicker.name = "ColorPicker";
		colorPicker.setColor(color);
		colorPicker.addEventListener(Event.CHANGE, colorPickerChanged);
		addChild(colorPicker);
		positionInternals();
	}

	private function removeColorPicker():Void {
		if (colorPicker == null) {
			return;
		}
		colorPicker.removeEventListener(Event.CHANGE, colorPickerChanged);
		colorPicker.remove();
		colorPicker = null;
	}

	private function colorPickerChanged(_:Event):Void {
		if (colorPicker != null) {
			setColor(colorPicker.getColor());
			lastColor = color;
			if (stage != null) {
				stage.focus = stage;
			}
		}
	}

	private function positionColorPicker():Void {
		if (colorPicker == null) {
			return;
		}
		var target = editField != null ? editField : displayField;
		colorPicker.x = target.width - colorPicker.width / 2;
		colorPicker.y = -colorPicker.height / 2;
	}

	private function positionInternals():Void {
		var buttonScaleX = inverseEditorScaleX();
		var buttonScaleY = inverseEditorScaleY();
		deleteButton.scaleX = buttonScaleX;
		deleteButton.scaleY = buttonScaleY;
		resizeHandle.scaleX = buttonScaleX;
		resizeHandle.scaleY = buttonScaleY;
		if (editButton != null) {
			editButton.scaleX = buttonScaleX;
			editButton.scaleY = buttonScaleY;
			editButton.x = 0;
			editButton.y = 0;
		}
		if (colorPicker != null) {
			colorPicker.scaleX = buttonScaleX * 0.4;
			colorPicker.scaleY = buttonScaleY * 0.4;
		}
		positionDeleteButton();
		positionResizeHandle();
		positionColorPicker();
		drawSelectionOutline();
	}

	private function inverseEditorScaleX():Float {
		return 1 / Math.max(0.01, Math.abs(scaleX * owner.scaleX * (owner.parent == null ? 1 : owner.parent.scaleX)));
	}

	private function inverseEditorScaleY():Float {
		return 1 / Math.max(0.01, Math.abs(scaleY * owner.scaleY * (owner.parent == null ? 1 : owner.parent.scaleY)));
	}

	private function positionDeleteButton():Void {
		var target = editField != null ? editField : displayField;
		deleteButton.x = 0;
		deleteButton.y = target.height;
	}

	private function positionResizeHandle():Void {
		var target = editField != null ? editField : displayField;
		resizeHandle.x = target.width;
		resizeHandle.y = target.height;
	}

	private function drawSelectionOutline():Void {
		var target = editField != null ? editField : displayField;
		selectionOutline.graphics.clear();
		selectionOutline.graphics.lineStyle(3, 0xFFFFFF, 1, false, "none");
		selectionOutline.graphics.moveTo(0, 0);
		selectionOutline.graphics.lineTo(0, target.height);
		selectionOutline.graphics.lineTo(target.width, target.height);
		selectionOutline.graphics.lineTo(target.width, 0);
		selectionOutline.graphics.lineTo(0, 0);
	}

	private function createResizeHandle():PR2MovieClip {
		var handle = PR2MovieClip.fromLinkage("ResizeButton", {maxNestedDepth: 4});
		handle.name = "ResizeButton";
		handle.buttonMode = true;
		handle.mouseChildren = false;
		handle.addEventListener(MouseEvent.MOUSE_DOWN, resizeHandlePressed);
		return handle;
	}

	private function deleteButtonPressed(event:MouseEvent):Void {
		owner.removeTextObject(this);
		event.stopImmediatePropagation();
	}

	private function editButtonPressed(event:MouseEvent):Void {
		startEditing();
		event.stopImmediatePropagation();
	}

	private function createTextField():TextField {
		var field = new TextField();
		field.defaultTextFormat = new TextFormat(FontResolver.resolve("Verdana"), 18, color);
		field.wordWrap = false;
		field.multiline = true;
		field.autoSize = TextFieldAutoSize.LEFT;
		field.textColor = color;
		return field;
	}

	public function fontNameForTests():String {
		return displayField.defaultTextFormat.font;
	}

	public function fontSizeForTests():Float {
		return displayField.defaultTextFormat.size;
	}

	public static function escapeText(value:String):String {
		var escaped = value == null ? "" : value;
		escaped = StringTools.replace(escaped, "#", "#35");
		escaped = StringTools.replace(escaped, "`", "#96");
		escaped = StringTools.replace(escaped, "&", "#38");
		escaped = StringTools.replace(escaped, ",", "#44");
		escaped = StringTools.replace(escaped, "+", "#43");
		escaped = StringTools.replace(escaped, "-", "#45");
		return StringTools.replace(escaped, ";", "#59");
	}

	public static function parseText(value:String):String {
		var parsed = value == null ? "" : value;
		parsed = StringTools.replace(parsed, "#96", "`");
		parsed = StringTools.replace(parsed, "#38", "&");
		parsed = StringTools.replace(parsed, "#44", ",");
		parsed = StringTools.replace(parsed, "#59", ";");
		parsed = StringTools.replace(parsed, "#43", "+");
		parsed = StringTools.replace(parsed, "#45", "-");
		return StringTools.replace(parsed, "#35", "#");
	}
}
