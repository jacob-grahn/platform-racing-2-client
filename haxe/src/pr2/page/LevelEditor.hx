package pr2.page;

import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.display.StageQuality;
import openfl.geom.Point;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.level.ServerLevel.DecodedDrawAction;
import pr2.level.BlockType;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevelRenderer;
import pr2.lobby.account.ColorPicker;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/**
	Initial shell for Flash `levelEditor.LevelEditor`.

	The editor subsystems are ported incrementally; this owns the top-level
	lifecycle boundary Flash established before sidebars/tools attach.
**/
class LevelEditor extends Page {
	public static var editor:Null<LevelEditor>;
	public static inline var segSize:Float = 30;

	public final isMod:Bool;
	public var reportsMode(default, null):Bool;
	public var overlayLayer(default, null):Null<Sprite>;
	public var menu(default, null):Null<LevelEditorMenu>;
	public var selectedToolSidebar(default, null):String = "";
	public var selectedToolId(default, null):String = "";
	public var drawLayers(default, null):Array<EditorDrawableLayer> = [];
	public var objectLayers(default, null):Array<EditorObjectLayer> = [];
	public var activeDrawLayer(default, null):Null<EditorDrawableLayer>;
	public var activeObjectLayer(default, null):Null<EditorObjectLayer>;
	public var blockLayer(default, null):Null<EditorBlockLayer>;
	public var selectedBlock(default, null):Null<EditorBlockObject>;
	public var lastBlockOptionsRequest(default, null):Null<EditorBlockObject>;
	private var layerContainer:Null<Sprite>;
	private var drawingLayer:Null<EditorDrawableLayer>;

	public function new(?variables:Dynamic, mod:Bool = false, report:Bool = false) {
		super();
		isMod = mod;
		reportsMode = report;
	}

	override public function initialize():Void {
		super.initialize();
		LevelEditor.editor = this;
		if (stage != null) {
			stage.quality = StageQuality.HIGH;
		}

		layerContainer = new Sprite();
		addChild(layerContainer);
		blockLayer = new EditorBlockLayer(this);
		layerContainer.addChild(blockLayer);
		attachArtLayers();
		addEventListener(MouseEvent.MOUSE_DOWN, placeSelectedToolFromMouse);
		addEventListener(MouseEvent.MOUSE_MOVE, continueSelectedToolFromMouse);
		addEventListener(MouseEvent.MOUSE_UP, stopSelectedToolFromMouse);

		overlayLayer = new Sprite();
		overlayLayer.mouseEnabled = false;
		overlayLayer.mouseChildren = false;

		menu = new LevelEditorMenu(this);
		menu.init();
		addChild(menu);
		menu.setReportsMode(reportsMode);
		addChild(overlayLayer);
	}

	public function setReportsMode(on:Bool = false):Void {
		reportsMode = on;
	}

	public function selectEditorTool(sidebar:String, toolId:String):Void {
		selectedToolSidebar = sidebar;
		selectedToolId = toolId;
	}

	public function setActiveObjectLayer(layerNum:Int):Void {
		if (layerNum < 1 || layerNum > objectLayers.length) {
			return;
		}
		activeDrawLayer = drawLayers[layerNum - 1];
		activeObjectLayer = objectLayers[layerNum - 1];
	}

	public function placeSelectedToolAt(stageX:Float, stageY:Float):Null<EditorPlacedObject> {
		if (activeObjectLayer == null || selectedToolSidebar != "stamps" || !StringTools.startsWith(selectedToolId, "stamp")) {
			return null;
		}
		var code = Std.parseInt(selectedToolId.substr("stamp".length));
		if (code == null) {
			return null;
		}
		return activeObjectLayer.addStamp(code, stageX, stageY);
	}

	public function placeSelectedTextAt(stageX:Float, stageY:Float):Null<EditorTextObject> {
		if (activeObjectLayer == null || selectedToolSidebar != "stamps" || selectedToolId != "text") {
			return null;
		}
		return activeObjectLayer.addText("", stageX, stageY, EditorTextObject.lastColor, true);
	}

	public function placeSelectedBlockAt(stageX:Float, stageY:Float):Null<EditorBlockObject> {
		if (blockLayer == null || selectedToolSidebar != "blocks" || selectedToolId == "delete") {
			return null;
		}
		var spec = EditorBlockLayer.specForTool(selectedToolId);
		if (spec == null) {
			return null;
		}
		return blockLayer.addBlockAtStage(spec.code, spec.type, stageX, stageY);
	}

	public function selectBlock(block:Null<EditorBlockObject>):Void {
		if (selectedBlock == block) {
			return;
		}
		if (selectedBlock != null) {
			selectedBlock.setSelected(false);
		}
		selectedBlock = block;
		if (selectedBlock != null) {
			selectedBlock.setSelected(true);
		}
	}

	public function openBlockOptions(block:EditorBlockObject):Void {
		lastBlockOptionsRequest = block;
	}

	public function beginSelectedBrushAt(stageX:Float, stageY:Float):Bool {
		if (activeDrawLayer == null || selectedToolSidebar != "tools" || (selectedToolId != "brush" && selectedToolId != "eraser")) {
			return false;
		}
		drawingLayer = activeDrawLayer;
		drawingLayer.beginStroke(stageX, stageY, selectedToolId == "eraser" ? "erase" : "draw");
		return true;
	}

	public function continueSelectedBrushAt(stageX:Float, stageY:Float):Bool {
		if (drawingLayer == null) {
			return false;
		}
		drawingLayer.extendStroke(stageX, stageY);
		return true;
	}

	public function endSelectedBrush():Bool {
		if (drawingLayer == null) {
			return false;
		}
		drawingLayer.finishStroke();
		drawingLayer = null;
		return true;
	}

	override public function remove():Void {
		if (LevelEditor.editor == this) {
			LevelEditor.editor = null;
		}
		removeEventListener(MouseEvent.MOUSE_DOWN, placeSelectedToolFromMouse);
		removeEventListener(MouseEvent.MOUSE_MOVE, continueSelectedToolFromMouse);
		removeEventListener(MouseEvent.MOUSE_UP, stopSelectedToolFromMouse);
		if (menu != null) {
			menu.remove();
			menu = null;
		}
		if (layerContainer != null) {
			for (layer in drawLayers) {
				layer.remove();
			}
			for (layer in objectLayers) {
				layer.remove();
			}
			drawLayers = [];
			objectLayers = [];
			activeDrawLayer = null;
			activeObjectLayer = null;
			if (blockLayer != null) {
				blockLayer.remove();
			}
			blockLayer = null;
			selectedBlock = null;
			lastBlockOptionsRequest = null;
			layerContainer = null;
		}
		drawingLayer = null;
		overlayLayer = null;
		super.remove();
	}

	private function attachArtLayers():Void {
		if (layerContainer == null) {
			return;
		}
		for (scale in [1.0, 0.5, 0.25, 1.0, 2.0]) {
			var drawLayer = new EditorDrawableLayer(drawLayers.length + 1, scale);
			drawLayers.push(drawLayer);
			layerContainer.addChild(drawLayer);
			var layer = new EditorObjectLayer(objectLayers.length + 1, scale);
			objectLayers.push(layer);
			layerContainer.addChild(layer);
		}
		activeDrawLayer = drawLayers[0];
		activeObjectLayer = objectLayers[0];
	}

	private function placeSelectedToolFromMouse(event:MouseEvent):Void {
		if (menu != null && menu.hitTestPoint(event.stageX, event.stageY, true)) {
			return;
		}
		if (beginSelectedBrushAt(event.stageX, event.stageY)) {
			event.stopImmediatePropagation();
			return;
		}
		if (placeSelectedBlockAt(event.stageX, event.stageY) != null) {
			event.stopImmediatePropagation();
			return;
		}
		if (placeSelectedToolAt(event.stageX, event.stageY) != null) {
			event.stopImmediatePropagation();
			return;
		}
		if (placeSelectedTextAt(event.stageX, event.stageY) != null) {
			event.stopImmediatePropagation();
		}
	}

	private function continueSelectedToolFromMouse(event:MouseEvent):Void {
		if (continueSelectedBrushAt(event.stageX, event.stageY)) {
			event.stopImmediatePropagation();
		}
	}

	private function stopSelectedToolFromMouse(event:MouseEvent):Void {
		if (endSelectedBrush()) {
			event.stopImmediatePropagation();
		}
	}
}

typedef EditorBlockSpec = {
	final code:Int;
	final type:Null<BlockType>;
};

class LevelEditorMenu extends Sprite {
	public final editor:LevelEditor;
	public final art:PR2MovieClip;
	public final blocks:EditorSideBar;
	public final settings:EditorSideBar;
	public final stamps:EditorSideBar;
	public final tools:EditorSideBar;
	public final bg:EditorSideBar;
	public var sideBar(default, null):Null<EditorSideBar>;
	private var bindings:Array<Binding> = [];

	public function new(editor:LevelEditor) {
		super();
		this.editor = editor;
		art = PR2MovieClip.fromLinkage("LevelEditorMenuGraphic", {maxNestedDepth: 8});
		addChild(art);
		blocks = new EditorSideBar("blocks", ["delete", "basic1", "basic2", "basic3", "basic4", "brick", "finish", "ice", "item", "infItem", "left",
			"right", "up", "down", "teleport", "mine", "crumble", "vanish", "move", "water", "rotateR", "rotateL", "push", "happy", "sad",
			"custom", "safety", "heart", "time", "egg"]);
		settings = new EditorSideBar("settings", ["music", "items", "hats", "rank", "gravity", "time", "mode", "sfcm", "pass"]);
		stamps = new EditorSideBar("stamps", ["brush", "delete", "text", "stamp0", "stamp1", "stamp2", "stamp3", "stamp4", "stamp5", "stamp6",
			"stamp7", "stamp8", "stamp9"]);
		tools = new EditorSideBar("tools", ["landscape", "brush", "eraser", "size", "color"]);
		bg = new EditorSideBar("backgrounds", ["color", "bg1", "bg2", "bg3", "bg4", "bg5", "bg6", "bg7"]);
	}

	public function init():Void {
		bind("blocksButton", clickBlocks);
		bind("settingsButton", clickSettings);
		bind("bgButton", clickBackgrounds);
		bind("layer00Button", function() setLayer(5));
		bind("layer0Button", function() setLayer(4));
		bind("layer1Button", function() setLayer(1));
		bind("layer2Button", function() setLayer(2));
		bind("layer3Button", function() setLayer(3));
		Reflect.setProperty(find("zoomSelect"), "selectedIndex", 3);
		if (pr2.lobby.LobbySession.group <= 0) {
			Reflect.setProperty(find("saveButton"), "enabled", false);
			Reflect.setProperty(find("loadButton"), "enabled", false);
		}
		reset();
	}

	public function setReportsMode(on:Bool = false):Void {
		Reflect.setProperty(find("saveButton"), "enabled", !on);
		editor.setReportsMode(on);
	}

	public function changeSideBar(next:EditorSideBar):Void {
		if (sideBar != null) {
			sideBar.exit();
		}
		sideBar = next;
		editor.selectEditorTool("", "");
		sideBar.init();
		addChild(sideBar);
	}

	public function reset():Void {
		clickBlocks();
		tools.exit();
	}

	public function remove():Void {
		for (binding in bindings) LobbyArt.unbind(binding);
		bindings = [];
		for (side in [blocks, settings, stamps, tools, bg]) {
			side.remove();
		}
		sideBar = null;
		art.dispose();
	}

	private function find(name:String):Dynamic {
		return pr2.util.DisplayUtil.findByName(art, name);
	}

	private function bind(name:String, handler:Void->Void):Void {
		var binding = LobbyArt.bind(DisplayUtil.findByName(art, name), handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	private function clickBlocks():Void {
		changeSideBar(blocks);
		moveGlow(find("blocksButton"));
	}

	private function clickSettings():Void {
		changeSideBar(settings);
		moveGlow(find("settingsButton"));
	}

	private function clickBackgrounds():Void {
		changeSideBar(bg);
		moveGlow(find("bgButton"));
	}

	private function setLayer(layerNum:Int):Void {
		if (sideBar != stamps && sideBar != tools) {
			changeSideBar(stamps);
		}
		editor.setActiveObjectLayer(layerNum);
		moveGlow(find(switch (layerNum) {
			case 5: "layer00Button";
			case 4: "layer0Button";
			case 1: "layer1Button";
			case 2: "layer2Button";
			case 3: "layer3Button";
			default: "layer1Button";
		}));
	}

	private function moveGlow(target:Null<DisplayObject>):Void {
		var glow = Std.downcast(find("selectedGlow"), DisplayObject);
		if (target == null || glow == null) {
			return;
		}
		glow.x = target.x + target.width / 2;
		glow.width = target.width + 6;
	}
}

class EditorBlockLayer extends Sprite {
	public final editor:LevelEditor;
	public final blocks:Array<EditorBlockObject> = [];
	private final blocksBySeg:Map<String, EditorBlockObject> = new Map();

	public function new(editor:LevelEditor) {
		super();
		this.editor = editor;
		name = "editorBlockLayer";
		for (code in ObjectCodes.BLOCK_START1...ObjectCodes.BLOCK_START4 + 1) {
			var start = addBlockAtLocal(code, BlockType.Start, code * LevelEditor.segSize + 10000, LevelEditor.segSize * 2 + 10000, false);
			start.deleteable = false;
		}
	}

	public function addBlockAtStage(code:Int, type:Null<BlockType>, stageX:Float, stageY:Float):Null<EditorBlockObject> {
		var point = globalToLocal(new Point(stageX - 15, stageY - 15));
		var segX = Math.round(point.x / LevelEditor.segSize);
		var segY = Math.round(point.y / LevelEditor.segSize);
		var existing = getBlockAtSeg(segX, segY);
		if (existing != null && !existing.deleteable) {
			return null;
		}
		if (existing != null) {
			removeBlock(existing, false);
		}
		return addBlockAtLocal(code, type, point.x, point.y, true);
	}

	public function getBlockAtSeg(segX:Int, segY:Int):Null<EditorBlockObject> {
		return blocksBySeg.get(segKey(segX, segY));
	}

	public function removeBlock(block:EditorBlockObject, record:Bool = true):Void {
		var index = blocks.indexOf(block);
		if (index < 0) {
			return;
		}
		if (editor.selectedBlock == block) {
			editor.selectBlock(null);
		}
		blocks.splice(index, 1);
		blocksBySeg.remove(segKey(block.segX, block.segY));
		block.remove();
	}

	public function getSaveString():String {
		var out:Array<String> = [];
		var lastX = 0;
		var lastY = 0;
		var lastCode = 0;
		for (block in blocks) {
			var code = block.code - 100;
			var relX = block.segX - lastX;
			var relY = block.segY - lastY;
			lastX = block.segX;
			lastY = block.segY;
			var row = relX + ";" + relY;
			if (code != lastCode || block.options != "") {
				lastCode = code;
				row += ";" + code;
				if (block.options != "") {
					row += ";" + block.options;
				}
			}
			out.push(row);
		}
		return out.join(",");
	}

	public function remove():Void {
		while (blocks.length > 0) {
			removeBlock(blocks[blocks.length - 1], false);
		}
		blocksBySeg.clear();
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function addBlockAtLocal(code:Int, type:Null<BlockType>, localX:Float, localY:Float, select:Bool):EditorBlockObject {
		var block = new EditorBlockObject(editor, code, type, snap(localX), snap(localY));
		blocks.push(block);
		blocksBySeg.set(segKey(block.segX, block.segY), block);
		addChild(block);
		if (select) {
			editor.selectBlock(block);
		}
		return block;
	}

	private static inline function snap(value:Float):Int {
		return Std.int(Math.round(value / LevelEditor.segSize) * LevelEditor.segSize);
	}

	private static inline function segKey(segX:Int, segY:Int):String {
		return segX + ":" + segY;
	}

	public static function specForTool(toolId:String):Null<EditorBlockSpec> {
		return switch (toolId) {
			case "basic1": {code: ObjectCodes.BLOCK_BASIC1, type: BlockType.Basic};
			case "basic2": {code: ObjectCodes.BLOCK_BASIC2, type: BlockType.Basic};
			case "basic3": {code: ObjectCodes.BLOCK_BASIC3, type: BlockType.Basic};
			case "basic4": {code: ObjectCodes.BLOCK_BASIC4, type: BlockType.Basic};
			case "brick": {code: ObjectCodes.BLOCK_BRICK, type: BlockType.Brick};
			case "finish": {code: ObjectCodes.BLOCK_FINISH, type: BlockType.Finish};
			case "ice": {code: ObjectCodes.BLOCK_ICE, type: BlockType.Ice};
			case "item": {code: ObjectCodes.BLOCK_ITEM, type: BlockType.Item};
			case "infItem": {code: ObjectCodes.BLOCK_ITEM_INF, type: BlockType.InfiniteItem};
			case "left": {code: ObjectCodes.BLOCK_ARROW_LEFT, type: BlockType.ArrowLeft};
			case "right": {code: ObjectCodes.BLOCK_ARROW_RIGHT, type: BlockType.ArrowRight};
			case "up": {code: ObjectCodes.BLOCK_ARROW_UP, type: BlockType.ArrowUp};
			case "down": {code: ObjectCodes.BLOCK_ARROW_DOWN, type: BlockType.ArrowDown};
			case "teleport": {code: ObjectCodes.BLOCK_TELEPORT, type: BlockType.Teleport};
			case "mine": {code: ObjectCodes.BLOCK_MINE, type: BlockType.Mine};
			case "crumble": {code: ObjectCodes.BLOCK_CRUMBLE, type: BlockType.Crumble};
			case "vanish": {code: ObjectCodes.BLOCK_VANISH, type: BlockType.Vanish};
			case "move": {code: ObjectCodes.BLOCK_MOVE, type: BlockType.Move};
			case "water": {code: ObjectCodes.BLOCK_WATER, type: BlockType.Water};
			case "rotateR": {code: ObjectCodes.BLOCK_ROTATE_RIGHT, type: BlockType.RotateRight};
			case "rotateL": {code: ObjectCodes.BLOCK_ROTATE_LEFT, type: BlockType.RotateLeft};
			case "push": {code: ObjectCodes.BLOCK_PUSH, type: BlockType.Push};
			case "happy": {code: ObjectCodes.BLOCK_HAPPY, type: BlockType.Happy};
			case "sad": {code: ObjectCodes.BLOCK_SAD, type: BlockType.Sad};
			case "custom": {code: ObjectCodes.BLOCK_CUSTOM_STATS, type: BlockType.CustomStats};
			case "safety": {code: ObjectCodes.BLOCK_SAFETY, type: BlockType.Safety};
			case "heart": {code: ObjectCodes.BLOCK_HEART, type: BlockType.Heart};
			case "time": {code: ObjectCodes.BLOCK_TIME, type: BlockType.Time};
			case "egg": {code: ObjectCodes.BLOCK_MINION_EGG, type: null};
			default: null;
		}
	}
}

class EditorBlockObject extends Sprite {
	public final editor:LevelEditor;
	public final code:Int;
	public final type:Null<BlockType>;
	public final segX:Int;
	public final segY:Int;
	public var options(default, null):String;
	public var deleteable:Bool = true;
	private final display:Sprite;
	private var highlight:Null<Sprite>;
	private var optionsButton:Null<Sprite>;

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
		display = createDisplay(code);
		addChild(display);
		addEventListener(MouseEvent.MOUSE_DOWN, blockPressed);
	}

	public function hasOptions():Bool {
		return type != null && EditorBlockOptions.hasOptions(type);
	}

	public function setOptions(nextOptions:String):Void {
		options = nextOptions == null ? "" : nextOptions;
	}

	public function setSelected(selected:Bool):Void {
		if (selected) {
			showHighlight();
			if (deleteable && hasOptions()) {
				showOptionsButton();
			}
		} else {
			hideHighlight();
			hideOptionsButton();
		}
	}

	public function remove():Void {
		removeEventListener(MouseEvent.MOUSE_DOWN, blockPressed);
		hideOptionsButton();
		hideHighlight();
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function blockPressed(event:MouseEvent):Void {
		editor.selectBlock(this);
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

	private function showOptionsButton():Void {
		if (optionsButton != null) {
			return;
		}
		optionsButton = new Sprite();
		optionsButton.name = "optionsButton";
		optionsButton.buttonMode = true;
		optionsButton.graphics.lineStyle(1, 0x222222);
		optionsButton.graphics.beginFill(0xFFFFFF);
		optionsButton.graphics.drawCircle(0, 0, 5);
		optionsButton.graphics.endFill();
		optionsButton.x = LevelEditor.segSize;
		optionsButton.y = LevelEditor.segSize;
		optionsButton.addEventListener(MouseEvent.MOUSE_DOWN, optionsPressed);
		addChild(optionsButton);
	}

	private function hideOptionsButton():Void {
		if (optionsButton == null) {
			return;
		}
		optionsButton.removeEventListener(MouseEvent.MOUSE_DOWN, optionsPressed);
		if (optionsButton.parent != null) {
			optionsButton.parent.removeChild(optionsButton);
		}
		optionsButton = null;
	}

	private function optionsPressed(event:MouseEvent):Void {
		editor.openBlockOptions(this);
		event.stopImmediatePropagation();
	}

	private static function createDisplay(code:Int):Sprite {
		var holder = new Sprite();
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
}

class EditorObjectLayer extends Sprite {
	public final layerNum:Int;
	public final placedObjects:Array<EditorPlacedObject> = [];
	public final textObjects:Array<EditorTextObject> = [];
	public final saveArray:Array<String> = [];

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
		var placed = new EditorPlacedObject(code, Math.round(point.x - size.width / 2), Math.round(point.y - size.height / 2));
		placedObjects.push(placed);
		addChild(createStampDisplay(placed, size));
		return placed;
	}

	public function addText(text:String, stageX:Float, stageY:Float, color:Int, startEditing:Bool = false):EditorTextObject {
		var point = globalToLocal(new Point(stageX - 5, stageY - 16));
		var placed = new EditorTextObject(text, Std.int(point.x), Std.int(point.y), color, this);
		textObjects.push(placed);
		saveArray.push("u" + placed.getEscapedText() + ";" + placed.x + ";" + placed.y + ";" + color + ";100;100");
		addChild(placed);
		if (startEditing) {
			placed.startEditing();
		}
		return placed;
	}

	public function recordChangeText(textObject:EditorTextObject):Void {
		var textId = textObjects.indexOf(textObject);
		if (textId >= 0) {
			saveArray.push("y" + textId + ";" + textObject.getEscapedText() + ";" + textObject.color);
		}
	}

	public function recordMoveText(textObject:EditorTextObject):Void {
		var textId = textObjects.indexOf(textObject);
		if (textId >= 0) {
			saveArray.push("m" + textId + ";" + textObject.x + ";" + textObject.y);
		}
	}

	public function recordResizeText(textObject:EditorTextObject):Void {
		var textId = textObjects.indexOf(textObject);
		if (textId >= 0) {
			saveArray.push("r" + textId + ";" + textObject.scaleX + ";" + textObject.scaleY);
		}
	}

	public function removeTextObject(textObject:EditorTextObject, record:Bool = true):Void {
		var textId = textObjects.indexOf(textObject);
		if (textId < 0) {
			return;
		}
		if (record) {
			saveArray.push("d" + textId);
		}
		textObjects.splice(textId, 1);
		textObject.remove();
	}

	public function getSaveString():String {
		return saveArray.join(",");
	}

	public function remove():Void {
		if (parent != null) {
			parent.removeChild(this);
		}
		while (numChildren > 0) {
			removeChildAt(0);
		}
		placedObjects.resize(0);
		for (textObject in textObjects) {
			textObject.remove();
		}
		textObjects.resize(0);
		saveArray.resize(0);
	}

	private static function createStampDisplay(placed:EditorPlacedObject, size:StampSize):Sprite {
		var holder = new Sprite();
		holder.x = placed.x;
		holder.y = placed.y;
		var assetPath = ServerLevelRenderer.stampAssetPath(placed.code);
		if (assetPath != "" && Assets.exists(assetPath, AssetType.IMAGE)) {
			var bitmap = new Bitmap(Assets.getBitmapData(assetPath));
			bitmap.smoothing = true;
			bitmap.scaleX = 0.25;
			bitmap.scaleY = 0.25;
			holder.addChild(bitmap);
		} else {
			holder.graphics.lineStyle(1, 0x666666);
			holder.graphics.beginFill(0xEEEEEE, 0.5);
			holder.graphics.drawRect(0, 0, size.width, size.height);
			holder.graphics.endFill();
		}
		return holder;
	}

	private static function stampDisplaySize(code:Int):StampSize {
		return switch (code) {
			case 0: new StampSize(228, 172.75);
			case 1: new StampSize(188, 249.25);
			case 2: new StampSize(194, 236.5);
			case 3: new StampSize(77.25, 101.75);
			case 5: new StampSize(87.25, 91);
			case 6: new StampSize(125.75, 118.5);
			case 7: new StampSize(114, 319.75);
			case 8: new StampSize(294.25, 268.5);
			default: new StampSize(30, 30);
		}
	}
}

class EditorDrawableLayer extends Sprite {
	public static inline var DEFAULT_BRUSH_SIZE:Float = 4;

	public final layerNum:Int;
	public final saveArray:Array<String> = [];
	public final drawActions:Array<DecodedDrawAction> = [];
	public final rasterCanvas:Sprite;
	public final brushCanvas:Sprite;
	private var color:Int = 0;
	private var brushSize:Float = DEFAULT_BRUSH_SIZE;
	private var mode:String = "draw";
	private var brushX:Float = 0;
	private var brushY:Float = 0;
	private var drawing:Bool = false;

	public function new(layerNum:Int, layerScale:Float) {
		super();
		this.layerNum = layerNum;
		name = 'editorDrawableLayer$layerNum';
		scaleX = layerScale;
		scaleY = layerScale;
		rasterCanvas = new Sprite();
		brushCanvas = new Sprite();
		addChild(rasterCanvas);
		addChild(brushCanvas);
		brushCanvas.graphics.lineStyle(brushSize, color);
	}

	public function beginStroke(stageX:Float, stageY:Float, nextMode:String):Void {
		recordColor(color);
		setBrushSize(brushSize);
		setMode(nextMode);
		var start = roundedLocalPoint(stageX, stageY);
		moveTo(start.x, start.y);
		drawing = true;
	}

	public function extendStroke(stageX:Float, stageY:Float):Void {
		if (!drawing) {
			return;
		}
		var point = roundedLocalPoint(stageX, stageY);
		if (point.x == brushX && point.y == brushY) {
			return;
		}
		lineTo(point.x, point.y);
	}

	public function finishStroke():Void {
		if (!drawing) {
			return;
		}
		drawing = false;
		rasterize();
	}

	public function getSaveString():String {
		return saveArray.join(",");
	}

	public function remove():Void {
		if (parent != null) {
			parent.removeChild(this);
		}
		clearChildren(rasterCanvas);
		clearChildren(brushCanvas);
		saveArray.resize(0);
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
		if (mode != "erase") {
			brushCanvas.graphics.moveTo(x, y);
			brushCanvas.graphics.lineTo(x - 0.15, y);
			brushCanvas.graphics.moveTo(x, y);
		}
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
		if (mode != "erase") {
			brushCanvas.graphics.lineTo(x, y);
		}
	}

	private function rasterize():Void {
		clearChildren(rasterCanvas);
		ServerLevelRenderer.renderLayerStrokes(rasterCanvas, drawActions);
		brushCanvas.graphics.clear();
		brushCanvas.graphics.lineStyle(brushSize, color);
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
	}

	private static function clearChildren(sprite:Sprite):Void {
		sprite.graphics.clear();
		while (sprite.numChildren > 0) {
			sprite.removeChildAt(0);
		}
	}
}

class EditorPlacedObject {
	public final code:Int;
	public final x:Int;
	public final y:Int;

	public function new(code:Int, x:Int, y:Int) {
		this.code = code;
		this.x = x;
		this.y = y;
	}
}

class EditorTextObject extends Sprite {
	public static var lastColor:Int = 0;

	public var color(default, null):Int;
	public var text(default, null):String;
	private final owner:EditorObjectLayer;
	private final displayField:TextField;
	private final resizeHandle:Sprite;
	private var editField:Null<TextField>;
	private var colorPicker:Null<ColorPicker>;
	private var originalText:String;
	private var originalColor:Int;
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
		resizeHandle = createResizeHandle();
		addChild(resizeHandle);
		setText(parseText(text));
		addEventListener(MouseEvent.MOUSE_DOWN, selectForEditing);
	}

	public function startEditing():Void {
		if (editField != null) {
			return;
		}
		originalText = text;
		originalColor = color;
		displayField.visible = false;
		resizeHandle.visible = false;
		editField = createTextField();
		editField.type = TextFieldType.INPUT;
		editField.selectable = true;
		editField.background = true;
		editField.border = true;
		editField.maxChars = 500;
		editField.width = Math.max(displayField.width, 100);
		editField.height = Math.max(displayField.height, 20);
		editField.text = text;
		editField.addEventListener(Event.CHANGE, editTextChanged);
		addChild(editField);
		addColorPicker();
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
		removeColorPicker();
		displayField.visible = true;
		resizeHandle.visible = true;
		positionResizeHandle();
		if (stage != null) {
			stage.focus = stage;
		}
		if (StringTools.trim(text) == "") {
			owner.removeTextObject(this);
			return;
		}
		if (text != originalText || color != originalColor) {
			owner.recordChangeText(this);
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
		positionResizeHandle();
	}

	public function setColor(nextColor:Int):Void {
		color = nextColor;
		displayField.textColor = color;
		if (editField != null) {
			editField.textColor = color;
		}
		lastColor = color;
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
		positionResizeHandle();
	}

	public function endResizeAt(stageX:Float, stageY:Float):Void {
		if (!resizing) {
			return;
		}
		resizeDragTo(stageX, stageY);
		resizing = false;
		var changed = scaleX != resizeStartScaleX || scaleY != resizeStartScaleY;
		resizeTo(scaleX, scaleY, false);
		positionResizeHandle();
		if (changed) {
			owner.recordResizeText(this);
		}
	}

	public function beginDragAt(stageX:Float, stageY:Float):Void {
		if (isEditing() || dragging) {
			return;
		}
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
		removeStageDragListeners();
		removeStageResizeListeners();
		resizeHandle.removeEventListener(MouseEvent.MOUSE_DOWN, resizeHandlePressed);
		if (editField != null) {
			editField.removeEventListener(Event.CHANGE, editTextChanged);
			removeChild(editField);
			editField = null;
		}
		removeColorPicker();
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function selectForEditing(event:MouseEvent):Void {
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

	private function editTextChanged(_:Event):Void {
		if (editField != null) {
			displayField.text = editField.text;
			displayField.height = Math.max(displayField.textHeight + 5, 20);
			editField.height = Math.max(editField.textHeight + 5, 20);
			editField.width = Math.max(editField.textWidth + 8, 100);
			positionColorPicker();
			positionResizeHandle();
		}
	}

	private function addColorPicker():Void {
		removeColorPicker();
		colorPicker = new ColorPicker();
		colorPicker.setColor(color);
		colorPicker.width = 14;
		colorPicker.height = 14;
		colorPicker.addEventListener(Event.CHANGE, colorPickerChanged);
		addChild(colorPicker);
		positionColorPicker();
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
		colorPicker.x = Math.max(target.width, 100) - colorPicker.width / 2;
		colorPicker.y = -colorPicker.height / 2;
	}

	private function positionResizeHandle():Void {
		var target = editField != null ? editField : displayField;
		resizeHandle.x = target.width;
		resizeHandle.y = target.height;
	}

	private function createResizeHandle():Sprite {
		var handle = new Sprite();
		handle.name = "resizeHandle";
		handle.buttonMode = true;
		handle.mouseChildren = false;
		handle.graphics.lineStyle(1, 0x333333);
		handle.graphics.beginFill(0xFFFFFF);
		handle.graphics.drawRect(-4, -4, 8, 8);
		handle.graphics.endFill();
		handle.addEventListener(MouseEvent.MOUSE_DOWN, resizeHandlePressed);
		return handle;
	}

	private function createTextField():TextField {
		var field = new TextField();
		field.defaultTextFormat = new TextFormat("_sans", 12, color);
		field.wordWrap = false;
		field.multiline = true;
		field.autoSize = TextFieldAutoSize.LEFT;
		field.textColor = color;
		return field;
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

private class StampSize {
	public final width:Float;
	public final height:Float;

	public function new(width:Float, height:Float) {
		this.width = width;
		this.height = height;
	}
}

class EditorSideBar extends Sprite {
	public final id:String;
	public var selectedEntry(default, null):Null<EditorSideBarEntry>;

	public function new(id:String, itemIds:Array<String>) {
		super();
		this.id = id;
		name = id + "SideBar";
		x = 222;
		y = -195;
		var itemY:Float = 4;
		for (itemId in itemIds) {
			var entry = new EditorSideBarEntry(itemId);
			entry.addEventListener(MouseEvent.CLICK, selectEntry);
			entry.y = itemY;
			addChild(entry);
			itemY += entry.height + 10;
		}
	}

	public function init():Void {}

	private function selectEntry(e:MouseEvent):Void {
		var entry = Std.downcast(e.currentTarget, EditorSideBarEntry);
		if (entry == null) {
			return;
		}
		if (selectedEntry != null) {
			selectedEntry.setSelected(false);
		}
		selectedEntry = entry;
		selectedEntry.setSelected(true);
		var editor = LevelEditor.editor;
		if (editor != null && id == "stamps" && entry.id == "brush" && editor.menu != null) {
			editor.menu.changeSideBar(editor.menu.tools);
			return;
		}
		if (editor != null) {
			editor.selectEditorTool(id, entry.id);
		}
	}

	public function exit():Void {
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	public function remove():Void {
		exit();
		while (numChildren > 0) {
			var child = removeChildAt(0);
			child.removeEventListener(MouseEvent.CLICK, selectEntry);
		}
		selectedEntry = null;
	}
}

class EditorSideBarEntry extends Sprite {
	public final id:String;

	public function new(id:String) {
		super();
		this.id = id;
		name = id + "Entry";
		buttonMode = true;
		useHandCursor = true;
		draw(false);
		var label = new TextField();
		label.defaultTextFormat = new TextFormat("_sans", 6, 0x111111);
		label.width = 30;
		label.height = 30;
		label.selectable = false;
		label.mouseEnabled = false;
		label.text = id;
		addChild(label);
	}

	public function setSelected(selected:Bool):Void {
		draw(selected);
	}

	private function draw(selected:Bool):Void {
		graphics.clear();
		graphics.beginFill(0xF4F4F4);
		graphics.lineStyle(selected ? 2 : 1, selected ? 0x1F66CC : 0x666666);
		graphics.drawRect(0, 0, 30, 30);
		graphics.endFill();
	}
}
