package pr2.levelEditor;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class EditorStampDisplay extends Sprite {
	private final owner:EditorObjectLayer;
	private final placed:EditorPlacedObject;
	private final size:StampSize;
	private final content:Sprite;
	private final selectionOutline:Sprite;
	private final deleteButton:EditorNativeGraphic;
	private final resizeButton:EditorNativeGraphic;
	private var dragging:Bool = false;
	private var dragMoved:Bool = false;
	private var dragOffsetX:Float = 0;
	private var dragOffsetY:Float = 0;
	private var dragStartX:Float = 0;
	private var dragStartY:Float = 0;
	private var resizing:Bool = false;
	private var resizeStartScaleX:Float = 1;
	private var resizeStartScaleY:Float = 1;

	public function new(owner:EditorObjectLayer, placed:EditorPlacedObject, size:StampSize) {
		super();
		this.owner = owner;
		this.placed = placed;
		this.size = size;
		x = placed.x;
		y = placed.y;
		scaleX = placed.scaleX;
		scaleY = placed.scaleY;
		buttonMode = true;
		useHandCursor = true;
		content = EditorObjectLayer.createStampContent(placed, size);
		addChild(content);
		selectionOutline = new Sprite();
		selectionOutline.name = "selectionOutline";
		addChild(selectionOutline);
		deleteButton = new EditorNativeGraphic("DeleteButton");
		deleteButton.addEventListener(MouseEvent.MOUSE_DOWN, deletePressed);
		addChild(deleteButton);
		resizeButton = new EditorNativeGraphic("ResizeButton");
		resizeButton.mouseChildren = false;
		resizeButton.addEventListener(MouseEvent.MOUSE_DOWN, resizePressed);
		addChild(resizeButton);
		addEventListener(MouseEvent.MOUSE_DOWN, selectPressed);
		positionInternals();
		setSelected(false);
	}

	public function setSelected(selected:Bool):Void {
		selectionOutline.visible = selected;
		deleteButton.visible = selected;
		resizeButton.visible = selected;
	}

	public function remove():Void {
		removeEventListener(MouseEvent.MOUSE_DOWN, selectPressed);
		removeStageDragListeners();
		removeStageResizeListeners();
		deleteButton.removeEventListener(MouseEvent.MOUSE_DOWN, deletePressed);
		resizeButton.removeEventListener(MouseEvent.MOUSE_DOWN, resizePressed);
		deleteButton.dispose();
		resizeButton.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	public function hasAuthoredDeleteButtonForTests():Bool {
		return deleteButton != null && deleteButton.name == "DeleteButton";
	}

	public function hasAuthoredResizeButtonForTests():Bool {
		return resizeButton != null && resizeButton.name == "ResizeButton";
	}

	public function selectionOutlineBoundsForTests():Rectangle {
		return selectionOutline.getBounds(this);
	}

	public function resizeHandleScaleXForTests():Float {
		return resizeButton.scaleX;
	}

	public function refreshControlsForZoom():Void {
		positionInternals();
	}

	public function syncFromModel():Void {
		x = placed.x;
		y = placed.y;
		scaleX = placed.scaleX;
		scaleY = placed.scaleY;
		positionInternals();
	}

	public function beginDragAt(stageX:Float, stageY:Float):Void {
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
		x = Math.round(x);
		y = Math.round(y);
		placed.x = Std.int(x);
		placed.y = Std.int(y);
		if (changed) {
			owner.recordMoveStamp(this);
		}
		owner.selectPlacedStamp(this);
	}

	public function beginResizeAt(stageX:Float, stageY:Float):Void {
		resizing = true;
		resizeStartScaleX = scaleX;
		resizeStartScaleY = scaleY;
	}

	public function resizeDragTo(stageX:Float, stageY:Float):Void {
		if (!resizing) {
			return;
		}
		var point = owner.globalToLocal(new Point(stageX, stageY));
		scaleX = (point.x - x) / Math.max(size.width, 1);
		scaleY = (point.y - y) / Math.max(size.height, 1);
		positionInternals();
	}

	public function endResizeAt(stageX:Float, stageY:Float):Void {
		if (!resizing) {
			return;
		}
		resizeDragTo(stageX, stageY);
		resizing = false;
		var changed = scaleX != resizeStartScaleX || scaleY != resizeStartScaleY;
		scaleX = Math.round(scaleX * 100) / 100;
		scaleY = Math.round(scaleY * 100) / 100;
		placed.scaleX = scaleX;
		placed.scaleY = scaleY;
		positionInternals();
		if (changed) {
			owner.recordResizeStamp(this);
		}
		owner.selectPlacedStamp(this);
	}

	private function selectPressed(event:MouseEvent):Void {
		owner.selectPlacedStamp(this);
		beginDragAt(event.stageX, event.stageY);
		if (stage != null) {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, dragMouseMoved);
			stage.addEventListener(MouseEvent.MOUSE_UP, dragMouseReleased);
			stage.focus = stage;
		}
		event.stopImmediatePropagation();
	}

	private function deletePressed(event:MouseEvent):Void {
		owner.removePlacedDisplay(this);
		event.stopImmediatePropagation();
	}

	private function resizePressed(event:MouseEvent):Void {
		beginResizeAt(event.stageX, event.stageY);
		if (stage != null) {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, resizeMouseMoved);
			stage.addEventListener(MouseEvent.MOUSE_UP, resizeMouseReleased);
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

	private function positionInternals():Void {
		var buttonScaleX = 1 / Math.max(0.01, Math.abs(scaleX * owner.scaleX * (owner.parent == null ? 1 : owner.parent.scaleX)));
		var buttonScaleY = 1 / Math.max(0.01, Math.abs(scaleY * owner.scaleY * (owner.parent == null ? 1 : owner.parent.scaleY)));
		deleteButton.scaleX = buttonScaleX;
		deleteButton.scaleY = buttonScaleY;
		resizeButton.scaleX = buttonScaleX;
		resizeButton.scaleY = buttonScaleY;
		deleteButton.x = 0;
		deleteButton.y = size.height;
		resizeButton.x = size.width;
		resizeButton.y = size.height;
		selectionOutline.graphics.clear();
		selectionOutline.graphics.lineStyle(3, 0xFFFFFF, 1, false, "none");
		selectionOutline.graphics.moveTo(0, 0);
		selectionOutline.graphics.lineTo(0, size.height);
		selectionOutline.graphics.lineTo(size.width, size.height);
		selectionOutline.graphics.lineTo(size.width, 0);
		selectionOutline.graphics.lineTo(0, 0);
	}
}
