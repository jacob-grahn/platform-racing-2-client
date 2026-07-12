package pr2.levelEditor;

import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.level.BlockType;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevelRenderer;
import pr2.page.EditorBlockOptions;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class EditorBlockObject extends Sprite {
	public final editor:LevelEditor;
	public final code:Int;
	public final type:Null<BlockType>;
	public var segX(default, null):Int;
	public var segY(default, null):Int;
	public var options(default, null):String;
	public var deleteable:Bool = true;
	private final display:Sprite;
	private var highlight:Null<Sprite>;
	private var deleteButton:Null<PR2MovieClip>;
	private var optionsButton:Null<PR2MovieClip>;
	private var dragging:Bool = false;
	private var dragMoved:Bool = false;
	private var dragOffsetX:Float = 0;
	private var dragOffsetY:Float = 0;
	private var dragStartX:Float = 0;
	private var dragStartY:Float = 0;
	private var teleportColor:Int = EditorBlockOptions.TELEPORT_DEFAULT_COLOR;

	public function new(editor:LevelEditor, code:Int, type:Null<BlockType>, x:Int, y:Int, options:String = "") {
		super();
		this.editor = editor;
		this.code = code;
		this.type = type;
		this.options = options;
		this.x = x;
		this.y = y;
		segX = Std.int(x / LevelEditor.segSize);
		segY = Std.int(y / LevelEditor.segSize);
		name = "editorBlock_" + segX + "_" + segY;
		buttonMode = true;
		useHandCursor = true;
		display = createDisplay(code, options);
		refreshTeleportBackground();
		addChild(display);
		addEventListener(MouseEvent.MOUSE_DOWN, blockPressed);
	}

	public function hasOptions():Bool {
		return type != null && EditorBlockOptions.hasOptions(type);
	}

	public function setSeg(nextSegX:Int, nextSegY:Int):Void {
		segX = nextSegX;
		segY = nextSegY;
		x = segX * LevelEditor.segSize;
		y = segY * LevelEditor.segSize;
		name = "editorBlock_" + segX + "_" + segY;
	}

	public function setOptions(nextOptions:String, record:Bool = true):Void {
		var normalized = nextOptions == null ? "" : nextOptions;
		if (options == normalized) {
			return;
		}
		options = normalized;
		refreshTeleportBackground();
		if (record && deleteable && editor.blockLayer != null && parent == editor.blockLayer) {
			editor.blockLayer.recordBlockOptionsChanged();
		}
	}

	public function refreshItemOptionsForAllowedItems(allowedItems:Array<Int>):Bool {
		if (type != BlockType.Item && type != BlockType.InfiniteItem) {
			return false;
		}
		var normalized = EditorBlockOptions.applyItemOptions(EditorBlockOptions.selectedItems(options, allowedItems), allowedItems);
		if (normalized == options) {
			return false;
		}
		setOptions(normalized, false);
		return true;
	}

	public function setSelected(selected:Bool):Void {
		if (selected) {
			showHighlight();
			if (deleteable) {
				showDeleteButton();
				if (hasOptions()) {
					showOptionsButton();
				}
			}
		} else {
			hideHighlight();
			hideDeleteButton();
			hideOptionsButton();
		}
	}

	public function remove():Void {
		removeEventListener(MouseEvent.MOUSE_DOWN, blockPressed);
		removeStageDragListeners();
		hideDeleteButton();
		hideOptionsButton();
		hideHighlight();
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	public function beginDragAt(stageX:Float, stageY:Float):Void {
		if (dragging || editor.blockLayer == null) {
			return;
		}
		var point = editor.blockLayer.globalToLocal(new Point(stageX, stageY));
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
		if (!dragging || editor.blockLayer == null) {
			return;
		}
		var point = editor.blockLayer.globalToLocal(new Point(stageX, stageY));
		var nextX = point.x + dragOffsetX;
		var nextY = point.y + dragOffsetY;
		if (x != nextX || y != nextY) {
			dragMoved = true;
		}
		x = nextX;
		y = nextY;
	}

	public function endDragAt(stageX:Float, stageY:Float):Void {
		if (!dragging || editor.blockLayer == null) {
			return;
		}
		dragTo(stageX, stageY);
		dragging = false;
		alpha = 1;
		var nextSegX = Math.round(x / LevelEditor.segSize);
		var nextSegY = Math.round(y / LevelEditor.segSize);
		x = dragStartX;
		y = dragStartY;
		if (dragMoved || nextSegX != segX || nextSegY != segY) {
			editor.blockLayer.moveBlockToSeg(this, nextSegX, nextSegY);
		}
		editor.selectBlock(this);
	}

	public function updateControlScale():Void {
		var scale = 1 / Math.max(0.01, Math.abs((parent == null ? 1 : parent.scaleX) * (parent != null && parent.parent != null ? parent.parent.scaleX : 1)));
		if (deleteButton != null) {
			deleteButton.scaleX = scale;
			deleteButton.scaleY = scale;
		}
		if (optionsButton != null) {
			optionsButton.scaleX = scale;
			optionsButton.scaleY = scale;
		}
	}

	public function optionButtonScaleXForTests():Float {
		return optionsButton == null ? 0 : optionsButton.scaleX;
	}

	public function deleteButtonScaleXForTests():Float {
		return deleteButton == null ? 0 : deleteButton.scaleX;
	}

	public function teleportBackgroundVisibleForTests():Bool {
		return display.getChildByName("teleportColor") != null;
	}

	public function teleportColorForTests():Int {
		return teleportColor;
	}

	private function blockPressed(event:MouseEvent):Void {
		if (editor.selectedToolSidebar == "blocks" && editor.selectedToolId == "delete") {
			editor.deleteBlock(this);
			event.stopImmediatePropagation();
			return;
		}
		editor.selectBlock(this);
		beginDragAt(event.stageX, event.stageY);
		if (stage != null) {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, dragMouseMoved);
			stage.addEventListener(MouseEvent.MOUSE_UP, dragMouseReleased);
			stage.focus = stage;
		}
		event.stopImmediatePropagation();
	}

	private function showHighlight():Void {
		if (highlight != null) {
			return;
		}
		highlight = new Sprite();
		highlight.name = "selectionOutline";
		highlight.graphics.lineStyle(3, 0xFFFFFF);
		highlight.graphics.drawRect(0, 0, LevelEditor.segSize, LevelEditor.segSize);
		addChild(highlight);
	}

	private function hideHighlight():Void {
		if (highlight == null) {
			return;
		}
		if (highlight.parent != null) {
			highlight.parent.removeChild(highlight);
		}
		highlight = null;
	}

	private function showDeleteButton():Void {
		if (deleteButton != null) {
			return;
		}
		deleteButton = PR2MovieClip.fromLinkage("DeleteButton", {maxNestedDepth: 4});
		deleteButton.name = "DeleteButton";
		deleteButton.x = 0;
		deleteButton.y = LevelEditor.segSize;
		deleteButton.addEventListener(MouseEvent.MOUSE_DOWN, deletePressed);
		addChild(deleteButton);
		updateControlScale();
	}

	private function hideDeleteButton():Void {
		if (deleteButton == null) {
			return;
		}
		deleteButton.removeEventListener(MouseEvent.MOUSE_DOWN, deletePressed);
		deleteButton.dispose();
		deleteButton = null;
	}

	private function showOptionsButton():Void {
		if (optionsButton != null) {
			return;
		}
		optionsButton = PR2MovieClip.fromLinkage("BlockOptionsButton", {maxNestedDepth: 4});
		optionsButton.name = "optionsButton";
		optionsButton.buttonMode = true;
		optionsButton.x = LevelEditor.segSize;
		optionsButton.y = LevelEditor.segSize;
		optionsButton.addEventListener(MouseEvent.MOUSE_DOWN, optionsPressed);
		addChild(optionsButton);
		updateControlScale();
	}

	private function hideOptionsButton():Void {
		if (optionsButton == null) {
			return;
		}
		optionsButton.removeEventListener(MouseEvent.MOUSE_DOWN, optionsPressed);
		if (optionsButton.parent != null) {
			optionsButton.parent.removeChild(optionsButton);
		}
		optionsButton.dispose();
		optionsButton = null;
	}

	private function optionsPressed(event:MouseEvent):Void {
		editor.openBlockOptions(this);
		event.stopImmediatePropagation();
	}

	private function deletePressed(event:MouseEvent):Void {
		editor.deleteBlock(this);
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

	private function removeStageDragListeners():Void {
		if (stage == null) {
			return;
		}
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragMouseMoved);
		stage.removeEventListener(MouseEvent.MOUSE_UP, dragMouseReleased);
	}

	private function refreshTeleportBackground():Void {
		if (code != ObjectCodes.BLOCK_TELEPORT) {
			return;
		}
		teleportColor = EditorBlockOptions.teleportColor(options);
		var background = Std.downcast(display.getChildByName("teleportColor"), Sprite);
		if (background == null) {
			return;
		}
		background.graphics.clear();
		background.graphics.beginFill(teleportColor);
		background.graphics.drawRect(0, 0, LevelEditor.segSize, LevelEditor.segSize);
		background.graphics.endFill();
	}

	private static function createDisplay(code:Int, options:String):Sprite {
		var holder = new Sprite();
		if (code == ObjectCodes.BLOCK_MINION_EGG) {
			var eggBlock = PR2MovieClip.fromLinkage("EggBlockGraphic", {maxNestedDepth: 8});
			stopEggBlockFoot(eggBlock, "var_152");
			stopEggBlockFoot(eggBlock, "var_165");
			holder.addChild(eggBlock);
			return holder;
		}
		if (code == ObjectCodes.BLOCK_TELEPORT) {
			var teleportBackground = new Sprite();
			teleportBackground.name = "teleportColor";
			holder.addChild(teleportBackground);
		}
		var assetPath = ServerLevelRenderer.blockAssetPath(code);
		if (assetPath != "" && Assets.exists(assetPath, AssetType.IMAGE)) {
			var bitmap = new Bitmap(Assets.getBitmapData(assetPath));
			bitmap.width = LevelEditor.segSize;
			bitmap.height = LevelEditor.segSize;
			bitmap.smoothing = false;
			holder.addChild(bitmap);
		} else {
			holder.graphics.lineStyle(1, 0x444444);
			holder.graphics.beginFill(0xCCCCCC);
			holder.graphics.drawRect(0, 0, LevelEditor.segSize, LevelEditor.segSize);
			holder.graphics.endFill();
		}
		var rotation = ServerLevelRenderer.arrowOverlayRotation(code);
		if (rotation != null && Assets.exists(ServerLevelRenderer.arrowOverlayAssetPath(), AssetType.IMAGE)) {
			var arrow = new Bitmap(Assets.getBitmapData(ServerLevelRenderer.arrowOverlayAssetPath()));
			arrow.width = LevelEditor.segSize;
			arrow.height = LevelEditor.segSize;
			arrow.x = LevelEditor.segSize / 2;
			arrow.y = LevelEditor.segSize / 2;
			arrow.rotation = rotation;
			arrow.smoothing = false;
			holder.addChild(arrow);
		}
		return holder;
	}

	private static function stopEggBlockFoot(root:PR2MovieClip, name:String):Void {
		var foot = Std.downcast(DisplayUtil.findByName(root, name), PR2MovieClip);
		if (foot == null) {
			return;
		}
		foot.stop();
		var colorMC = Std.downcast(DisplayUtil.findByName(foot, "colorMC"), PR2MovieClip);
		if (colorMC != null) {
			colorMC.stop();
		}
		var colorMC2 = Std.downcast(DisplayUtil.findByName(foot, "colorMC2"), PR2MovieClip);
		if (colorMC2 != null) {
			colorMC2.stop();
		}
	}
}
