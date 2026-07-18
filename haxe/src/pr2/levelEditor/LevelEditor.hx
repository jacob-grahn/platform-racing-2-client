package pr2.levelEditor;

import haxe.Json;
import haxe.Timer;
#if js
import js.Browser;
#end
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.display.StageQuality;
import openfl.geom.Point;
import openfl.geom.ColorTransform;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import openfl.ui.Keyboard;
import pr2.audio.MusicCatalog;
import pr2.gameplay.Items;
import pr2.gameplay.LevelConfig;
import pr2.level.ServerLevel.DecodedArtLayer;
import pr2.level.BlockType;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevelDecoder;
import pr2.level.ServerLevelRenderer;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.Popup;
import pr2.net.ServerLevelData;
import pr2.page.BlockGridLines;
import pr2.page.Page;

/**
	Top-level level editor page. Coordinates authored block/art layers, tools,
	settings, persistence, camera input, and the extracted popup/background controllers.
**/
class LevelEditor extends Page {
	public static var editor:Null<LevelEditor>;
	public static inline var segSize:Float = 30;
	private static inline var LEVEL_WIDTH:Int = 60000;
	private static inline var LEVEL_HEIGHT:Int = 60000;
	private static inline var BASE_HALF_STAGE_WIDTH:Float = 275;
	private static inline var BASE_HALF_STAGE_HEIGHT:Float = 200;

	public final isMod:Bool;
	public var reportsMode(default, null):Bool;
	public var overlayLayer(default, null):Null<Sprite>;
	public var menu(default, null):Null<LevelEditorMenu>;
	public var selectedToolSidebar(default, null):String = "";
	public var selectedToolId(default, null):String = "";
	public var focusedEditorLayer(default, null):String = "blocks";
	public var drawLayers(default, null):Array<EditorDrawableLayer> = [];
	public var objectLayers(default, null):Array<EditorObjectLayer> = [];
	public var activeDrawLayer(default, null):Null<EditorDrawableLayer>;
	public var activeObjectLayer(default, null):Null<EditorObjectLayer>;
	public var blockGrid(default, null):Null<BlockGridLines>;
	public var blockLayer(default, null):Null<EditorBlockLayer>;
	public var selectedBlock(default, null):Null<EditorBlockObject>;
	public var lastBlockOptionsRequest(default, null):Null<EditorBlockObject>;
	public var activeBlockOptionsPopup(default, null):Null<EditorBlockOptionsPopup>;
	public var activeItemSettingsPopup(default, null):Null<EditorItemSettingsPopup>;
	public var activeHatsSettingsPopup(default, null):Null<EditorHatsSettingsPopup>;
	public var activeMusicSettingsPopup(default, null):Null<EditorMusicSettingsPopup>;
	public var activeModeSettingsPopup(default, null):Null<EditorModeSettingsPopup>;
	public var activeValueSettingsPopup(default, null):Null<EditorValueSettingsPopup>;
	public var activeBrushSizeMenu(default, null):Null<EditorBrushSizePickerMenu>;
	public var toolCursor(default, null):EditorToolCursorManager;
	public var levelConfig(default, null):LevelConfig = new LevelConfig();
	public var allowedItems(default, null):Array<Int> = Items.getAllCodes();
	public var badHats(default, null):Array<Int> = [];
	public var title:String = "";
	public var note:String = "";
	public var live:Float = 0;
	public var toNewest:Bool = true;
	public var minRank(default, null):String = "0";
	public var pass(default, null):Null<String> = null;
	public var hasPass(default, null):Int = 0;
	public var song(get, never):String;
	public var gravity(get, never):String;
	public var maxTime(get, never):String;
	public var gameMode(get, never):String;
	public var cowboyChance(get, never):String;
	public var color(get, never):Int;
	public var artBackgroundCode(default, null):Null<Int> = null;
	public var brushColor(default, null):Int = 0;
	public var brushSize(default, null):Float = EditorDrawableLayer.DEFAULT_BRUSH_SIZE;
	public var zoom(default, null):Float = 1;
	public var posX(default, null):Float = 0;
	public var posY(default, null):Float = 0;
	private var layerContainer:Null<Sprite>;
	private var editorMousePlane:Null<Sprite>;
	private var solidBackground:Null<Shape>;
	private var artBackgroundContainer:Null<Sprite>;
	private var backgroundLoadGeneration:Int = 0;
	private var drawingLayer:Null<EditorDrawableLayer>;
	private var deletingObjects:Bool = false;
	private var deletingBlocks:Bool = false;
	private var placingBlocks:Bool = false;
	private var brushRestartTimer:Null<Timer>;
	private var brushMouseStageX:Float = 0;
	private var brushMouseStageY:Float = 0;
	private var velX:Float = 0;
	private var velY:Float = 0;
	private var pressedKeys:Map<Int, Bool> = new Map();
	private var cameraStarted:Bool = false;
	private var stageInputListenersAttached:Bool = false;
	private var mouseDownEventsForTests:Int = 0;
	private var lastMouseDownTargetForTests:String = "";
	private var lastMouseDownXForTests:Float = 0;
	private var lastMouseDownYForTests:Float = 0;
	private var initialVariables:Null<Map<String, String>>;
	private final popupController:LevelEditorPopupController;
	private final backgroundController:LevelEditorBackgroundController;

	public function new(?variables:Dynamic, mod:Bool = false, report:Bool = false) {
		super();
		isMod = mod;
		reportsMode = report;
		toolCursor = new EditorToolCursorManager(this);
		popupController = new LevelEditorPopupController(this);
		backgroundController = new LevelEditorBackgroundController(this);
		if (variables != null) {
			initialVariables = copyVars(cast variables);
		}
	}

	override public function initialize():Void {
		super.initialize();
		LevelEditor.editor = this;
		if (stage != null) {
			stage.quality = StageQuality.HIGH;
		}

		attachEditorBackground();
		editorMousePlane = createEditorMousePlane();
		editorMousePlane.addEventListener(MouseEvent.MOUSE_DOWN, placeSelectedToolFromMouse);
		editorMousePlane.addEventListener(MouseEvent.MOUSE_MOVE, continueSelectedToolFromMouse);
		editorMousePlane.addEventListener(MouseEvent.MOUSE_UP, stopSelectedToolFromMouse);
		addChild(editorMousePlane);
		layerContainer = new Sprite();
		addChild(layerContainer);
		blockGrid = new BlockGridLines();
		layerContainer.addChild(blockGrid);
		blockLayer = new EditorBlockLayer(this);
		layerContainer.addChild(blockLayer);
		attachArtLayers();
		centerOnStart();
		addEventListener(MouseEvent.MOUSE_DOWN, placeSelectedToolFromMouse);
		addEventListener(MouseEvent.MOUSE_MOVE, continueSelectedToolFromMouse);
		addEventListener(MouseEvent.MOUSE_UP, stopSelectedToolFromMouse);
		addEventListener(Event.ENTER_FRAME, keyScroll);
		addEventListener(Event.ADDED_TO_STAGE, attachKeyboardListeners);
		addEventListener(Event.REMOVED_FROM_STAGE, detachKeyboardListeners);
		if (stage != null) {
			attachKeyboardListeners();
		}

		overlayLayer = new Sprite();
		overlayLayer.mouseEnabled = false;
		overlayLayer.mouseChildren = false;

		menu = new LevelEditorMenu(this);
		menu.x = BASE_HALF_STAGE_WIDTH;
		menu.y = BASE_HALF_STAGE_HEIGHT;
		menu.init();
		addChild(menu);
		menu.setReportsMode(reportsMode);
		addChild(overlayLayer);
		if (initialVariables != null) {
			applyLoadedLevelData(new ServerLevelData(initialVariables, true), reportsMode);
			initialVariables = null;
		}
		installBrowserHarness();
	}

	private function createEditorMousePlane():Sprite {
		var plane = new Sprite();
		plane.name = "editorMousePlane";
		plane.mouseChildren = false;
		plane.graphics.beginFill(0x000000, 0.01);
		plane.graphics.drawRect(0, 0, BASE_HALF_STAGE_WIDTH * 2, BASE_HALF_STAGE_HEIGHT * 2);
		plane.graphics.endFill();
		return plane;
	}

	public function setReportsMode(on:Bool = false):Void {
		reportsMode = on;
	}

	public function canViewLevelReports():Bool {
		return isMod;
	}

	public function setColor(value:Int = LevelConfig.DEFAULT_COLOR):Void {
		levelConfig.setColor(value);
		artBackgroundCode = null;
		redrawEditorBackground();
		renderArtBackground();
		applyEditorColorTransforms();
		if (menu != null) {
			menu.updateBackgroundColor();
		}
	}

	public function setArtBackground(code:Null<Int>):Void {
		artBackgroundCode = code;
		renderArtBackground();
	}

	public function selectArtBackground(code:Int, color:Int):Void {
		setColor(color);
		setArtBackground(code);
	}

	public function setSong(value:Null<String>):Void {
		levelConfig.setSong(value);
	}

	public function setGravity(value:Null<String>):Void {
		levelConfig.setGravity(value == null || value == "" ? "1" : value);
		updateSettingValue("gravity", gravity);
	}

	public function setMaxTime(value:Null<String>):Void {
		levelConfig.setMaxTime(value == null || value == "" ? "120" : value);
		updateSettingValue("time", maxTime);
	}

	public function setMinRank(value:Null<String>):Void {
		minRank = value == null || value == "" ? "0" : value;
		updateSettingValue("rank", minRank);
	}

	public function setCowboyChance(value:Null<String>):Void {
		levelConfig.setCowboyChance(value == null || value == "" ? "5" : value);
		updateSettingValue("sfcm", cowboyChance);
	}

	public function setPass(value:Null<String>):Void {
		pass = value == null ? "" : value;
		hasPass = pass != "" ? 1 : 0;
		updateSettingValue("pass", pass);
	}

	public function setGameMode(value:String):Void {
		levelConfig.setGameMode(value == "eggs" ? "egg" : value);
		badHats = levelConfig.badHats.copy();
		updateSettingValue("mode", gameMode);
	}

	private function updateSettingValue(itemId:String, value:String):Void {
		if (menu != null) {
			menu.settings.setEntryValue(itemId, value);
		}
	}

	public function setBrushColor(value:Int):Void {
		brushColor = value & 0xFFFFFF;
		if (toolCursor != null) {
			toolCursor.setBrushColor(brushColor);
		}
	}

	public function setBrushSize(value:Float):Void {
		if (Math.isNaN(value)) {
			return;
		}
		brushSize = Math.max(1, Math.min(255, Math.round(value)));
		if (toolCursor != null) {
			toolCursor.setBrushSize(brushSize);
		}
	}

	public function setItems(value:Null<String>):Void {
		levelConfig.setItems(value);
		allowedItems = levelConfig.allowedItems.copy();
		refreshItemBlocksForAllowedItems();
	}

	public function setAllowedItems(value:Array<Int>):Void {
		setItems(value == null || value.length == 0 ? "" : value.join("`"));
	}

	public function refreshItemBlocksForAllowedItems():Int {
		return blockLayer == null ? 0 : blockLayer.refreshItemBlocksForAllowedItems(allowedItems);
	}

	public function setBadHats(value:Null<String>):Void {
		levelConfig.setBadHats(value);
		badHats = levelConfig.badHats.copy();
	}

	public function setVariables(vars:Map<String, String>):Void {
		live = parseFloat(vars.get("live"), 0);
		setMinRank(vars.get("min_level"));
		setPass(parseInt(vars.get("has_pass"), 0) == 1 ? "******" : "");
		levelConfig.setVariables(vars);
		title = levelConfig.title;
		note = levelConfig.note;
		allowedItems = levelConfig.allowedItems.copy();
		badHats = levelConfig.badHats.copy();
		if (menu != null) {
			menu.updateBackgroundColor();
		}
	}

	public function applyLoadedLevelData(data:ServerLevelData, report:Bool = false):Void {
		setVariables(data.vars);
		if (data.data != "" && blockLayer != null) {
			var level = ServerLevelDecoder.decode(data.data);
			setColor(level.bgColor);
			setArtBackground(level.artBackgroundCode);
			blockLayer.loadBlocks(level.blocks);
			loadDrawLayersFromData(data.data);
			loadObjectLayersFromDecoded(level.artLayers);
			centerOnStart();
		}
		if (menu != null) {
			menu.setReportsMode(report);
		}
	}

	public function clear():Void {
		closeBlockOptionsPopup();
		closeItemSettingsPopup();
		closeHatsSettingsPopup();
		closeMusicSettingsPopup();
		closeModeSettingsPopup();
		closeValueSettingsPopup();
		closeBrushSizeMenu();
		selectEditorTool("", "");
		levelConfig = new LevelConfig();
		title = "";
		note = "";
		live = 0;
		toNewest = true;
		allowedItems = levelConfig.allowedItems.copy();
		badHats = levelConfig.badHats.copy();
		artBackgroundCode = null;
		redrawEditorBackground();
		renderArtBackground();
		applyEditorColorTransforms();
		if (blockLayer != null) {
			blockLayer.resetToInitialBlocks();
		}
		for (drawLayer in drawLayers) {
			drawLayer.loadDrawString("");
		}
		for (objectLayer in objectLayers) {
			objectLayer.loadArtLayer(null);
		}
		setZoom(1);
		centerOnStart();
		if (menu != null) {
			menu.updateBackgroundColor();
			menu.reset();
			menu.updateUndoRedoState();
		}
	}

	public function getSaveString():String {
		var blockSave = blockLayer == null ? "" : blockLayer.getSaveString();
		var objectSave = [for (i in 0...5) objectLayers.length > i ? objectLayers[i].getSaveString() : ""];
		var drawSave = [for (i in 0...5) drawLayers.length > i ? drawLayers[i].getSaveString() : ""];
		return LevelEditorCodec.encodeLevelData(color, blockSave, objectSave, drawSave, artBackgroundCode);
	}

	public function getLevelVars():Map<String, String> {
		return LevelEditorCodec.buildVariables({
			title: title, note: note, data: getSaveString(), credits: levelConfig.credits,
			live: live, minRank: minRank, song: song, gravity: gravity, maxTime: maxTime,
			allowedItems: allowedItems, badHats: badHats, hasPass: hasPass, gameMode: gameMode,
			cowboyChance: cowboyChance, pass: pass, toNewest: toNewest
		});
	}

	public static function copyVars(vars:Map<String, String>):Map<String, String> {
		return LevelEditorCodec.copyVariables(vars);
	}

	public function setZoom(nextZoom:Float):Void {
		if (Math.isNaN(nextZoom) || nextZoom <= 0) {
			return;
		}
		zoom = nextZoom;
		if (layerContainer != null) {
			layerContainer.scaleX = zoom;
			layerContainer.scaleY = zoom;
		}
		if (blockGrid != null) {
			blockGrid.setZoom(zoom);
		}
		if (cameraStarted) {
			setPos(posX, posY);
		} else {
			applyLayerPositions();
		}
		if (toolCursor != null) {
			toolCursor.setZoom(zoom);
		}
		for (layer in objectLayers) {
			layer.updateDrawObjectControlsForZoom();
		}
		if (blockLayer != null) {
			blockLayer.updateBlockControlScales();
		}
	}

	public function setPos(x:Float, y:Float):Void {
		posX = clampScrollX(x);
		posY = clampScrollY(y);
		applyLayerPositions();
	}

	public function selectEditorTool(sidebar:String, toolId:String):Void {
		selectEditorToolInternal(sidebar, toolId, true);
	}

	public function selectEditorToolFromCursor(sidebar:String, toolId:String):Void {
		selectEditorToolInternal(sidebar, toolId, false);
	}

	private function selectEditorToolInternal(sidebar:String, toolId:String, updateCursor:Bool):Void {
		selectedToolSidebar = sidebar;
		selectedToolId = toolId;
		switch (sidebar) {
			case "blocks": focusOnBlocks();
			case "stamps": focusOnActiveObjectLayer();
			case "tools": focusOnActiveDrawLayer();
			default:
		}
		if (updateCursor && toolCursor != null) {
			toolCursor.select(sidebar, toolId);
		}
		if (menu != null) {
			menu.updateUndoRedoState();
		}
	}

	public function setActiveObjectLayer(layerNum:Int):Void {
		if (layerNum < 1 || layerNum > objectLayers.length) {
			return;
		}
		var nextObjectLayer = objectLayers[layerNum - 1];
		if (activeObjectLayer != null && activeObjectLayer != nextObjectLayer) {
			activeObjectLayer.deselectItem();
		}
		activeDrawLayer = drawLayers[layerNum - 1];
		activeObjectLayer = nextObjectLayer;
		updateObjectLayerInteractivity();
	}

	public function focusOnBlocks():Void {
		focusedEditorLayer = "blocks";
		updateObjectLayerInteractivity();
		if (menu != null) {
			menu.updateUndoRedoState();
		}
	}

	public function focusOnActiveObjectLayer():Void {
		focusedEditorLayer = "objects";
		updateObjectLayerInteractivity();
		if (menu != null) {
			menu.updateUndoRedoState();
		}
	}

	public function focusOnActiveDrawLayer():Void {
		focusedEditorLayer = "draw";
		updateObjectLayerInteractivity();
		if (menu != null) {
			menu.updateUndoRedoState();
		}
	}

	public function focusNone():Void {
		focusedEditorLayer = "";
		updateObjectLayerInteractivity();
		if (menu != null) {
			menu.updateUndoRedoState();
		}
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

	public function canPlaceStampFromTargetForTests(target:DisplayObject, stageX:Float, stageY:Float):Bool {
		return canPlaceStampFromTarget(target, stageX, stageY);
	}

	public function placeSelectedTextAt(stageX:Float, stageY:Float):Null<EditorTextObject> {
		if (activeObjectLayer == null || selectedToolSidebar != "stamps" || selectedToolId != "text") {
			return null;
		}
		var textObject = activeObjectLayer.addText("", stageX, stageY, EditorTextObject.lastColor, true);
		selectEditorTool("", "");
		return textObject;
	}

	public function placeSelectedBlockAt(stageX:Float, stageY:Float, select:Bool = true):Null<EditorBlockObject> {
		if (blockLayer == null || selectedToolSidebar != "blocks" || selectedToolId == "delete") {
			return null;
		}
		var spec = EditorBlockLayer.specForTool(selectedToolId);
		if (spec == null) {
			return null;
		}
		return blockLayer.addBlockAtStage(spec.code, spec.type, stageX, stageY, select);
	}

	public function deleteSelectedBlockAt(stageX:Float, stageY:Float):Bool {
		if (blockLayer == null || selectedToolSidebar != "blocks" || selectedToolId != "delete") {
			return false;
		}
		var block = blockLayer.getBlockAtStage(stageX, stageY);
		if (block == null || !block.deleteable) {
			return false;
		}
		deleteBlock(block);
		return true;
	}

	public function deleteSelectedObjectAt(stageX:Float, stageY:Float):Bool {
		if (activeObjectLayer == null || selectedToolSidebar != "stamps" || selectedToolId != "delete") {
			return false;
		}
		return activeObjectLayer.removeObjectsTouchingPoint(stageX, stageY);
	}

	public function deleteBlock(block:EditorBlockObject):Void {
		if (blockLayer == null || !block.deleteable) {
			return;
		}
		if (activeBlockOptionsPopup != null && activeBlockOptionsPopup.block == block) {
			closeBlockOptionsPopup();
		}
		blockLayer.removeBlock(block);
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

	public function openBlockOptions(block:EditorBlockObject):Void popupController.openBlockOptions(block);
	public function closeBlockOptionsPopup():Void popupController.closeBlockOptionsPopup();
	public function blockOptionsPopupRemoved(popup:EditorBlockOptionsPopup):Void popupController.blockOptionsPopupRemoved(popup);
	public function openItemSettingsMenu(target:DisplayObject):Void popupController.openItemSettingsMenu(target);
	public function closeItemSettingsPopup():Void popupController.closeItemSettingsPopup();
	public function itemSettingsPopupRemoved(popup:EditorItemSettingsPopup):Void popupController.itemSettingsPopupRemoved(popup);
	public function openHatsSettingsMenu(target:DisplayObject):Void popupController.openHatsSettingsMenu(target);
	public function closeHatsSettingsPopup():Void popupController.closeHatsSettingsPopup();
	public function hatsSettingsPopupRemoved(popup:EditorHatsSettingsPopup):Void popupController.hatsSettingsPopupRemoved(popup);
	public function openMusicSettingsMenu(target:DisplayObject):Void popupController.openMusicSettingsMenu(target);
	public function closeMusicSettingsPopup():Void popupController.closeMusicSettingsPopup();
	public function musicSettingsPopupRemoved(popup:EditorMusicSettingsPopup):Void popupController.musicSettingsPopupRemoved(popup);
	public function openModeSettingsMenu(target:DisplayObject):Void popupController.openModeSettingsMenu(target);
	public function closeModeSettingsPopup():Void popupController.closeModeSettingsPopup();
	public function modeSettingsPopupRemoved(popup:EditorModeSettingsPopup):Void popupController.modeSettingsPopupRemoved(popup);
	public function openValueSettingsMenu(settingId:String, target:DisplayObject):Void popupController.openValueSettingsMenu(settingId, target);
	public function closeValueSettingsPopup():Void popupController.closeValueSettingsPopup();
	public function valueSettingsPopupRemoved(popup:EditorValueSettingsPopup):Void popupController.valueSettingsPopupRemoved(popup);
	public function openBrushSizeMenu(target:EditorBrushSizePickerButton):Void popupController.openBrushSizeMenu(target);
	public function closeBrushSizeMenu():Void popupController.closeBrushSizeMenu();
	public function brushSizeMenuRemoved(menu:EditorBrushSizePickerMenu):Void popupController.brushSizeMenuRemoved(menu);

	public function beginSelectedBrushAt(stageX:Float, stageY:Float):Bool {
		if (activeDrawLayer == null || selectedToolSidebar != "tools" || (selectedToolId != "brush" && selectedToolId != "eraser")) {
			return false;
		}
		if (activeDrawLayer.isDrawing()) {
			return false;
		}
		brushMouseStageX = stageX;
		brushMouseStageY = stageY;
		drawingLayer = activeDrawLayer;
		var isEraser = selectedToolId == "eraser";
		drawingLayer.beginStroke(stageX, stageY, isEraser ? "erase" : "draw", brushSize, isEraser ? 0xFFFFFF : brushColor);
		if (toolCursor != null) {
			toolCursor.setBrushDrawing(true);
		}
		startBrushRestartTimer();
		return true;
	}

	public function canStartBrushFromTargetForTests(target:DisplayObject, stageX:Float, stageY:Float):Bool {
		return canStartBrushFromTarget(target, stageX, stageY);
	}

	public function isPointOverMenu(stageX:Float, stageY:Float):Bool {
		return (menu != null && displayShapeHitTest(menu, stageX, stageY))
			|| (activeBrushSizeMenu != null && displayBoundsHitTest(activeBrushSizeMenu, stageX, stageY));
	}

	private static function displayBoundsHitTest(display:DisplayObject, stageX:Float, stageY:Float):Bool {
		if (display == null || !display.visible) {
			return false;
		}
		var point = display.globalToLocal(new Point(stageX, stageY));
		return display.getBounds(display).contains(point.x, point.y);
	}

	private static function displayShapeHitTest(display:DisplayObject, stageX:Float, stageY:Float):Bool {
		if (display == null || !display.visible) {
			return false;
		}
		if (display.hitTestPoint(stageX, stageY, true)) {
			return true;
		}
		var container = Std.downcast(display, DisplayObjectContainer);
		if (container != null) {
			for (i in 0...container.numChildren) {
				if (displayShapeHitTest(container.getChildAt(i), stageX, stageY)) {
					return true;
				}
			}
		}
		return false;
	}

	public function continueSelectedBrushAt(stageX:Float, stageY:Float):Bool {
		if (drawingLayer == null) {
			return false;
		}
		if (!drawingLayer.isDrawing()) {
			drawingLayer = null;
			if (toolCursor != null) {
				toolCursor.setBrushDrawing(false);
			}
			stopBrushRestartTimer();
			return false;
		}
		brushMouseStageX = stageX;
		brushMouseStageY = stageY;
		if (drawingLayer.extendStroke(stageX, stageY)) {
			restartSelectedBrushStroke();
		}
		return true;
	}

	public function endSelectedBrush():Bool {
		if (drawingLayer == null) {
			return false;
		}
		drawingLayer.finishStroke();
		drawingLayer = null;
		if (toolCursor != null) {
			toolCursor.setBrushDrawing(false);
		}
		stopBrushRestartTimer();
		return true;
	}

	public function restartSelectedBrushStrokeForTests():Bool {
		return restartSelectedBrushStroke();
	}

	public function isDrawing():Bool {
		return drawingLayer != null && drawingLayer.isDrawing();
	}

	public function undoActiveObjectLayer():Bool {
		var changed = false;
		if (blockLayer != null && focusedEditorLayer == "blocks") {
			changed = blockLayer.undo();
		} else if (activeDrawLayer != null && focusedEditorLayer == "draw") {
			changed = activeDrawLayer.undo();
		} else if (activeObjectLayer != null && focusedEditorLayer == "objects") {
			changed = activeObjectLayer.undo();
		}
		if (menu != null) {
			menu.updateUndoRedoState();
		}
		return changed;
	}

	public function redoActiveObjectLayer():Bool {
		var changed = false;
		if (blockLayer != null && focusedEditorLayer == "blocks") {
			changed = blockLayer.redo();
		} else if (activeDrawLayer != null && focusedEditorLayer == "draw") {
			changed = activeDrawLayer.redo();
		} else if (activeObjectLayer != null && focusedEditorLayer == "objects") {
			changed = activeObjectLayer.redo();
		}
		if (menu != null) {
			menu.updateUndoRedoState();
		}
		return changed;
	}

	public function runBrowserE2EForTests():String {
		var result:Dynamic = {
			ok: false,
			floorPresent: false,
			artPresent: false,
			stampPresent: false,
			floorBlocks: 0,
			artActions: 0,
			stamps: 0,
			clearedBlocks: 0,
			clearedArtActions: 0,
			clearedStamps: 0,
			savedLength: 0,
			error: ""
		};
		try {
			if (blockLayer == null || activeDrawLayer == null || activeObjectLayer == null) {
				throw "editor layers are not ready";
			}
			var start = firstStartBlock();
			if (start == null) {
				throw "start block is missing";
			}

			selectEditorTool("blocks", "basic1");
			var floorSegY = start.segY + 1;
			for (dx in -2...3) {
				var point = stagePointForBlockSeg(start.segX + dx, floorSegY);
				placeSelectedBlockAt(point.x, point.y);
			}

			selectEditorTool("tools", "brush");
			setBrushColor(0x00AAFF);
			setBrushSize(6);
			var left = (start.segX - 1) * segSize;
			var top = (start.segY + 3) * segSize;
			var right = left + segSize * 2;
			var bottom = top + segSize * 2;
			drawBrushPolyline([
				new Point(left, top),
				new Point(right, top),
				new Point(right, bottom),
				new Point(left, bottom),
				new Point(left, top)
			]);

			selectEditorTool("stamps", "stamp0");
			var stampPoint = stagePointForObjectLayerLocal((start.segX + 4) * segSize, (start.segY + 3) * segSize);
			placeSelectedToolAt(stampPoint.x, stampPoint.y);

			title = "Codex Level Editor E2E";
			note = "Saved by the deterministic headless editor scenario.";
			var savedVars = getLevelVars();
			savedVars.set("level_id", "900001");
			savedVars.set("version", "1");
			var savedData = savedVars.get("data");
			result.savedLength = savedData == null ? 0 : savedData.length;

			clear();
			result.clearedBlocks = blockLayer.blocks.length;
			result.clearedArtActions = activeDrawLayer.saveArray.length;
			result.clearedStamps = activeObjectLayer.placedObjects.length;

			applyLoadedLevelData(new ServerLevelData(savedVars, true), false);
			result.floorBlocks = countBlocksOnFloor(start.segX, floorSegY);
			result.artActions = activeDrawLayer == null ? 0 : activeDrawLayer.drawActions.length;
			result.stamps = activeObjectLayer == null ? 0 : activeObjectLayer.placedObjects.length;
			result.floorPresent = result.floorBlocks == 5;
			result.artPresent = result.artActions > 0;
			result.stampPresent = result.stamps > 0;
			centerOnStart();
			result.ok = result.floorPresent && result.artPresent && result.stampPresent && result.savedLength > 0
				&& result.clearedBlocks == 4 && result.clearedArtActions == 0 && result.clearedStamps == 0;
		} catch (error:Dynamic) {
			result.error = Std.string(error);
		}
		reportBrowserE2EState(result);
		return Json.stringify(result);
	}

	public function getBrowserStateForTests():String {
		return Json.stringify({
			ok: true,
			title: title,
			selectedToolSidebar: selectedToolSidebar,
			selectedToolId: selectedToolId,
			mouseDownEvents: mouseDownEventsForTests,
			lastMouseDownTarget: lastMouseDownTargetForTests,
			lastMouseDownX: lastMouseDownXForTests,
			lastMouseDownY: lastMouseDownYForTests,
			blocks: blockLayer == null ? 0 : blockLayer.blocks.length,
			basicBlocks: countBlocksByCode(ObjectCodes.BLOCK_BASIC1),
			artActions: totalArtActions(),
			stamps: totalPlacedStamps()
		});
	}

	override public function remove():Void {
		clearBrowserHarness();
		if (LevelEditor.editor == this) {
			LevelEditor.editor = null;
		}
		removeEventListener(MouseEvent.MOUSE_DOWN, placeSelectedToolFromMouse);
		removeEventListener(MouseEvent.MOUSE_MOVE, continueSelectedToolFromMouse);
		removeEventListener(MouseEvent.MOUSE_UP, stopSelectedToolFromMouse);
		removeEventListener(Event.ENTER_FRAME, keyScroll);
		removeEventListener(Event.ADDED_TO_STAGE, attachKeyboardListeners);
		removeEventListener(Event.REMOVED_FROM_STAGE, detachKeyboardListeners);
		detachKeyboardListeners();
		if (toolCursor != null) {
			toolCursor.remove();
		}
		if (menu != null) {
			menu.remove();
			menu = null;
		}
		if (layerContainer != null) {
			if (placingBlocks && blockLayer != null) {
				blockLayer.endHistoryBatch();
			}
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
			if (blockGrid != null) {
				blockGrid.remove();
			}
			blockGrid = null;
			selectedBlock = null;
			lastBlockOptionsRequest = null;
			deletingBlocks = false;
			placingBlocks = false;
			closeBlockOptionsPopup();
			closeItemSettingsPopup();
			closeHatsSettingsPopup();
			closeMusicSettingsPopup();
			closeModeSettingsPopup();
			closeValueSettingsPopup();
			closeBrushSizeMenu();
			layerContainer = null;
		}
		backgroundLoadGeneration++;
		if (artBackgroundContainer != null) {
			while (artBackgroundContainer.numChildren > 0) {
				artBackgroundContainer.removeChildAt(0);
			}
			artBackgroundContainer = null;
		}
		solidBackground = null;
		if (editorMousePlane != null) {
			editorMousePlane.removeEventListener(MouseEvent.MOUSE_DOWN, placeSelectedToolFromMouse);
			editorMousePlane.removeEventListener(MouseEvent.MOUSE_MOVE, continueSelectedToolFromMouse);
			editorMousePlane.removeEventListener(MouseEvent.MOUSE_UP, stopSelectedToolFromMouse);
			if (editorMousePlane.parent != null) {
				editorMousePlane.parent.removeChild(editorMousePlane);
			}
			editorMousePlane = null;
		}
		drawingLayer = null;
		deletingBlocks = false;
		placingBlocks = false;
		stopBrushRestartTimer();
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
			var layer = new EditorObjectLayer(objectLayers.length + 1, scale);
			objectLayers.push(layer);
		}
		if (blockGrid != null && blockGrid.parent == layerContainer) {
			layerContainer.removeChild(blockGrid);
		}
		if (blockLayer != null && blockLayer.parent == layerContainer) {
			layerContainer.removeChild(blockLayer);
		}
		// Flash depth order: the three parallax layers sit behind the map,
		// while layers four and five sit in front. Drawing is below stamps on
		// back layers and above stamps on front layers.
		for (index in [2, 1, 0]) {
			layerContainer.addChild(drawLayers[index]);
			layerContainer.addChild(objectLayers[index]);
		}
		if (blockGrid != null) {
			layerContainer.addChild(blockGrid);
		}
		if (blockLayer != null) {
			layerContainer.addChild(blockLayer);
		}
		for (index in [3, 4]) {
			layerContainer.addChild(objectLayers[index]);
			layerContainer.addChild(drawLayers[index]);
		}
		activeDrawLayer = drawLayers[0];
		activeObjectLayer = objectLayers[0];
		updateObjectLayerInteractivity();
		applyLayerPositions();
		applyEditorColorTransforms();
	}

	private function updateObjectLayerInteractivity():Void {
		for (layer in objectLayers) {
			var active = focusedEditorLayer == "objects" && layer == activeObjectLayer;
			layer.mouseEnabled = active;
			layer.mouseChildren = active;
		}
	}

	private function attachEditorBackground():Void backgroundController.attachEditorBackground();
	private function redrawEditorBackground():Void backgroundController.redrawEditorBackground();
	private function renderArtBackground():Void backgroundController.renderArtBackground();
	private function applyEditorColorTransforms():Void backgroundController.applyEditorColorTransforms();

	private function firstStartBlock():Null<EditorBlockObject> {
		if (blockLayer == null) {
			return null;
		}
		for (block in blockLayer.blocks) {
			if (block.code >= ObjectCodes.BLOCK_START1 && block.code <= ObjectCodes.BLOCK_START4) {
				return block;
			}
		}
		return null;
	}

	private function stagePointForBlockSeg(segX:Int, segY:Int):Point {
		if (blockLayer == null) {
			return new Point();
		}
		var point = blockLayer.localToGlobal(new Point(segX * segSize, segY * segSize));
		point.x += segSize / 2;
		point.y += segSize / 2;
		return point;
	}

	private function stagePointForDrawLayerLocal(localX:Float, localY:Float):Point {
		return activeDrawLayer == null ? new Point() : activeDrawLayer.localToGlobal(new Point(localX, localY));
	}

	private function stagePointForObjectLayerLocal(localX:Float, localY:Float):Point {
		return activeObjectLayer == null ? new Point() : activeObjectLayer.localToGlobal(new Point(localX, localY));
	}

	private function drawBrushPolyline(points:Array<Point>):Void {
		if (points.length == 0) {
			return;
		}
		var first = stagePointForDrawLayerLocal(points[0].x, points[0].y);
		beginSelectedBrushAt(first.x, first.y);
		for (i in 1...points.length) {
			var point = stagePointForDrawLayerLocal(points[i].x, points[i].y);
			continueSelectedBrushAt(point.x, point.y);
		}
		endSelectedBrush();
	}

	private function countBlocksOnFloor(startSegX:Int, floorSegY:Int):Int {
		if (blockLayer == null) {
			return 0;
		}
		var count = 0;
		for (dx in -2...3) {
			var block = blockLayer.getBlockAtSeg(startSegX + dx, floorSegY);
			if (block != null && block.code == ObjectCodes.BLOCK_BASIC1) {
				count++;
			}
		}
		return count;
	}

	private function countBlocksByCode(code:Int):Int {
		if (blockLayer == null) {
			return 0;
		}
		var count = 0;
		for (block in blockLayer.blocks) {
			if (block.code == code) {
				count++;
			}
		}
		return count;
	}

	private function totalArtActions():Int {
		var count = 0;
		for (layer in drawLayers) {
			count += layer.drawActions.length;
		}
		return count;
	}

	private function totalPlacedStamps():Int {
		var count = 0;
		for (layer in objectLayers) {
			count += layer.placedObjects.length;
		}
		return count;
	}

	private function centerOnStart():Void {
		var start = firstStartBlock();
		if (start == null) {
			return;
		}
		setPos(BASE_HALF_STAGE_WIDTH - (start.segX * segSize), BASE_HALF_STAGE_HEIGHT - (start.segY * segSize));
	}

	private function installBrowserHarness():Void {
		#if js
		Browser.document.body.setAttribute("data-pr2-page", "level-editor");
		Browser.document.body.setAttribute("data-pr2-editor-e2e", "");
		var self = this;
		untyped Browser.window.__pr2RunLevelEditorE2E = function():String {
			return self.runBrowserE2EForTests();
		};
		untyped Browser.window.__pr2GetLevelEditorStateForTests = function():String {
			return self.getBrowserStateForTests();
		};
		#end
	}

	private function clearBrowserHarness():Void {
		#if js
		untyped Browser.window.__pr2RunLevelEditorE2E = null;
		untyped Browser.window.__pr2GetLevelEditorStateForTests = null;
		#end
	}

	private function reportBrowserE2EState(result:Dynamic):Void {
		#if js
		Browser.document.body.setAttribute("data-pr2-editor-e2e", Json.stringify(result));
		#end
	}

	private function keyScroll(_:Event):Void {
		var hasInput = isPressed(Keyboard.DOWN) || isPressed(Keyboard.UP) || isPressed(Keyboard.LEFT) || isPressed(Keyboard.RIGHT);
		if (!cameraStarted && !hasInput) {
			return;
		}
		cameraStarted = true;
		if (stage != null && Std.isOfType(stage.focus, TextField)) {
			setPos(posX, posY);
			return;
		}
		var accel = isPressed(Keyboard.SHIFT) ? 20 : 10;
		if (isPressed(Keyboard.DOWN)) {
			velY -= accel;
		}
		if (isPressed(Keyboard.UP)) {
			velY += accel;
		}
		if (isPressed(Keyboard.LEFT)) {
			velX += accel;
		}
		if (isPressed(Keyboard.RIGHT)) {
			velX -= accel;
		}
		velX *= 0.6;
		velY *= 0.6;
		setPos(posX + velX / zoom, posY + velY / zoom);
	}

	private function onKeyDown(event:KeyboardEvent):Void {
		pressedKeys[event.keyCode] = true;
	}

	private function onKeyUp(event:KeyboardEvent):Void {
		pressedKeys.remove(event.keyCode);
	}

	private function clearPressedKeys(_:Event):Void {
		pressedKeys.clear();
	}

	private function attachKeyboardListeners(?_:Event):Void {
		if (stage == null || stageInputListenersAttached) {
			return;
		}
		stageInputListenersAttached = true;
		stage.addEventListener(MouseEvent.MOUSE_DOWN, placeSelectedToolFromMouse, true);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, continueSelectedToolFromMouse, true);
		stage.addEventListener(MouseEvent.MOUSE_UP, stopSelectedToolFromMouse, true);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		stage.addEventListener(Event.DEACTIVATE, clearPressedKeys);
		stage.addEventListener(FocusEvent.FOCUS_OUT, clearPressedKeys);
	}

	private function detachKeyboardListeners(?_:Event):Void {
		if (stage == null || !stageInputListenersAttached) {
			return;
		}
		stageInputListenersAttached = false;
		stage.removeEventListener(MouseEvent.MOUSE_DOWN, placeSelectedToolFromMouse, true);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, continueSelectedToolFromMouse, true);
		stage.removeEventListener(MouseEvent.MOUSE_UP, stopSelectedToolFromMouse, true);
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		stage.removeEventListener(Event.DEACTIVATE, clearPressedKeys);
		stage.removeEventListener(FocusEvent.FOCUS_OUT, clearPressedKeys);
		pressedKeys.clear();
	}

	private function isPressed(keyCode:Int):Bool {
		return pressedKeys.exists(keyCode);
	}

	private function clampScrollX(value:Float):Float {
		return clamp(value, -LEVEL_WIDTH + BASE_HALF_STAGE_WIDTH / zoom, -BASE_HALF_STAGE_WIDTH / zoom);
	}

	private function clampScrollY(value:Float):Float {
		return clamp(value, -LEVEL_HEIGHT + BASE_HALF_STAGE_HEIGHT / zoom, -BASE_HALF_STAGE_HEIGHT / zoom);
	}

	private static inline function clamp(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

	private function applyLayerPositions():Void {
		if (blockGrid != null) {
			blockGrid.setPos(posX, posY);
		}
		if (blockLayer != null) {
			positionLayer(blockLayer, 1);
		}
		for (layer in drawLayers) {
			positionLayer(layer, layer.layerScale);
		}
		for (layer in objectLayers) {
			positionLayer(layer, layer.scaleX);
		}
	}

	private function positionLayer(layer:Sprite, layerScale:Float):Void {
		layer.x = Math.round(posX * layerScale);
		layer.y = Math.round(posY * layerScale);
	}

	private function placeSelectedToolFromMouse(event:MouseEvent):Void {
		if (Popup.getOpen().length > 0) {
			// Modal dialogs live directly on the stage, above the editor. Let their
			// controls receive the click without mutating the level underneath.
			return;
		}
		var target = Std.downcast(event.target, DisplayObject);
		if (target != null && isTargetWithinActiveEditorPopup(target)) {
			// Editor settings/block-option popups mount directly on the stage. They
			// are interactive editor chrome, not level-canvas input.
			return;
		}
		var targetInMenu = target != null && isTargetWithinEditorMenu(target);
		var targetInPlacedObject = target != null && isTargetWithinPlacedEditorObject(target);
		mouseDownEventsForTests++;
		lastMouseDownTargetForTests = target == null ? "" : target.name;
		lastMouseDownXForTests = event.stageX;
		lastMouseDownYForTests = event.stageY;
		if (isStampPlacementTool()) {
			if (targetInPlacedObject) {
				// Flash's ObjectPlacer removes itself when the current object layer
				// is hit, then lets the stamp's drag/resize handler receive the click.
				cancelSelectedPlacementTool();
				return;
			}
			if (target == null || !canPlaceStampFromTarget(target, event.stageX, event.stageY)) {
				cancelSelectedPlacementTool();
				// Flash removes a one-shot placer when editor chrome is clicked, but
				// lets the click continue to the menu/scrollbar control underneath.
				if (!targetInMenu && !isPointOverMenu(event.stageX, event.stageY)) {
					event.stopImmediatePropagation();
				}
				return;
			}
			if (placeSelectedToolAt(event.stageX, event.stageY) != null) {
				event.stopImmediatePropagation();
			}
			return;
		}
		if (targetInMenu || isPointOverMenu(event.stageX, event.stageY)) {
			return;
		}
		if (target != null && canStartBrushFromTarget(target, event.stageX, event.stageY) && beginSelectedBrushAt(event.stageX, event.stageY)) {
			event.stopImmediatePropagation();
			return;
		}
		if (selectedToolSidebar == "stamps" && selectedToolId == "delete") {
			deletingObjects = true;
			if (deleteSelectedObjectAt(event.stageX, event.stageY)) {
				event.stopImmediatePropagation();
			}
			return;
		}
		if (selectedToolSidebar == "blocks" && selectedToolId == "delete") {
			deletingBlocks = true;
			if (deleteSelectedBlockAt(event.stageX, event.stageY)) {
				event.stopImmediatePropagation();
			}
			return;
		}
		if (deleteSelectedBlockAt(event.stageX, event.stageY)) {
			event.stopImmediatePropagation();
			return;
		}
		if (isBlockPlacementTool()) {
			if (!placingBlocks && blockLayer != null) {
				blockLayer.beginHistoryBatch();
			}
			placingBlocks = true;
			if (placeSelectedBlockAt(event.stageX, event.stageY, false) != null) {
				event.stopImmediatePropagation();
			}
			return;
		}
		if (placeSelectedTextAt(event.stageX, event.stageY) != null) {
			event.stopImmediatePropagation();
		}
	}

	private function continueSelectedToolFromMouse(event:MouseEvent):Void {
		if (Popup.getOpen().length > 0) {
			return;
		}
		var target = Std.downcast(event.target, DisplayObject);
		if (target != null && isTargetWithinActiveEditorPopup(target)) {
			return;
		}
		if (continueSelectedBrushAt(event.stageX, event.stageY)) {
			event.stopImmediatePropagation();
			return;
		}
		if (deletingObjects && deleteSelectedObjectAt(event.stageX, event.stageY)) {
			event.stopImmediatePropagation();
			return;
		}
		if (deletingBlocks) {
			if (deleteSelectedBlockAt(event.stageX, event.stageY)) {
				event.stopImmediatePropagation();
			}
			return;
		}
		if (placingBlocks) {
			if (placeSelectedBlockAt(event.stageX, event.stageY, false) != null) {
				event.stopImmediatePropagation();
			}
			return;
		}
	}

	private function stopSelectedToolFromMouse(event:MouseEvent):Void {
		if (endSelectedBrush()) {
			event.stopImmediatePropagation();
		}
		deletingObjects = false;
		deletingBlocks = false;
		if (placingBlocks && blockLayer != null) {
			blockLayer.endHistoryBatch();
		}
		placingBlocks = false;
	}

	private function isBlockHistoryActive():Bool {
		return selectedToolSidebar == "blocks" || (menu != null && menu.sideBar == menu.blocks);
	}

	private function canStartBrushFromTarget(target:DisplayObject, stageX:Float, stageY:Float):Bool {
		if (activeDrawLayer == null || selectedToolSidebar != "tools" || (selectedToolId != "brush" && selectedToolId != "eraser")) {
			return false;
		}
		if (activeDrawLayer.isDrawing()) {
			return false;
		}
		if (isPointOverMenu(stageX, stageY)) {
			return false;
		}
		var current:Null<DisplayObject> = target;
		while (current != null) {
			if (current == menu || current == activeBrushSizeMenu) {
				return false;
			}
			if (current == activeDrawLayer || current == activeObjectLayer || current == blockGrid || current == this) {
				return true;
			}
			current = current.parent;
		}
		return false;
	}

	private function isTargetWithinEditorMenu(target:DisplayObject):Bool {
		var current:Null<DisplayObject> = target;
		while (current != null) {
			if (current == menu || current == activeBrushSizeMenu) {
				return true;
			}
			current = current.parent;
		}
		return false;
	}

	private function isTargetWithinActiveEditorPopup(target:DisplayObject):Bool {
		var current:Null<DisplayObject> = target;
		while (current != null) {
			if (current == activeBlockOptionsPopup
				|| current == activeItemSettingsPopup
				|| current == activeHatsSettingsPopup
				|| current == activeMusicSettingsPopup
				|| current == activeModeSettingsPopup
				|| current == activeValueSettingsPopup) {
				return true;
			}
			current = current.parent;
		}
		return false;
	}

	private function isTargetWithinPlacedEditorObject(target:DisplayObject):Bool {
		var current:Null<DisplayObject> = target;
		while (current != null && current != activeObjectLayer) {
			if (Std.isOfType(current, EditorStampDisplay) || Std.isOfType(current, EditorTextObject)) {
				return true;
			}
			current = current.parent;
		}
		return false;
	}

	private function isStampPlacementTool():Bool {
		return activeObjectLayer != null && selectedToolSidebar == "stamps" && StringTools.startsWith(selectedToolId, "stamp");
	}

	private function isBlockPlacementTool():Bool {
		return blockLayer != null && selectedToolSidebar == "blocks" && selectedToolId != "delete" && EditorBlockLayer.specForTool(selectedToolId) != null;
	}

	private function canPlaceStampFromTarget(target:DisplayObject, stageX:Float, stageY:Float):Bool {
		if (!isStampPlacementTool()) {
			return false;
		}
		if (isTargetWithinPlacedEditorObject(target)) {
			return false;
		}
		if (isPointOverMenu(stageX, stageY)) {
			return false;
		}
		var current:Null<DisplayObject> = target;
		while (current != null) {
			if (current == menu) {
				return false;
			}
			current = current.parent;
		}
		return true;
	}

	private function cancelSelectedPlacementTool():Void {
		if (isStampPlacementTool()) {
			selectEditorTool("", "");
		}
	}

	private function restartSelectedBrushStroke():Bool {
		if (drawingLayer == null || !drawingLayer.isDrawing()) {
			stopBrushRestartTimer();
			return false;
		}
		var layer = drawingLayer;
		var isEraser = selectedToolId == "eraser";
		layer.finishStroke();
		layer.beginStroke(brushMouseStageX, brushMouseStageY, isEraser ? "erase" : "draw", brushSize, isEraser ? 0xFFFFFF : brushColor);
		startBrushRestartTimer();
		return true;
	}

	private function startBrushRestartTimer():Void {
		stopBrushRestartTimer();
		brushRestartTimer = new Timer(10000);
		brushRestartTimer.run = function():Void {
			restartSelectedBrushStroke();
		};
	}

	private function stopBrushRestartTimer():Void {
		if (brushRestartTimer != null) {
			brushRestartTimer.stop();
			brushRestartTimer = null;
		}
	}

	private function loadDrawLayersFromData(rawData:String):Void {
		var drawSections = LevelEditorCodec.drawSections(rawData);
		for (i in 0...drawSections.length) {
			if (i < drawLayers.length) {
				drawLayers[i].loadDrawString(drawSections[i]);
			}
		}
	}

	private function loadObjectLayersFromDecoded(layers:Array<DecodedArtLayer>):Void {
		for (i in 0...objectLayers.length) {
			objectLayers[i].loadArtLayer(i < layers.length ? layers[i] : null);
		}
	}

	private function get_song():String {
		return levelConfig.song;
	}

	private function get_gravity():String {
		return levelConfig.gravity;
	}

	private function get_maxTime():String {
		return levelConfig.maxTime;
	}

	private function get_gameMode():String {
		return levelConfig.gameMode;
	}

	private function get_cowboyChance():String {
		return levelConfig.cowboyChance;
	}

	private function get_color():Int {
		return levelConfig.color;
	}

	private static function parseFloat(value:Null<String>, fallback:Float):Float {
		return LevelEditorCodec.parseFloatOr(value, fallback);
	}

	private static function parseInt(value:Null<String>, fallback:Int):Int {
		return LevelEditorCodec.parseIntOr(value, fallback);
	}
}
