package pr2.page;

import haxe.Json;
import haxe.crypto.Md5;
import haxe.Timer;
import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.display.StageQuality;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.app.AppStage;
import pr2.audio.MusicCatalog;
import pr2.audio.MusicCatalog.MusicTrack;
import pr2.character.LocalCharacter;
import pr2.gameplay.Course;
import pr2.gameplay.Items;
import pr2.gameplay.LevelConfig;
import pr2.level.ServerLevel.DecodedDrawAction;
import pr2.level.ServerLevel.DecodedArtLayer;
import pr2.level.ServerLevel.DecodedArtObject;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.level.ServerLevel.DecodedTextObject;
import pr2.level.BlockType;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevelDecoder;
import pr2.level.ServerLevelRenderer;
import pr2.lobby.account.ColorPicker;
import pr2.lobby.account.Settings;
import pr2.lobby.account.StatSlider;
import pr2.lobby.account.StatsSelect;
import pr2.lobby.LobbySession;
import pr2.lobby.chat.ChatText;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.ProgressBar;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.lobby.dialogs.HoverPopup;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.net.FormPostClient;
import pr2.net.LevelDataClient;
import pr2.net.ServerLevelData;
import pr2.net.ServerConfig;
import pr2.runtime.FlCheckBox;
import pr2.runtime.FlComboBox;
import pr2.runtime.FlComponents;
import pr2.runtime.FlSlider;
import pr2.runtime.FlSliderEvent;
import pr2.runtime.FlTextInput;
import pr2.runtime.PR2MovieClip;
import pr2.ui.CustomScrollBar;
import pr2.util.DisplayUtil;

/**
	Initial shell for Flash `levelEditor.LevelEditor`.

	The editor subsystems are ported incrementally; this owns the top-level
	lifecycle boundary Flash established before sidebars/tools attach.
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
	public var drawLayers(default, null):Array<EditorDrawableLayer> = [];
	public var objectLayers(default, null):Array<EditorObjectLayer> = [];
	public var activeDrawLayer(default, null):Null<EditorDrawableLayer>;
	public var activeObjectLayer(default, null):Null<EditorObjectLayer>;
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
	public var brushColor(default, null):Int = 0;
	public var brushSize(default, null):Float = EditorDrawableLayer.DEFAULT_BRUSH_SIZE;
	public var zoom(default, null):Float = 1;
	public var posX(default, null):Float = 0;
	public var posY(default, null):Float = 0;
	private var layerContainer:Null<Sprite>;
	private var drawingLayer:Null<EditorDrawableLayer>;
	private var deletingObjects:Bool = false;
	private var velX:Float = 0;
	private var velY:Float = 0;
	private var pressedKeys:Map<Int, Bool> = new Map();
	private var cameraStarted:Bool = false;
	private var initialVariables:Null<Map<String, String>>;

	public function new(?variables:Dynamic, mod:Bool = false, report:Bool = false) {
		super();
		isMod = mod;
		reportsMode = report;
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

		layerContainer = new Sprite();
		addChild(layerContainer);
		blockLayer = new EditorBlockLayer(this);
		layerContainer.addChild(blockLayer);
		attachArtLayers();
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
		menu.init();
		addChild(menu);
		menu.setReportsMode(reportsMode);
		addChild(overlayLayer);
		if (initialVariables != null) {
			setVariables(initialVariables);
		}
	}

	public function setReportsMode(on:Bool = false):Void {
		reportsMode = on;
	}

	public function setColor(value:Int = LevelConfig.DEFAULT_COLOR):Void {
		levelConfig.setColor(value);
		if (menu != null) {
			menu.updateBackgroundColor();
		}
	}

	public function setSong(value:Null<String>):Void {
		levelConfig.setSong(value);
	}

	public function setGravity(value:Null<String>):Void {
		levelConfig.setGravity(value == null || value == "" ? "1" : value);
	}

	public function setMaxTime(value:Null<String>):Void {
		levelConfig.setMaxTime(value == null || value == "" ? "120" : value);
	}

	public function setMinRank(value:Null<String>):Void {
		minRank = value == null || value == "" ? "0" : value;
	}

	public function setCowboyChance(value:Null<String>):Void {
		levelConfig.setCowboyChance(value == null || value == "" ? "5" : value);
	}

	public function setPass(value:Null<String>):Void {
		pass = value == null ? "" : value;
		hasPass = pass != "" ? 1 : 0;
	}

	public function setGameMode(value:String):Void {
		levelConfig.setGameMode(value == "eggs" ? "egg" : value);
	}

	public function setBrushColor(value:Int):Void {
		brushColor = value & 0xFFFFFF;
	}

	public function setBrushSize(value:Float):Void {
		if (Math.isNaN(value)) {
			return;
		}
		brushSize = Math.max(1, Math.min(255, Math.round(value)));
	}

	public function setItems(value:Null<String>):Void {
		levelConfig.setItems(value);
		allowedItems = levelConfig.allowedItems.copy();
	}

	public function setAllowedItems(value:Array<Int>):Void {
		setItems(value == null || value.length == 0 ? "" : value.join("`"));
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
			blockLayer.loadBlocks(level.blocks);
			loadDrawLayersFromData(data.data);
			loadObjectLayersFromDecoded(level.artLayers);
		}
		if (menu != null) {
			menu.setReportsMode(report);
		}
	}

	public function getSaveString():String {
		var blockSave = blockLayer == null ? "" : blockLayer.getSaveString();
		var objectSave = [for (i in 0...5) objectLayers.length > i ? objectLayers[i].getSaveString() : ""];
		var drawSave = [for (i in 0...5) drawLayers.length > i ? drawLayers[i].getSaveString() : ""];
		return [
			"m4",
			StringTools.hex(color).toLowerCase(),
			blockSave,
			objectSave[0],
			objectSave[1],
			objectSave[2],
			drawSave[0],
			drawSave[1],
			drawSave[2],
			"",
			objectSave[3],
			objectSave[4],
			drawSave[3],
			drawSave[4]
		].join("`");
	}

	public function getLevelVars():Map<String, String> {
		var vars = new Map<String, String>();
		vars.set("title", title);
		vars.set("note", note);
		vars.set("data", getSaveString());
		vars.set("credits", levelConfig.credits.join("`"));
		vars.set("live", Std.string(live));
		vars.set("min_level", minRank);
		vars.set("song", song);
		vars.set("gravity", gravity);
		vars.set("max_time", maxTime);
		vars.set("items", allowedItems.join("`"));
		vars.set("badHats", badHats.join(","));
		vars.set("hasPass", Std.string(hasPass));
		vars.set("gameMode", gameMode == "eggs" ? "egg" : gameMode);
		vars.set("cowboyChance", cowboyChance);
		vars.set("passHash", passHash());
		vars.set("to_newest", toNewest ? "1" : "0");
		return vars;
	}

	public static function copyVars(vars:Map<String, String>):Map<String, String> {
		var copied = new Map<String, String>();
		if (vars != null) {
			for (key in vars.keys()) {
				copied.set(key, vars.get(key));
			}
		}
		return copied;
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
		if (cameraStarted) {
			setPos(posX, posY);
		} else {
			applyLayerPositions();
		}
	}

	public function setPos(x:Float, y:Float):Void {
		posX = clampScrollX(x);
		posY = clampScrollY(y);
		applyLayerPositions();
	}

	public function selectEditorTool(sidebar:String, toolId:String):Void {
		selectedToolSidebar = sidebar;
		selectedToolId = toolId;
		if (menu != null) {
			menu.updateUndoRedoState();
		}
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

	public function openBlockOptions(block:EditorBlockObject):Void {
		lastBlockOptionsRequest = block;
		closeBlockOptionsPopup();
		if (block.type == BlockType.Happy || block.type == BlockType.Sad) {
			activeBlockOptionsPopup = new EditorStatBlockOptionsPopup(this, block);
		} else if (block.type == BlockType.Item || block.type == BlockType.InfiniteItem) {
			activeBlockOptionsPopup = new EditorItemBlockOptionsPopup(this, block);
		} else if (block.type == BlockType.Teleport) {
			activeBlockOptionsPopup = new EditorTeleportBlockOptionsPopup(this, block);
		} else if (block.type == BlockType.CustomStats) {
			activeBlockOptionsPopup = new EditorCustomStatsBlockOptionsPopup(this, block);
		}
	}

	public function closeBlockOptionsPopup():Void {
		if (activeBlockOptionsPopup != null) {
			var popup = activeBlockOptionsPopup;
			activeBlockOptionsPopup = null;
			popup.remove();
		}
	}

	public function blockOptionsPopupRemoved(popup:EditorBlockOptionsPopup):Void {
		if (activeBlockOptionsPopup == popup) {
			activeBlockOptionsPopup = null;
		}
	}

	public function openItemSettingsMenu(target:DisplayObject):Void {
		closeHatsSettingsPopup();
		closeMusicSettingsPopup();
		closeModeSettingsPopup();
		closeValueSettingsPopup();
		closeItemSettingsPopup();
		activeItemSettingsPopup = new EditorItemSettingsPopup(this, target);
	}

	public function closeItemSettingsPopup():Void {
		if (activeItemSettingsPopup != null) {
			var popup = activeItemSettingsPopup;
			activeItemSettingsPopup = null;
			popup.remove();
		}
	}

	public function itemSettingsPopupRemoved(popup:EditorItemSettingsPopup):Void {
		if (activeItemSettingsPopup == popup) {
			activeItemSettingsPopup = null;
		}
	}

	public function openHatsSettingsMenu(target:DisplayObject):Void {
		closeItemSettingsPopup();
		closeMusicSettingsPopup();
		closeModeSettingsPopup();
		closeValueSettingsPopup();
		closeHatsSettingsPopup();
		activeHatsSettingsPopup = new EditorHatsSettingsPopup(this, target);
	}

	public function closeHatsSettingsPopup():Void {
		if (activeHatsSettingsPopup != null) {
			var popup = activeHatsSettingsPopup;
			activeHatsSettingsPopup = null;
			popup.remove();
		}
	}

	public function hatsSettingsPopupRemoved(popup:EditorHatsSettingsPopup):Void {
		if (activeHatsSettingsPopup == popup) {
			activeHatsSettingsPopup = null;
		}
	}

	public function openMusicSettingsMenu(target:DisplayObject):Void {
		closeItemSettingsPopup();
		closeHatsSettingsPopup();
		closeModeSettingsPopup();
		closeValueSettingsPopup();
		closeMusicSettingsPopup();
		activeMusicSettingsPopup = new EditorMusicSettingsPopup(this, target);
	}

	public function closeMusicSettingsPopup():Void {
		if (activeMusicSettingsPopup != null) {
			var popup = activeMusicSettingsPopup;
			activeMusicSettingsPopup = null;
			popup.remove();
		}
	}

	public function musicSettingsPopupRemoved(popup:EditorMusicSettingsPopup):Void {
		if (activeMusicSettingsPopup == popup) {
			activeMusicSettingsPopup = null;
		}
	}

	public function openModeSettingsMenu(target:DisplayObject):Void {
		closeItemSettingsPopup();
		closeHatsSettingsPopup();
		closeMusicSettingsPopup();
		closeValueSettingsPopup();
		closeModeSettingsPopup();
		activeModeSettingsPopup = new EditorModeSettingsPopup(this, target);
	}

	public function closeModeSettingsPopup():Void {
		if (activeModeSettingsPopup != null) {
			var popup = activeModeSettingsPopup;
			activeModeSettingsPopup = null;
			popup.remove();
		}
	}

	public function modeSettingsPopupRemoved(popup:EditorModeSettingsPopup):Void {
		if (activeModeSettingsPopup == popup) {
			activeModeSettingsPopup = null;
		}
	}

	public function openValueSettingsMenu(settingId:String, target:DisplayObject):Void {
		closeItemSettingsPopup();
		closeHatsSettingsPopup();
		closeMusicSettingsPopup();
		closeModeSettingsPopup();
		closeValueSettingsPopup();
		activeValueSettingsPopup = new EditorValueSettingsPopup(this, target, settingId);
	}

	public function closeValueSettingsPopup():Void {
		if (activeValueSettingsPopup != null) {
			var popup = activeValueSettingsPopup;
			activeValueSettingsPopup = null;
			popup.remove();
		}
	}

	public function valueSettingsPopupRemoved(popup:EditorValueSettingsPopup):Void {
		if (activeValueSettingsPopup == popup) {
			activeValueSettingsPopup = null;
		}
	}

	public function openBrushSizeMenu(target:EditorBrushSizePickerButton):Void {
		closeBrushSizeMenu();
		activeBrushSizeMenu = new EditorBrushSizePickerMenu(this, target);
		addChild(activeBrushSizeMenu);
	}

	public function closeBrushSizeMenu():Void {
		if (activeBrushSizeMenu != null) {
			var menu = activeBrushSizeMenu;
			activeBrushSizeMenu = null;
			menu.remove();
		}
	}

	public function brushSizeMenuRemoved(menu:EditorBrushSizePickerMenu):Void {
		if (activeBrushSizeMenu == menu) {
			activeBrushSizeMenu = null;
		}
	}

	public function beginSelectedBrushAt(stageX:Float, stageY:Float):Bool {
		if (activeDrawLayer == null || selectedToolSidebar != "tools" || (selectedToolId != "brush" && selectedToolId != "eraser")) {
			return false;
		}
		drawingLayer = activeDrawLayer;
		var isEraser = selectedToolId == "eraser";
		drawingLayer.beginStroke(stageX, stageY, isEraser ? "erase" : "draw", brushSize, isEraser ? 0xFFFFFF : brushColor);
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

	public function isDrawing():Bool {
		return drawingLayer != null && drawingLayer.isDrawing();
	}

	public function undoActiveObjectLayer():Bool {
		var changed = false;
		if (blockLayer != null && isBlockHistoryActive()) {
			changed = blockLayer.undo();
		} else if (activeDrawLayer != null && selectedToolSidebar == "tools") {
			changed = activeDrawLayer.undo();
		} else if (activeObjectLayer != null) {
			changed = activeObjectLayer.undo();
		}
		if (menu != null) {
			menu.updateUndoRedoState();
		}
		return changed;
	}

	public function redoActiveObjectLayer():Bool {
		var changed = false;
		if (blockLayer != null && isBlockHistoryActive()) {
			changed = blockLayer.redo();
		} else if (activeDrawLayer != null && selectedToolSidebar == "tools") {
			changed = activeDrawLayer.redo();
		} else if (activeObjectLayer != null) {
			changed = activeObjectLayer.redo();
		}
		if (menu != null) {
			menu.updateUndoRedoState();
		}
		return changed;
	}

	override public function remove():Void {
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
			closeBlockOptionsPopup();
			closeItemSettingsPopup();
			closeHatsSettingsPopup();
			closeMusicSettingsPopup();
			closeModeSettingsPopup();
			closeValueSettingsPopup();
			closeBrushSizeMenu();
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
		applyLayerPositions();
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
		if (stage == null) {
			return;
		}
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		stage.addEventListener(Event.DEACTIVATE, clearPressedKeys);
		stage.addEventListener(FocusEvent.FOCUS_OUT, clearPressedKeys);
	}

	private function detachKeyboardListeners(?_:Event):Void {
		if (stage == null) {
			return;
		}
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
		if (blockLayer != null) {
			positionLayer(blockLayer, 1);
		}
		for (layer in drawLayers) {
			positionLayer(layer, layer.scaleX);
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
		if (menu != null && menu.hitTestPoint(event.stageX, event.stageY, true)) {
			return;
		}
		if (beginSelectedBrushAt(event.stageX, event.stageY)) {
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
		if (deleteSelectedBlockAt(event.stageX, event.stageY)) {
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
			return;
		}
		if (deletingObjects && deleteSelectedObjectAt(event.stageX, event.stageY)) {
			event.stopImmediatePropagation();
		}
	}

	private function stopSelectedToolFromMouse(event:MouseEvent):Void {
		if (endSelectedBrush()) {
			event.stopImmediatePropagation();
		}
		deletingObjects = false;
	}

	private function isBlockHistoryActive():Bool {
		return selectedToolSidebar == "blocks" || (menu != null && menu.sideBar == menu.blocks);
	}

	private function passHash():String {
		if (pass == null || pass == "" || StringTools.replace(pass, "*", "") == "") {
			return "";
		}
		return Md5.encode(pass + ServerConfig.LEVEL_PASS_SALT);
	}

	private function loadDrawLayersFromData(rawData:String):Void {
		var sections = rawData.split("`");
		var drawSections = [section(sections, 6), section(sections, 7), section(sections, 8), section(sections, 12), section(sections, 13)];
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
		if (value == null || value == "") {
			return fallback;
		}
		var parsed = Std.parseFloat(value);
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	private static function parseInt(value:Null<String>, fallback:Int):Int {
		if (value == null || value == "") {
			return fallback;
		}
		var parsed = Std.parseInt(value);
		return parsed == null ? fallback : parsed;
	}

	private static function section(sections:Array<String>, index:Int):String {
		return index < sections.length ? sections[index] : "";
	}
}

class TestCoursePage extends Page {
	private static inline var TEST_STATS_TOTAL:Int = 300;
	private static inline var TEST_STATS_X:Float = 10;
	private static inline var TEST_STATS_Y:Float = 290;
	private static inline var TEST_STATS_SCALE:Float = 0.66;
	private static inline var TEST_HAT_X:Float = 15;
	private static inline var TEST_HAT_Y:Float = 265;
	private static inline var TEST_HAT_SCALE:Float = 0.7;

	public final variables:Map<String, String>;
	public final isMod:Bool;
	public final reportsMode:Bool;
	public var course(default, null):Null<Course>;
	public var art(default, null):Null<PR2MovieClip>;
	public var statsSelect(default, null):Null<StatsSelect>;
	public var hatPicker(default, null):Null<TestCourseHatPicker>;
	private var bindings:Array<Binding> = [];

	public function new(variables:Map<String, String>, mod:Bool = false, report:Bool = false) {
		super();
		this.variables = LevelEditor.copyVars(variables);
		isMod = mod;
		reportsMode = report;
	}

	override public function initialize():Void {
		super.initialize();
		mountCourse();
		art = PR2MovieClip.fromLinkage("TestCourseGraphic", {maxNestedDepth: 6});
		addChild(art);
		bind("back_bt", clickBack);
		bind("restart_bt", clickRestart);
		stackOverlayControls();
	}

	override public function remove():Void {
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		if (statsSelect != null) {
			statsSelect.remove();
			statsSelect = null;
		}
		if (hatPicker != null) {
			hatPicker.remove();
			hatPicker = null;
		}
		if (course != null) {
			course.remove();
			course = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private function mountCourse():Void {
		var data = new ServerLevelData(variables, true);
		var level = ServerLevelDecoder.decode(data.data);
		course = new Course(level, data, LevelConfig.fromServerData(data));
		addChildAt(course, 0);
		mountStatsSelect();
		mountHatPicker();
		course.beginRace();
	}

	private function mountStatsSelect():Void {
		if (course == null || course.localCharacter == null) {
			return;
		}
		if (statsSelect != null) {
			statsSelect.remove();
			statsSelect = null;
		}
		var savedStats:Dynamic = Settings.getValue(Settings.LE_TEST_STATS, Settings.DEFAULT_LE_TEST_STATS);
		var speed = parseStatField(savedStats, "speed", Settings.DEFAULT_LE_TEST_STATS.speed);
		var acceleration = parseStatField(savedStats, "acceleration", Settings.DEFAULT_LE_TEST_STATS.acceleration);
		var jumping = parseStatField(savedStats, "jumping", Settings.DEFAULT_LE_TEST_STATS.jumping);
		statsSelect = new StatsSelect(TEST_STATS_TOTAL, speed, acceleration, jumping, course.localCharacter);
		statsSelect.x = TEST_STATS_X;
		statsSelect.y = TEST_STATS_Y;
		statsSelect.scaleX = statsSelect.scaleY = TEST_STATS_SCALE;
		addChild(statsSelect);
	}

	private function mountHatPicker():Void {
		if (course == null || course.localCharacter == null) {
			return;
		}
		if (hatPicker != null) {
			hatPicker.remove();
			hatPicker = null;
		}
		hatPicker = new TestCourseHatPicker(course.localCharacter);
		hatPicker.x = TEST_HAT_X;
		hatPicker.y = TEST_HAT_Y;
		hatPicker.scaleX = hatPicker.scaleY = TEST_HAT_SCALE;
		addChild(hatPicker);
	}

	private function stackOverlayControls():Void {
		if (art != null) {
			addChild(art);
		}
		if (statsSelect != null) {
			addChild(statsSelect);
		}
		if (hatPicker != null) {
			addChild(hatPicker);
		}
	}

	private function bind(name:String, handler:Void->Void):Void {
		var target = art == null ? null : DisplayUtil.findByName(art, name);
		var binding = LobbyArt.bind(target, handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	private function clickBack():Void {
		if (pageHolder != null) {
			pageHolder.changePage(new LevelEditor(variables, isMod, reportsMode));
		}
	}

	private function clickRestart():Void {
		if (statsSelect != null) {
			statsSelect.remove();
			statsSelect = null;
		}
		if (hatPicker != null) {
			hatPicker.remove();
			hatPicker = null;
		}
		if (course != null) {
			course.remove();
			course = null;
		}
		mountCourse();
		stackOverlayControls();
	}

	private static function parseStatField(stats:Dynamic, field:String, fallback:Int):Int {
		var value:Dynamic = stats == null ? null : Reflect.field(stats, field);
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? fallback : parsed;
	}
}

class TestCourseHatPicker extends Sprite {
	private static inline var MIN_HAT:Int = 1;
	private static inline var MAX_HAT:Int = 16;
	private static inline var ARTIFACT_HAT:Int = 14;
	private static inline var DEFAULT_HAT:Int = 2;

	private var localCharacter:Null<LocalCharacter>;
	private var art:Null<PR2MovieClip>;
	private var bindings:Array<Binding> = [];
	public var pickedHat(default, null):Int = DEFAULT_HAT;

	public function new(localCharacter:LocalCharacter) {
		super();
		this.localCharacter = localCharacter;
		art = PR2MovieClip.fromLinkage("HatPickerGraphic", {maxNestedDepth: 6});
		addChild(art);
		var arrows = Std.downcast(DisplayUtil.findByName(art, "var_173"), PR2MovieClip);
		bind(arrows, "left", clickLeft);
		bind(arrows, "right", clickRight);
		pickedHat = normalizeHat(parseInt(Std.string(Settings.getValue(Settings.LE_TEST_HAT, DEFAULT_HAT)), DEFAULT_HAT));
		display();
	}

	public function resetHat():Void {
		if (localCharacter == null) {
			return;
		}
		var color = localCharacter.hat1Color;
		var color2 = localCharacter.hat1Color2;
		localCharacter.setHats([]);
		localCharacter.setHats([pickedHat, color, color2]);
	}

	public function remove():Void {
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		localCharacter = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function bind(container:Null<PR2MovieClip>, name:String, handler:Void->Void):Void {
		var target = container == null ? null : DisplayUtil.findByName(container, name);
		var binding = LobbyArt.bind(target, handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	private function clickLeft():Void {
		pickedHat--;
		if (pickedHat == ARTIFACT_HAT) {
			pickedHat = ARTIFACT_HAT - 1;
		}
		if (pickedHat < MIN_HAT) {
			pickedHat = MAX_HAT;
		}
		display();
	}

	private function clickRight():Void {
		pickedHat++;
		if (pickedHat == ARTIFACT_HAT) {
			pickedHat = ARTIFACT_HAT + 1;
		}
		if (pickedHat > MAX_HAT) {
			pickedHat = MIN_HAT;
		}
		display();
	}

	private function display():Void {
		var hat = Std.downcast(DisplayUtil.findByName(art, "hat"), PR2MovieClip);
		if (hat != null) {
			hat.gotoAndStop(pickedHat);
			var colorMC = Std.downcast(DisplayUtil.findByName(hat, "colorMC"), PR2MovieClip);
			if (colorMC != null) {
				colorMC.gotoAndStop(pickedHat);
			}
			var colorMC2 = Std.downcast(DisplayUtil.findByName(hat, "colorMC2"), PR2MovieClip);
			if (colorMC2 != null) {
				colorMC2.gotoAndStop(pickedHat);
				colorMC2.visible = pickedHat == MAX_HAT;
			}
		}
		var color = Math.round(Math.random() * 0xFFFFFF);
		var color2 = 0;
		if (localCharacter != null) {
			localCharacter.setHats([pickedHat, color, color2]);
		}
		Settings.setValue(Settings.LE_TEST_HAT, pickedHat);
	}

	private static function normalizeHat(hatId:Int):Int {
		if (hatId == ARTIFACT_HAT) {
			return ARTIFACT_HAT + 1;
		}
		if (hatId < MIN_HAT || hatId > MAX_HAT) {
			return DEFAULT_HAT;
		}
		return hatId;
	}

	private static function parseInt(value:Null<String>, fallback:Int):Int {
		if (value == null || value == "") {
			return fallback;
		}
		var parsed = Std.parseInt(value);
		return parsed == null ? fallback : parsed;
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
		bind("undoButton", clickUndo);
		bind("redoButton", clickRedo);
		bind("saveButton", clickSave);
		bind("loadButton", clickLoad);
		bind("testButton", clickTest);
		var zoomSelect = zoomCombo();
		if (zoomSelect != null) {
			zoomSelect.addEventListener(Event.CHANGE, chooseZoom);
			zoomSelect.selectedIndex = 3;
		} else {
			Reflect.setProperty(find("zoomSelect"), "selectedIndex", 3);
		}
		editor.setZoom(1);
		updateUndoRedoState();
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
		var zoomSelect = zoomCombo();
		if (zoomSelect != null) {
			zoomSelect.removeEventListener(Event.CHANGE, chooseZoom);
		}
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

	private function zoomCombo():Null<FlComboBox> {
		return Std.downcast(find("zoomSelect"), FlComboBox);
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

	private function clickUndo():Void {
		editor.undoActiveObjectLayer();
		updateUndoRedoState();
	}

	private function clickRedo():Void {
		editor.redoActiveObjectLayer();
		updateUndoRedoState();
	}

	private function clickSave():Void {
		new SaveLevelPopup(editor);
	}

	private function clickLoad():Void {
		if (editor.isMod) {
			new ChooseLevelsModePopup();
		} else {
			new GetLevelsPopup();
		}
	}

	private function clickTest():Void {
		if (editor.pageHolder != null) {
			editor.pageHolder.changePage(new TestCoursePage(editor.getLevelVars(), editor.isMod, editor.reportsMode));
		}
	}

	private function chooseZoom(_):Void {
		var combo = zoomCombo();
		if (combo == null || combo.selectedItem == null) {
			return;
		}
		var data = Std.string(Reflect.field(combo.selectedItem, "data"));
		var percent = Std.parseFloat(data);
		if (Math.isNaN(percent)) {
			return;
		}
		editor.setZoom(percent / 100);
		if (editor.stage != null) {
			editor.stage.focus = editor.stage;
		}
	}

	public function updateUndoRedoState():Void {
		if (editor.blockLayer != null && (editor.selectedToolSidebar == "blocks" || sideBar == blocks)) {
			Reflect.setProperty(find("undoButton"), "enabled", editor.blockLayer.saveArray.length > 0);
			Reflect.setProperty(find("redoButton"), "enabled", editor.blockLayer.redoArray.length > 0);
			return;
		}
		if (editor.selectedToolSidebar == "tools" && editor.activeDrawLayer != null) {
			Reflect.setProperty(find("undoButton"), "enabled", editor.activeDrawLayer.saveArray.length > 0);
			Reflect.setProperty(find("redoButton"), "enabled", editor.activeDrawLayer.redoArray.length > 0);
			return;
		}
		var activeLayer = editor.activeObjectLayer;
		Reflect.setProperty(find("undoButton"), "enabled", activeLayer != null && activeLayer.saveArray.length > 0);
		Reflect.setProperty(find("redoButton"), "enabled", activeLayer != null && activeLayer.redoArray.length > 0);
	}

	public function updateBackgroundColor():Void {
		bg.updateColor();
	}

	private function setLayer(layerNum:Int):Void {
		if (sideBar != stamps && sideBar != tools) {
			changeSideBar(stamps);
		}
		editor.setActiveObjectLayer(layerNum);
		updateUndoRedoState();
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

typedef SaveLevelUploadFactory = LevelEditor->Null<Popup>;
typedef GetLevelsPostFactory = String->Map<String, String>->(Dynamic->Void)->(String->Void)->Void;
typedef GetLevelsLoadFactory = Int->Int->Void;
typedef LoadingLevelFetchFactory = Int->Int->(ServerLevelData->Void)->(String->Void)->Void;
typedef UploadingLevelPostFactory = String->Map<String, String>->String->(Dynamic->Void)->(String->Void)->Null<UploadingPopup>;
typedef UploadingLevelRetryFactory = (Void->Void)->Int->Null<Timer>;
typedef DeleteLevelPostFactory = String->Map<String, String>->String->(Dynamic->Void)->(String->Void)->Null<UploadingPopup>;
typedef HandleLevelReportUploadFactory = String->Map<String, String>->String->(Dynamic->Void)->(String->Void)->Null<UploadingPopup>;
typedef HandleLevelReportReopenFactory = Void->Void;

class ChooseLevelsModePopup extends Popup {
	public final art:PR2MovieClip;
	private var bindings:Array<Binding> = [];

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("ChooseLevelsModePopupGraphic", {maxNestedDepth: 5});
		addChild(art);
		bind("reports_bt", clickReports);
		bind("mine_bt", clickMine);
		bind("cancel_bt", function():Void startFadeOut());
	}

	private function clickReports():Void {
		new GetReportedLevelsPopup();
		startFadeOut();
	}

	private function clickMine():Void {
		new GetLevelsPopup();
		startFadeOut();
	}

	private function bind(name:String, handler:Void->Void):Void {
		var binding = LobbyArt.bind(DisplayUtil.findByName(art, name), handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	override public function remove():Void {
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		art.dispose();
		super.remove();
	}
}

class GetLevelsPopup extends Popup {
	public static var postFactory:GetLevelsPostFactory = defaultPost;
	public static var loadFactory:GetLevelsLoadFactory = defaultLoad;

	public final art:PR2MovieClip;
	public final listings:Array<GetLevelsPopupItem> = [];
	public var selected(default, null):Null<GetLevelsPopupItem>;
	private var bindings:Array<Binding> = [];
	private var scroll:Null<CustomScrollBar>;

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("GetLevelsPopupGraphic", {maxNestedDepth: 6});
		addChild(art);
		scroll = new CustomScrollBar();
		scroll.x = 119;
		scroll.y = -86;
		addChild(scroll);
		var holder = levelsHolder();
		if (holder != null) {
			scroll.init(holder, 160, 158);
		}
		setText("titleBox", "-- My Levels --");
		bind("cancel_bt", function():Void startFadeOut());
		bind("load_bt", clickLoad);
		bind("delete_bt", clickDelete);
		updateButtons();
		postFactory(ServerConfig.levelsGetUrl(), requestFields(), handleResponse, handleError);
	}

	public function selectListing(listing:Null<GetLevelsPopupItem>):Void {
		selected = listing;
		for (item in listings) {
			item.setSelected(item == selected);
		}
		updateButtons();
	}

	public function loadSelected():Void {
		clickLoad();
	}

	private function handleResponse(ret:Dynamic):Void {
		var levels:Dynamic = ret == null ? null : Reflect.field(ret, "levels");
		if (Std.isOfType(levels, Array)) {
			for (level in cast(levels, Array<Dynamic>)) {
				addListing(new GetLevelsPopupItem(level, this));
			}
		}
		hideLoadingGraphic();
	}

	private function handleError(message:String):Void {
		hideLoadingGraphic();
		if (message != null && message != "") {
			new MessagePopup("Error: " + message);
		}
	}

	private function addListing(listing:GetLevelsPopupItem):Void {
		listing.y = listings.length * 18;
		var holder = levelsHolder();
		if (holder != null) {
			holder.addChild(listing);
		}
		listings.push(listing);
	}

	private function clickLoad():Void {
		if (selected == null) {
			return;
		}
		loadFactory(selected.levelId, selected.version);
		startFadeOut();
	}

	private function clickDelete():Void {
		if (selected == null) {
			return;
		}
		var listing = selected;
		new ConfirmPopup(function():Void {
			new DeletingLevelPopup(listing.levelId);
			startFadeOut();
		}, 'Are you sure you want to delete "' + ChatText.escapeString(listing.title) + '"?');
	}

	private function updateButtons():Void {
		Reflect.setProperty(DisplayUtil.findByName(art, "load_bt"), "enabled", selected != null);
		Reflect.setProperty(DisplayUtil.findByName(art, "delete_bt"), "enabled", selected != null);
	}

	private function hideLoadingGraphic():Void {
		var loading = DisplayUtil.findByName(art, "loadingGraphic");
		if (loading != null && loading.parent != null) {
			loading.parent.removeChild(loading);
		}
	}

	private function levelsHolder():Null<DisplayObjectContainer> {
		return Std.downcast(DisplayUtil.findByName(art, "levelsHolder"), DisplayObjectContainer);
	}

	private function setText(name:String, value:String):Void {
		var field = LobbyArt.text(art, name);
		if (field != null) {
			field.text = value;
		}
	}

	private function bind(name:String, handler:Void->Void):Void {
		var binding = LobbyArt.bind(DisplayUtil.findByName(art, name), handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	override public function remove():Void {
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		for (listing in listings.copy()) {
			listing.remove();
		}
		listings.resize(0);
		selected = null;
		if (scroll != null) {
			scroll.remove();
			scroll = null;
		}
		art.dispose();
		super.remove();
	}

	private static function requestFields():Map<String, String> {
		var fields = new Map<String, String>();
		fields.set("token", LobbySession.token);
		return fields;
	}

	private static function defaultPost(url:String, fields:Map<String, String>, onResult:Dynamic->Void, onError:String->Void):Void {
		FormPostClient.post(url, fields, function(body:String):Void {
			if (body == null || body == "") {
				onResult({levels: []});
				return;
			}
			try {
				onResult(Json.parse(body));
			} catch (_:Dynamic) {
				onError("The loaded data was not in the expected format.");
			}
		}, onError);
	}

	private static function defaultLoad(levelId:Int, version:Int):Void {
		new LoadingLevelPopup(levelId, version);
	}
}

class LoadingLevelPopup extends Popup {
	public static var fetchFactory:LoadingLevelFetchFactory = defaultFetch;

	public var art(default, null):Null<PR2MovieClip>;
	public final levelId:Int;
	public final version:Int;
	public final report:Bool;
	private var closeBinding:Null<Binding>;
	private var progressBar:Null<ProgressBar>;

	public function new(levelId:Int, version:Int, report:Bool = false) {
		super();
		this.levelId = levelId;
		this.version = version;
		this.report = report;
		art = PR2MovieClip.fromLinkage("UploadingPopupGraphic", {maxNestedDepth: 4});
		var textBox = LobbyArt.text(art, "textBox");
		if (textBox != null) {
			textBox.text = "Loading level...";
		}
		addChild(art);
		progressBar = new ProgressBar();
		progressBar.x = -100;
		progressBar.y = -5;
		addChild(progressBar);
		closeBinding = LobbyArt.bind(DisplayUtil.findByName(art, "close_bt"), function():Void startFadeOut());
		fetchFactory(levelId, version, handleLoad, handleError);
	}

	private function handleLoad(data:ServerLevelData):Void {
		if (progressBar != null) {
			progressBar.setProgress(1);
		}
		if (LevelEditor.editor != null) {
			LevelEditor.editor.applyLoadedLevelData(data, report);
		}
		startFadeOut();
	}

	private function handleError(message:String):Void {
		if (progressBar != null) {
			progressBar.setProgress(1);
		}
		if (message != null && message != "") {
			new MessagePopup(message);
		}
		startFadeOut();
	}

	public static function defaultFetch(levelId:Int, version:Int, onResult:ServerLevelData->Void, onError:String->Void):Void {
		LevelDataClient.fetchEditorLoad(levelId, version, onResult, onError);
	}

	override public function remove():Void {
		LobbyArt.unbind(closeBinding);
		closeBinding = null;
		if (progressBar != null) {
			progressBar.remove();
			progressBar = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}

class GetLevelsPopupItem extends Sprite {
	public final level:Dynamic;
	public final levelId:Int;
	public final version:Int;
	public final title:String;
	public var art(default, null):PR2MovieClip;
	private var popup:Null<GetLevelsPopup>;
	private var info:Null<HoverPopup>;
	private var selected:Bool = false;

	public function new(level:Dynamic, popup:GetLevelsPopup) {
		super();
		this.level = level;
		this.popup = popup;
		art = PR2MovieClip.fromLinkage("GetLevelsPopupItemGraphic", {maxNestedDepth: 4});
		addChild(art);
		levelId = parseInt(field("level_id"), 0);
		version = parseInt(field("version"), 0);
		title = field("title");
		setText("titleBox", title);
		setText("statusBox", parseInt(field("live"), 0) == 1 ? "Published" : "Unpublished");
		mouseChildren = false;
		buttonMode = true;
		doubleClickEnabled = true;
		addEventListener(MouseEvent.CLICK, onClick);
		addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
		addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}

	public function setSelected(on:Bool):Void {
		selected = on;
		var glow = DisplayUtil.findByName(art, "selectedGlow");
		if (glow != null) {
			glow.visible = on;
		}
		alpha = on ? 1 : 0.92;
	}

	private function onClick(_:MouseEvent):Void {
		if (popup != null) {
			popup.selectListing(this);
		}
	}

	private function onDoubleClick(_:MouseEvent):Void {
		if (popup != null) {
			popup.selectListing(this);
			popup.loadSelected();
		}
	}

	private function onMouseOver(_:MouseEvent):Void {
		var title = "-- " + ChatText.escapeString(field("title")) + " --";
		var popText = "Game Mode: " + modeName(field("type")) + "<br/>";
		popText += "Version: " + version + "<br/>";
		popText += "Plays: " + field("play_count") + "<br/>";
		popText += "Rating: " + field("rating");
		var note = StringTools.trim(field("note"));
		if (note != "") {
			popText += "<br/>-----<br/><i>" + ChatText.escapeString(note) + "</i>";
		}
		info = new HoverPopup(title, popText, art);
		info.x = 550 - info.width;
	}

	private function onMouseOut(_:MouseEvent = null):Void {
		if (info != null) {
			info.remove();
			info = null;
		}
	}

	public function remove():Void {
		onMouseOut();
		removeEventListener(MouseEvent.CLICK, onClick);
		removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
		removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		popup = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function setText(name:String, value:String):Void {
		var text = LobbyArt.text(art, name);
		if (text != null) {
			text.text = value;
		}
	}

	private function field(name:String):String {
		var value = level == null ? null : Reflect.field(level, name);
		return value == null ? "" : Std.string(value);
	}

	private static function parseInt(value:String, fallback:Int):Int {
		var parsed = Std.parseInt(value);
		return parsed == null ? fallback : parsed;
	}

	private static function modeName(mode:String):String {
		return switch (mode) {
			case "d", "deathmatch": "Deathmatch";
			case "o", "objective": "Objective";
			case "h", "hat": "Hat Attack";
			case "e", "egg", "eggs": "Egg";
			default: "Race";
		}
	}
}

class GetReportedLevelsPopup extends Popup {
	public static var postFactory:GetLevelsPostFactory = defaultPost;
	public static var loadFactory:GetLevelsLoadFactory = defaultLoad;

	public final art:PR2MovieClip;
	public final listings:Array<GetReportedLevelsPopupItem> = [];
	public var selected(default, null):Null<GetReportedLevelsPopupItem>;
	private var bindings:Array<Binding> = [];

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("GetLevelsPopupGraphic", {maxNestedDepth: 6});
		addChild(art);
		setText("titleBox", "-- Reported Levels --");
		var handle = DisplayUtil.findByName(art, "delete_bt");
		Reflect.setProperty(handle, "label", "Handle");
		bind("cancel_bt", function():Void startFadeOut());
		bind("load_bt", clickLoad);
		bind("delete_bt", clickHandle);
		updateButtons();
		postFactory(ServerConfig.levelsGetReportedUrl(), requestFields(), handleResponse, handleError);
	}

	public function selectListing(listing:Null<GetReportedLevelsPopupItem>):Void {
		selected = listing;
		for (item in listings) {
			item.setSelected(item == selected);
		}
		updateButtons();
	}

	public function loadSelected():Void {
		clickLoad();
	}

	private function handleResponse(ret:Dynamic):Void {
		var levels:Dynamic = ret == null ? null : Reflect.field(ret, "levels");
		if (Std.isOfType(levels, Array)) {
			for (level in cast(levels, Array<Dynamic>)) {
				addListing(new GetReportedLevelsPopupItem(level, this));
			}
		}
		hideLoadingGraphic();
	}

	private function handleError(message:String):Void {
		hideLoadingGraphic();
		if (message != null && message != "") {
			new MessagePopup("Error: " + message);
		}
	}

	private function addListing(listing:GetReportedLevelsPopupItem):Void {
		listing.y = listings.length * 18;
		var holder = levelsHolder();
		if (holder != null) {
			holder.addChild(listing);
		}
		listings.push(listing);
	}

	private function clickLoad():Void {
		if (selected == null) {
			return;
		}
		loadFactory(selected.levelId, selected.version);
		startFadeOut();
	}

	private function clickHandle():Void {
		if (selected == null) {
			return;
		}
		new HandleLevelReportPopup(this, selected.level);
	}

	private function updateButtons():Void {
		Reflect.setProperty(DisplayUtil.findByName(art, "load_bt"), "enabled", selected != null);
		Reflect.setProperty(DisplayUtil.findByName(art, "delete_bt"), "enabled", selected != null);
	}

	private function hideLoadingGraphic():Void {
		var loading = DisplayUtil.findByName(art, "loadingGraphic");
		if (loading != null && loading.parent != null) {
			loading.parent.removeChild(loading);
		}
	}

	private function levelsHolder():Null<DisplayObjectContainer> {
		return Std.downcast(DisplayUtil.findByName(art, "levelsHolder"), DisplayObjectContainer);
	}

	private function setText(name:String, value:String):Void {
		var field = LobbyArt.text(art, name);
		if (field != null) {
			field.text = value;
		}
	}

	private function bind(name:String, handler:Void->Void):Void {
		var binding = LobbyArt.bind(DisplayUtil.findByName(art, name), handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	override public function remove():Void {
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		for (listing in listings.copy()) {
			listing.remove();
		}
		listings.resize(0);
		selected = null;
		art.dispose();
		super.remove();
	}

	private static function requestFields():Map<String, String> {
		var fields = new Map<String, String>();
		fields.set("token", LobbySession.token);
		return fields;
	}

	private static function defaultPost(url:String, fields:Map<String, String>, onResult:Dynamic->Void, onError:String->Void):Void {
		FormPostClient.post(url, fields, function(body:String):Void {
			if (body == null || body == "") {
				onResult({levels: []});
				return;
			}
			try {
				onResult(Json.parse(body));
			} catch (_:Dynamic) {
				onError("The loaded data was not in the expected format.");
			}
		}, onError);
	}

	private static function defaultLoad(levelId:Int, version:Int):Void {
		new LoadingLevelPopup(levelId, version, true);
	}
}

class GetReportedLevelsPopupItem extends Sprite {
	private static final MONTHS:Array<String> = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sept", "Oct", "Nov", "Dec"];

	public final level:Dynamic;
	public final levelId:Int;
	public final version:Int;
	public final title:String;
	public var art(default, null):PR2MovieClip;
	private var popup:Null<GetReportedLevelsPopup>;
	private var info:Null<HoverPopup>;

	public function new(level:Dynamic, popup:GetReportedLevelsPopup) {
		super();
		this.level = level;
		this.popup = popup;
		art = PR2MovieClip.fromLinkage("GetReportedLevelsPopupItemGraphic", {maxNestedDepth: 4});
		addChild(art);
		levelId = parseInt(field("level_id"), 0);
		version = parseInt(field("version"), 0);
		title = field("title");
		setText("titleBox", title);
		setText("timeBox", shortDate(parseFloat(field("report_time"), 0)));
		mouseChildren = false;
		buttonMode = true;
		doubleClickEnabled = true;
		addEventListener(MouseEvent.CLICK, onClick);
		addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
		addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}

	public function setSelected(on:Bool):Void {
		alpha = on ? 1 : 0.92;
		if (art != null) {
			art.gotoAndStop(on ? "selected" : "up");
		}
	}

	private function onClick(_:MouseEvent):Void {
		if (popup != null) {
			popup.selectListing(this);
		}
	}

	private function onDoubleClick(_:MouseEvent):Void {
		if (popup != null) {
			popup.selectListing(this);
			popup.loadSelected();
		}
	}

	private function onMouseOver(_:MouseEvent):Void {
		var levelTitle = "-- " + ChatText.escapeString(title) + " --";
		var popText = "Creator: " + ChatText.escapeString(field("creator")) + "<br/>";
		popText += "Version: " + version;
		var note = StringTools.trim(field("note"));
		if (note != "") {
			popText += "<br/>Note: <i>" + ChatText.escapeString(note) + "</i>";
		}
		popText += "<br/>-----<br/>";
		popText += "Reported: " + fieldText("timeBox") + "<br/>";
		popText += "^ By: " + ChatText.escapeString(field("reporter")) + "<br/>";
		popText += "Reason: <i>" + ChatText.escapeString(field("reason")) + "</i>";
		info = new HoverPopup(levelTitle, popText, art);
		info.width -= 3;
		info.x = 550 - info.width;
	}

	private function onMouseOut(_:MouseEvent = null):Void {
		if (info != null) {
			info.remove();
			info = null;
		}
	}

	public function remove():Void {
		onMouseOut();
		removeEventListener(MouseEvent.CLICK, onClick);
		removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
		removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		popup = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function setText(name:String, value:String):Void {
		var text = LobbyArt.text(art, name);
		if (text != null) {
			text.text = value;
		}
	}

	private function fieldText(name:String):String {
		var text = LobbyArt.text(art, name);
		return text == null ? "" : text.text;
	}

	private function field(name:String):String {
		var value = level == null ? null : Reflect.field(level, name);
		return value == null ? "" : Std.string(value);
	}

	private static function parseInt(value:String, fallback:Int):Int {
		var parsed = Std.parseInt(value);
		return parsed == null ? fallback : parsed;
	}

	private static function parseFloat(value:String, fallback:Float):Float {
		var parsed = Std.parseFloat(value);
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	private static function shortDate(time:Float):String {
		var d = Date.fromTime(time * 1000);
		return d.getDate() + "/" + MONTHS[d.getMonth()] + "/" + d.getFullYear();
	}
}

class HandleLevelReportPopup extends Popup {
	private static final MONTHS:Array<String> = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sept", "Oct", "Nov", "Dec"];

	public static var uploadFactory:HandleLevelReportUploadFactory = defaultUpload;
	public static var reopenFactory:HandleLevelReportReopenFactory = defaultReopen;

	public final reportsPopup:GetReportedLevelsPopup;
	public final level:Dynamic;
	public var art(default, null):Null<PR2MovieClip>;
	private var htmlNameMaker:HtmlNameMaker = new HtmlNameMaker();
	private var bindings:Array<Null<Binding>> = [];
	private var uploading:Null<UploadingPopup>;
	private var banRet:Dynamic = null;
	private var info:Null<HoverPopup>;

	public function new(reportsPopup:GetReportedLevelsPopup, level:Dynamic) {
		super();
		this.reportsPopup = reportsPopup;
		this.level = level;
		art = PR2MovieClip.fromLinkage("HandleLevelReportPopupGraphic", {maxNestedDepth: 6});
		addChild(art);
		var titleBox = LobbyArt.text(art, "titleBox");
		if (titleBox != null) {
			htmlNameMaker.listenForLink(titleBox);
			titleBox.htmlText = htmlNameMaker.makeLevel(field("title"), levelId()) + " by "
				+ htmlNameMaker.makeName(field("creator"), fieldOr("creator_group", "0"));
		}
		setOtherReasonMode(false);
		var reason = reasonCombo();
		if (reason != null) {
			reason.addEventListener(Event.CHANGE, checkIfSelectedOther);
		}
		bind("other_cancel_bt", function():Void setOtherReasonMode(false));
		bind("ban_bt", clickBan);
		bind("cancel_bt", function():Void startFadeOut());
		bind("archive_bt", clickArchive);
		bindMouse("info_bt", MouseEvent.MOUSE_OVER, addInfoHover);
		bindMouse("info_bt", MouseEvent.MOUSE_OUT, removeInfoHover);
	}

	private function addInfoHover(_:MouseEvent):Void {
		var title = "-- " + ChatText.escapeString(field("title")) + " --";
		var popText = "Creator: " + ChatText.escapeString(field("creator")) + "<br/>";
		popText += "Version: " + version();
		var note = StringTools.trim(field("note"));
		if (note != "") {
			popText += "<br/>Note: <i>" + ChatText.escapeString(note) + "</i>";
		}
		popText += "<br/>-----<br/>";
		popText += "Reported: " + shortDate(parseFloat(field("report_time"), 0)) + "<br/>";
		popText += "^ By: " + ChatText.escapeString(field("reporter")) + "<br/>";
		popText += "Reason: <i>" + ChatText.escapeString(field("reason")) + "</i>";
		var target = DisplayUtil.findByName(art, "info_bt");
		if (target != null) {
			info = new HoverPopup(title, popText, target);
			info.x += info.width + 23;
		}
	}

	private function removeInfoHover(?_:MouseEvent):Void {
		if (info != null) {
			info.remove();
			info = null;
		}
	}

	private function checkIfSelectedOther(_:Event):Void {
		var reason = reasonCombo();
		if (reason == null || reason.selectedIndex < reason.length - 1) {
			return;
		}
		setOtherReasonMode(true);
	}

	private function setOtherReasonMode(selectedOther:Bool):Void {
		var reason = reasonCombo();
		if (reason != null) {
			reason.selectedIndex = 0;
			reason.visible = !selectedOther;
		}
		var otherReason = DisplayUtil.findByName(art, "otherReasonBox");
		if (otherReason != null) {
			otherReason.visible = selectedOther;
		}
		var otherCancel = DisplayUtil.findByName(art, "other_cancel_bt");
		if (otherCancel != null) {
			otherCancel.visible = selectedOther;
		}
	}

	private function clickBan():Void {
		var reason = reportReason();
		if (reason == "") {
			new MessagePopup("Error: You must enter a reason for the ban.");
			return;
		}
		var duration = selectedDataInt(durationCombo(), 0);
		if (duration == 0) {
			new MessagePopup("Error: You must specify a ban length.");
			return;
		}
		new ConfirmPopup(banUser,
			"Are you sure you want to socially ban " + ChatText.escapeString(field("creator")) + "? This will also unpublish the reported level.");
	}

	private function banUser():Void {
		banRet = null;
		uploading = uploadFactory(ServerConfig.banUserUrl(), banFields(), "Unpublishing and banning...", function(ret:Dynamic):Void {
			banRet = ret;
			archiveReport();
		}, handleUploadError);
	}

	private function clickArchive():Void {
		new ConfirmPopup(archiveReport, "Are you sure you want to archive this report?");
	}

	private function archiveReport():Void {
		uploading = uploadFactory(ServerConfig.archiveReportUrl(), archiveFields(), "Archiving report...", archiveDone, handleUploadError);
	}

	private function archiveDone(_:Dynamic):Void {
		reportsPopup.startFadeOut();
		reopenFactory();
		if (banRet != null && Reflect.hasField(banRet, "message")) {
			new MessagePopup(Std.string(Reflect.field(banRet, "message")));
		}
		startFadeOut();
	}

	private function handleUploadError(message:String):Void {
		if (message != null && message != "") {
			new MessagePopup("Error: " + message);
		}
	}

	private function banFields():Map<String, String> {
		return [
			"level_id" => Std.string(levelId()),
			"banned_name" => field("creator"),
			"duration" => Std.string(selectedDataInt(durationCombo(), 0)),
			"reason" => "Inappropriate Level -- " + reportReason(),
			"scope" => "social",
			"record" => "Level ID: " + levelId() + "\nTitle: " + ChatText.escapeString(field("title")) + "\nNote: "
				+ ChatText.escapeString(field("note")) + "\nVersion: " + version()
		];
	}

	private function archiveFields():Map<String, String> {
		return [
			"level_id" => Std.string(levelId()),
			"version" => Std.string(version())
		];
	}

	private function reportReason():String {
		var reason = reasonCombo();
		if (reason == null || reason.selectedIndex == 0 || reason.selectedIndex == reason.length - 1) {
			return otherReasonText();
		}
		return selectedData(reason, "");
	}

	private function otherReasonText():String {
		var field = FlComponents.asTextField(DisplayUtil.findByName(art, "otherReasonBox"));
		return field == null ? "" : field.text;
	}

	private function reasonCombo():Null<FlComboBox> {
		return Std.downcast(DisplayUtil.findByName(art, "reason"), FlComboBox);
	}

	private function durationCombo():Null<FlComboBox> {
		return Std.downcast(DisplayUtil.findByName(art, "duration"), FlComboBox);
	}

	private static function selectedData(combo:Null<FlComboBox>, fallback:String):String {
		if (combo == null || combo.selectedItem == null) {
			return fallback;
		}
		var data:Dynamic = Reflect.field(combo.selectedItem, "data");
		return data == null ? fallback : Std.string(data);
	}

	private static function selectedDataInt(combo:Null<FlComboBox>, fallback:Int):Int {
		var parsed = Std.parseInt(selectedData(combo, Std.string(fallback)));
		return parsed == null ? fallback : parsed;
	}

	private function bind(name:String, handler:Void->Void):Void {
		bindings.push(LobbyArt.bind(DisplayUtil.findByName(art, name), handler));
	}

	private function bindMouse(name:String, type:String, handler:MouseEvent->Void):Void {
		var target = DisplayUtil.findByName(art, name);
		if (target != null) {
			target.addEventListener(type, handler);
		}
	}

	private function unbindMouse(name:String, type:String, handler:MouseEvent->Void):Void {
		var target = DisplayUtil.findByName(art, name);
		if (target != null) {
			target.removeEventListener(type, handler);
		}
	}

	private function field(name:String):String {
		return fieldOr(name, "");
	}

	private function fieldOr(name:String, fallback:String):String {
		var value = level == null ? null : Reflect.field(level, name);
		return value == null ? fallback : Std.string(value);
	}

	private function levelId():Int {
		return parseInt(field("level_id"), 0);
	}

	private function version():Int {
		return parseInt(field("version"), 0);
	}

	private static function parseInt(value:String, fallback:Int):Int {
		var parsed = Std.parseInt(value);
		return parsed == null ? fallback : parsed;
	}

	private static function parseFloat(value:String, fallback:Float):Float {
		var parsed = Std.parseFloat(value);
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	private static function shortDate(time:Float):String {
		var d = Date.fromTime(time * 1000);
		return d.getDate() + "/" + MONTHS[d.getMonth()] + "/" + d.getFullYear();
	}

	override public function remove():Void {
		removeInfoHover();
		var reason = reasonCombo();
		if (reason != null) {
			reason.removeEventListener(Event.CHANGE, checkIfSelectedOther);
		}
		unbindMouse("info_bt", MouseEvent.MOUSE_OVER, addInfoHover);
		unbindMouse("info_bt", MouseEvent.MOUSE_OUT, removeInfoHover);
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		if (uploading != null) {
			uploading.startFadeOut();
			uploading = null;
		}
		htmlNameMaker.remove();
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	public static function defaultUpload(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
			onError:String->Void):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label, onResult, onError);
	}

	public static function defaultReopen():Void {
		new GetReportedLevelsPopup();
	}
}

class SaveLevelPopup extends Popup {
	public static var uploadFactory:SaveLevelUploadFactory = defaultUpload;

	public final editor:LevelEditor;
	public var art(default, null):Null<PR2MovieClip>;
	private var bindings:Array<Binding> = [];

	public function new(editor:LevelEditor) {
		super();
		this.editor = editor;
		art = PR2MovieClip.fromLinkage("SaveLevelPopupGraphic", {maxNestedDepth: 6});
		addChild(art);
		var titleBox = titleField();
		if (titleBox != null) {
			titleBox.text = editor.title;
			titleBox.addEventListener(Event.CHANGE, countChars);
		}
		var noteBox = noteField();
		if (noteBox != null) {
			noteBox.text = editor.note;
			noteBox.addEventListener(Event.CHANGE, countChars);
		}
		var publish = publishCheck();
		var newest = newestCheck();
		if (editor.live == 1 && publish != null) {
			publish.selected = true;
			if (newest != null) {
				newest.enabled = true;
				newest.selected = editor.toNewest;
			}
		} else if (newest != null) {
			newest.enabled = false;
			newest.selected = false;
		}
		if (publish != null) {
			publish.addEventListener(Event.CHANGE, updateChks);
		}
		bind("cancel_bt", function():Void startFadeOut());
		bind("save_bt", clickSave);
		countChars();
	}

	private function countChars(?_:Event):Void {
		var titleCount = LobbyArt.text(art, "titleCharsRemaining");
		if (titleCount != null) {
			titleCount.text = fieldText(titleField()).length + " / 50";
		}
		var noteCount = LobbyArt.text(art, "noteCharsRemaining");
		if (noteCount != null) {
			noteCount.text = fieldText(noteField()).length + " / 255";
		}
	}

	private function updateChks(?_:Event):Void {
		var newest = newestCheck();
		if (newest == null) {
			return;
		}
		var selected = publishCheck() != null && publishCheck().selected;
		newest.enabled = selected;
		newest.selected = selected;
	}

	private function clickSave():Void {
		var title = fieldText(titleField());
		if (title == "") {
			new MessagePopup("I'm not sure what would happen if you didn't enter a title, but it would probably destroy the world.");
			return;
		}
		editor.title = title;
		editor.note = fieldText(noteField());
		editor.live = publishCheck() != null && publishCheck().selected ? 1 : 0;
		editor.toNewest = newestCheck() != null && newestCheck().selected;
		uploadFactory(editor);
		startFadeOut();
	}

	override public function remove():Void {
		var titleBox = titleField();
		if (titleBox != null) {
			titleBox.removeEventListener(Event.CHANGE, countChars);
		}
		var noteBox = noteField();
		if (noteBox != null) {
			noteBox.removeEventListener(Event.CHANGE, countChars);
		}
		var publish = publishCheck();
		if (publish != null) {
			publish.removeEventListener(Event.CHANGE, updateChks);
		}
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private function bind(name:String, handler:Void->Void):Void {
		var binding = LobbyArt.bind(DisplayUtil.findByName(art, name), handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	private function titleField():Null<TextField> {
		return LobbyArt.text(art, "titleBox");
	}

	private function noteField():Null<TextField> {
		return LobbyArt.text(art, "noteBox");
	}

	private function publishCheck():Null<FlCheckBox> {
		return Std.downcast(DisplayUtil.findByName(art, "publish_chk"), FlCheckBox);
	}

	private function newestCheck():Null<FlCheckBox> {
		return Std.downcast(DisplayUtil.findByName(art, "newest_chk"), FlCheckBox);
	}

	private static function fieldText(field:Null<TextField>):String {
		return field == null || field.text == null ? "" : field.text;
	}

	public static function defaultUpload(editor:LevelEditor):Null<Popup> {
		return new UploadingLevelPopup(editor);
	}
}

class UploadingLevelPopup extends Popup {
	public static var postFactory:UploadingLevelPostFactory = defaultPost;
	public static var retryFactory:UploadingLevelRetryFactory = defaultRetry;

	public final editor:LevelEditor;
	public final overrideBanConfirmed:Bool;
	public final overwriteExistingConfirmed:Bool;
	private var uploading:Null<UploadingPopup>;
	private var waitTimer:Null<Timer>;

	public function new(editor:LevelEditor, overrideBan:Bool = false, overwriteExisting:Bool = false) {
		super();
		this.editor = editor;
		overrideBanConfirmed = overrideBan;
		overwriteExistingConfirmed = overwriteExisting;
		if (uploadLevel()) {
			startFadeOut();
		}
	}

	private function uploadLevel():Bool {
		if (editor.isDrawing()) {
			clearWaitTimer();
			waitTimer = retryFactory(function():Void {
				waitTimer = null;
				if (uploadLevel()) {
					startFadeOut();
				}
			}, 1000);
			return false;
		}
		var fields = buildFields(editor, overrideBanConfirmed, overwriteExistingConfirmed);
		if (fields.get("data") == null || fields.get("data") == "") {
			new MessagePopup("The client is glitching out. Could not save your level.");
			return true;
		}
		uploading = postFactory(ServerConfig.uploadLevelUrl(), fields, "Uploading level...", handleResponse, handleUploadError);
		return true;
	}

	private function handleResponse(ret:Dynamic):Void {
		if (ret == null) {
			new MessagePopup("Error: The loaded data was not in the expected format.");
			return;
		}
		var message = Reflect.field(ret, "message");
		if (message != null) {
			new MessagePopup(Std.string(message));
		}
		var status = Reflect.field(ret, "status");
		if (status == "exists") {
			new ConfirmPopup(function():Void {
				new UploadingLevelPopup(editor, overrideBanConfirmed, true);
			}, "You have another level with this title. Is it okay to overwrite the existing level with this save?");
		} else if (status == "banned") {
			new ConfirmPopup(function():Void {
				new UploadingLevelPopup(editor, true, overwriteExistingConfirmed);
			}, bannedConfirmationMessage(ret));
		} else if (status != "banned" && failedResponse(ret)) {
			new MessagePopup("Error: " + errorMessage(ret));
		}
	}

	private function handleUploadError(message:String):Void {
		if (message != null && message != "") {
			new MessagePopup("Error: " + message);
		}
	}

	private static function failedResponse(ret:Dynamic):Bool {
		return Reflect.hasField(ret, "error") || (Reflect.hasField(ret, "success") && Reflect.field(ret, "success") != true);
	}

	private static function errorMessage(ret:Dynamic):String {
		if (Reflect.hasField(ret, "error")) {
			return Std.string(Reflect.field(ret, "error"));
		}
		return "An unknown error occurred. I suspect evil aliens.";
	}

	private static function bannedConfirmationMessage(ret:Dynamic):String {
		var banId = Reflect.hasField(ret, "ban_id") ? Std.string(Reflect.field(ret, "ban_id")) : "";
		var banLang = Reflect.field(ret, "scope") == "s" ? "socially " : "";
		var url = ServerConfig.getHost() + "/bans/show_record.php?ban_id=" + ChatText.escapeString(banId);
		var link = '<a href="' + ChatText.escapeString(url) + '" target="_blank"><u><font color="#0000FF">'
			+ banLang + "banned</font></u></a>";
		return "Because you are currently " + link
			+ ", you can only save this level as unpublished without a password. Is it okay to continue with these settings?";
	}

	public static function buildFields(editor:LevelEditor, overrideBan:Bool = false, overwriteExisting:Bool = false):Map<String, String> {
		var fields = LevelEditor.copyVars(editor.getLevelVars());
		var data = fields.get("data");
		if (data == null) {
			data = "";
		}
		var title = fields.get("title");
		if (title == null) {
			title = "";
		}
		fields.set("hash", Md5.encode(title + LobbySession.userName.toLowerCase() + data + ServerConfig.LEVEL_SALT));
		fields.set("to_newest", editor.toNewest ? "1" : "0");
		fields.set("override_banned", overrideBan ? "1" : "0");
		fields.set("overwrite_existing", overwriteExisting ? "1" : "0");
		fields.set("rand", Std.string(Std.random(10000000)));
		fields.set("token", LobbySession.token);
		return fields;
	}

	public static function defaultPost(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
			onError:String->Void):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label, onResult, onError);
	}

	public static function defaultRetry(callback:Void->Void, delayMs:Int):Null<Timer> {
		return Timer.delay(callback, delayMs);
	}

	private function clearWaitTimer():Void {
		if (waitTimer != null) {
			waitTimer.stop();
			waitTimer = null;
		}
	}

	override public function remove():Void {
		clearWaitTimer();
		super.remove();
	}
}

class DeletingLevelPopup {
	public static var postFactory:DeleteLevelPostFactory = defaultPost;

	public final levelId:Int;

	public function new(levelId:Int) {
		this.levelId = levelId;
		postFactory(ServerConfig.deleteLevelUrl(), requestFields(levelId), "Deleting level...", handleResponse, handleError);
	}

	private function handleResponse(_:Dynamic):Void {
		new GetLevelsPopup();
	}

	private function handleError(message:String):Void {
		if (message != null && message != "") {
			new MessagePopup("Error: " + message);
		}
	}

	private static function requestFields(levelId:Int):Map<String, String> {
		var fields = new Map<String, String>();
		fields.set("level_id", Std.string(levelId));
		fields.set("rand", Std.string(Std.random(10000000)));
		fields.set("token", LobbySession.token);
		return fields;
	}

	public static function defaultPost(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
			onError:String->Void):Null<UploadingPopup> {
		return new UploadingPopup(url, fields, label, onResult, onError);
	}
}

class EditorBlockLayer extends Sprite {
	public final editor:LevelEditor;
	public final blocks:Array<EditorBlockObject> = [];
	public final saveArray:Array<String> = [];
	public final redoArray:Array<String> = [];
	private final blocksBySeg:Map<String, EditorBlockObject> = new Map();
	private var initialSaveString:String = "";

	public function new(editor:LevelEditor) {
		super();
		this.editor = editor;
		name = "editorBlockLayer";
		for (code in ObjectCodes.BLOCK_START1...ObjectCodes.BLOCK_START4 + 1) {
			var start = addBlockAtLocal(code, BlockType.Start, code * LevelEditor.segSize + 10000, LevelEditor.segSize * 2 + 10000, false);
			start.deleteable = false;
		}
		initialSaveString = getSaveString();
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
		var block = addBlockAtLocal(code, type, point.x, point.y, true);
		recordSnapshot();
		return block;
	}

	public function getBlockAtSeg(segX:Int, segY:Int):Null<EditorBlockObject> {
		return blocksBySeg.get(segKey(segX, segY));
	}

	public function getBlockAtStage(stageX:Float, stageY:Float):Null<EditorBlockObject> {
		var point = globalToLocal(new Point(stageX - 15, stageY - 15));
		return getBlockAtSeg(Math.round(point.x / LevelEditor.segSize), Math.round(point.y / LevelEditor.segSize));
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
		if (record) {
			recordSnapshot();
		}
	}

	public function loadBlocks(decodedBlocks:Array<DecodedBlock>):Void {
		editor.selectBlock(null);
		while (blocks.length > 0) {
			removeBlock(blocks[blocks.length - 1], false);
		}
		blocksBySeg.clear();
		for (decoded in decodedBlocks) {
			var block = addBlockAtLocal(decoded.code, typeForCode(decoded.code), decoded.x, decoded.y, false, decoded.opts);
			block.deleteable = !isStartBlockCode(decoded.code);
		}
		initialSaveString = getSaveString();
		saveArray.resize(0);
		redoArray.resize(0);
		notifyHistoryChanged();
	}

	public function recordBlockOptionsChanged():Void {
		recordSnapshot();
	}

	public function undo():Bool {
		if (saveArray.length == 0) {
			return false;
		}
		var snapshot = saveArray.pop();
		if (snapshot != null) {
			redoArray.push(snapshot);
		}
		rebuildFromSaveString(saveArray.length == 0 ? initialSaveString : saveArray[saveArray.length - 1]);
		notifyHistoryChanged();
		return true;
	}

	public function redo():Bool {
		if (redoArray.length == 0) {
			return false;
		}
		var snapshot = redoArray.pop();
		if (snapshot != null) {
			saveArray.push(snapshot);
			rebuildFromSaveString(snapshot);
		}
		notifyHistoryChanged();
		return true;
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
		saveArray.resize(0);
		redoArray.resize(0);
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function addBlockAtLocal(code:Int, type:Null<BlockType>, localX:Float, localY:Float, select:Bool, options:String = ""):EditorBlockObject {
		var block = new EditorBlockObject(editor, code, type, snap(localX), snap(localY), options);
		blocks.push(block);
		blocksBySeg.set(segKey(block.segX, block.segY), block);
		addChild(block);
		if (select) {
			editor.selectBlock(block);
		}
		return block;
	}

	private function recordSnapshot():Void {
		var snapshot = getSaveString();
		var previous = saveArray.length == 0 ? initialSaveString : saveArray[saveArray.length - 1];
		if (snapshot == previous) {
			return;
		}
		saveArray.push(snapshot);
		redoArray.resize(0);
		notifyHistoryChanged();
	}

	private function rebuildFromSaveString(saveString:String):Void {
		editor.selectBlock(null);
		while (blocks.length > 0) {
			removeBlock(blocks[blocks.length - 1], false);
		}
		blocksBySeg.clear();
		for (decoded in ServerLevelDecoder.decodeBlocks("m4", saveString)) {
			var block = addBlockAtLocal(decoded.code, typeForCode(decoded.code), decoded.x, decoded.y, false, decoded.opts);
			block.deleteable = !isStartBlockCode(decoded.code);
		}
	}

	private function notifyHistoryChanged():Void {
		if (editor.menu != null) {
			editor.menu.updateUndoRedoState();
		}
	}

	private static inline function snap(value:Float):Int {
		return Std.int(Math.round(value / LevelEditor.segSize) * LevelEditor.segSize);
	}

	private static inline function segKey(segX:Int, segY:Int):String {
		return segX + ":" + segY;
	}

	private static function isStartBlockCode(code:Int):Bool {
		return code >= ObjectCodes.BLOCK_START1 && code <= ObjectCodes.BLOCK_START4;
	}

	private static function typeForCode(code:Int):Null<BlockType> {
		return switch (code) {
			case ObjectCodes.BLOCK_START1 | ObjectCodes.BLOCK_START2 | ObjectCodes.BLOCK_START3 | ObjectCodes.BLOCK_START4:
				BlockType.Start;
			case ObjectCodes.BLOCK_FINISH:
				BlockType.Finish;
			case ObjectCodes.BLOCK_ICE:
				BlockType.Ice;
			case ObjectCodes.BLOCK_ARROW_DOWN:
				BlockType.ArrowDown;
			case ObjectCodes.BLOCK_ARROW_UP:
				BlockType.ArrowUp;
			case ObjectCodes.BLOCK_ARROW_LEFT:
				BlockType.ArrowLeft;
			case ObjectCodes.BLOCK_ARROW_RIGHT:
				BlockType.ArrowRight;
			case ObjectCodes.BLOCK_MINE:
				BlockType.Mine;
			case ObjectCodes.BLOCK_ITEM:
				BlockType.Item;
			case ObjectCodes.BLOCK_ITEM_INF:
				BlockType.InfiniteItem;
			case ObjectCodes.BLOCK_CRUMBLE:
				BlockType.Crumble;
			case ObjectCodes.BLOCK_VANISH:
				BlockType.Vanish;
			case ObjectCodes.BLOCK_MOVE:
				BlockType.Move;
			case ObjectCodes.BLOCK_WATER:
				BlockType.Water;
			case ObjectCodes.BLOCK_ROTATE_RIGHT:
				BlockType.RotateRight;
			case ObjectCodes.BLOCK_ROTATE_LEFT:
				BlockType.RotateLeft;
			case ObjectCodes.BLOCK_PUSH:
				BlockType.Push;
			case ObjectCodes.BLOCK_SAFETY:
				BlockType.Safety;
			case ObjectCodes.BLOCK_TELEPORT:
				BlockType.Teleport;
			case ObjectCodes.BLOCK_CUSTOM_STATS:
				BlockType.CustomStats;
			case ObjectCodes.BLOCK_BRICK:
				BlockType.Brick;
			case ObjectCodes.BLOCK_HAPPY:
				BlockType.Happy;
			case ObjectCodes.BLOCK_SAD:
				BlockType.Sad;
			case ObjectCodes.BLOCK_HEART:
				BlockType.Heart;
			case ObjectCodes.BLOCK_TIME:
				BlockType.Time;
			case ObjectCodes.BLOCK_BASIC1 | ObjectCodes.BLOCK_BASIC2 | ObjectCodes.BLOCK_BASIC3 | ObjectCodes.BLOCK_BASIC4:
				BlockType.Basic;
			case ObjectCodes.BLOCK_MINION_EGG:
				null;
			default:
				BlockType.Solid;
		}
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

class EditorBlockOptionsPopup extends Sprite {
	public final editor:LevelEditor;
	public final block:EditorBlockObject;
	public final art:PR2MovieClip;
	private var armed:Bool = false;
	private var removed:Bool = false;

	public function new(editor:LevelEditor, block:EditorBlockObject, linkage:String) {
		super();
		this.editor = editor;
		this.block = block;
		art = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 6});
		addChild(art);
		mountNearBlock();
		Timer.delay(armAutoDismiss, 25);
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		if (armed && AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
		}
		art.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
		editor.blockOptionsPopupRemoved(this);
	}

	private function mountNearBlock():Void {
		var host:Null<Sprite> = editor.overlayLayer;
		if (AppStage.stage != null) {
			AppStage.stage.addChild(this);
			var blockBounds = block.getBounds(AppStage.stage);
			placeBeside(blockBounds);
			return;
		}
		if (host != null) {
			host.addChild(this);
			var blockBounds = block.getBounds(host);
			placeBeside(blockBounds);
		}
	}

	private function placeBeside(blockBounds:Rectangle):Void {
		var popupBounds = getBounds(this);
		var popupWidth = popupBounds.width <= 0 ? 236 : popupBounds.width;
		var popupHeight = popupBounds.height <= 0 ? 120 : popupBounds.height;
		x = blockBounds.left > popupWidth ? blockBounds.left - popupWidth - 7 : blockBounds.right + 7;
		y = blockBounds.top;
		if (y < 0) {
			y = 0;
		}
		if (y + popupHeight > 400) {
			y = 400 - popupHeight;
		}
		x = Math.round(x);
		y = Math.round(y);
	}

	private function armAutoDismiss():Void {
		if (removed || AppStage.stage == null) {
			return;
		}
		armed = true;
		AppStage.stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
	}

	private function onStageMouseDown(event:MouseEvent):Void {
		if (!hitTestPoint(event.stageX, event.stageY, true)) {
			remove();
		}
	}
}

class EditorStatBlockOptionsPopup extends EditorBlockOptionsPopup {
	private var slider:Null<FlSlider>;
	private var statBox:Null<TextField>;

	public function new(editor:LevelEditor, block:EditorBlockObject) {
		super(editor, block, "StatBlockOptionsGraphic");
		slider = Std.downcast(DisplayUtil.findByName(art, "slider"), FlSlider);
		statBox = FlComponents.asTextField(DisplayUtil.findByName(art, "statBox"));
		var titleBox = FlComponents.asTextField(DisplayUtil.findByName(art, "titleBox"));
		var descBox = FlComponents.asTextField(DisplayUtil.findByName(art, "descBox"));
		var happy = block.type == BlockType.Happy;
		if (titleBox != null) {
			titleBox.text = happy ? "-- Happy Block --" : "-- Sad Block --";
		}
		if (descBox != null) {
			descBox.text = "All the stats of players that bump this block will be " + (happy ? "increased" : "decreased") + " by:";
		}
		if (slider != null) {
			slider.minimum = 5;
			slider.maximum = 100;
			slider.snapInterval = 5;
			slider.addEventListener(FlSliderEvent.CHANGE, updateStatDisplay);
			slider.addEventListener(FlSliderEvent.THUMB_DRAG, updateStatDisplay);
		}
		setStatMagnitude(Std.int(Math.abs(EditorBlockOptions.statChange(block.type, block.options))));
	}

	public function setStatMagnitude(value:Int):Void {
		if (slider != null) {
			slider.value = value;
			updateStatDisplay();
		} else if (statBox != null) {
			statBox.text = Std.string(value);
		}
	}

	override public function remove():Void {
		if (slider != null) {
			slider.removeEventListener(FlSliderEvent.CHANGE, updateStatDisplay);
			slider.removeEventListener(FlSliderEvent.THUMB_DRAG, updateStatDisplay);
		}
		var magnitude = slider == null ? Std.int(Math.abs(EditorBlockOptions.statChange(block.type, block.options))) : Std.int(Math.round(slider.value));
		block.setOptions(EditorBlockOptions.applyStatChange(block.type, block.type == BlockType.Sad ? -magnitude : magnitude));
		super.remove();
	}

	private function updateStatDisplay(?_):Void {
		if (slider != null && statBox != null) {
			statBox.text = Std.string(Std.int(Math.round(slider.value)));
		}
	}
}

class EditorItemBlockOptionsPopup extends EditorBlockOptionsPopup {
	private final checks:Map<Int, FlCheckBox> = new Map();

	public function new(editor:LevelEditor, block:EditorBlockObject) {
		super(editor, block, "ItemBlockOptionsGraphic");
		var selected = EditorBlockOptions.selectedItems(block.options, editor.allowedItems);
		for (itemId in Items.getAllCodes()) {
			var check = Std.downcast(DisplayUtil.findByName(art, "check" + itemId), FlCheckBox);
			if (check != null) {
				check.selected = selected.indexOf(itemId) >= 0;
				checks.set(itemId, check);
			}
		}
	}

	public function setItemSelected(itemId:Int, selected:Bool):Void {
		var check = checks.get(itemId);
		if (check != null) {
			check.selected = selected;
		}
	}

	override public function remove():Void {
		var selected:Array<Int> = [];
		for (itemId in Items.getAllCodes()) {
			var check = checks.get(itemId);
			if (check != null && check.selected) {
				selected.push(itemId);
			}
		}
		block.setOptions(EditorBlockOptions.applyItemOptions(selected, editor.allowedItems));
		super.remove();
	}
}

class EditorTeleportBlockOptionsPopup extends EditorBlockOptionsPopup {
	private var picker:ColorPicker;

	public function new(editor:LevelEditor, block:EditorBlockObject) {
		super(editor, block, "TeleportBlockOptionsGraphic");
		picker = new ColorPicker();
		picker.name = "colorPicker";
		picker.width = 30;
		picker.height = 30;
		picker.x -= 15;
		picker.y += 30;
		picker.setColor(EditorBlockOptions.teleportColor(block.options));
		picker.addEventListener(Event.CHANGE, commitColor);
		addChild(picker);
	}

	public function setTeleportColor(color:Int):Void {
		picker.setColor(color);
	}

	override public function remove():Void {
		commitColor();
		picker.removeEventListener(Event.CHANGE, commitColor);
		picker.remove();
		super.remove();
	}

	private function commitColor(?_):Void {
		block.setOptions(EditorBlockOptions.applyTeleportColor(picker.getColor()));
	}
}

class EditorCustomStatsBlockOptionsPopup extends EditorBlockOptionsPopup {
	private var speedSlider:StatSlider;
	private var accelSlider:StatSlider;
	private var jumpnSlider:StatSlider;
	private var resetCheck:Null<FlCheckBox>;
	private var resetPop:Null<HoverPopup>;

	public function new(editor:LevelEditor, block:EditorBlockObject) {
		super(editor, block, "CustomStatsBlockOptionsGraphic");
		speedSlider = makeSlider("Speed", "speedSlider", -62.75, -40);
		accelSlider = makeSlider("Acceleration", "accelSlider", -62.75, 0);
		jumpnSlider = makeSlider("Jumping", "jumpnSlider", -62.75, 40);
		resetCheck = Std.downcast(DisplayUtil.findByName(art, "resetChk"), FlCheckBox);
		if (resetCheck != null) {
			resetCheck.addEventListener(Event.CHANGE, onResetClick);
			resetCheck.addEventListener(MouseEvent.MOUSE_OVER, onResetMouse);
			resetCheck.addEventListener(MouseEvent.MOUSE_OUT, onResetMouse);
			resetCheck.selected = block.options == "reset";
		}
		var stats = EditorBlockOptions.customStats(block.options);
		speedSlider.setValue(stats[0]);
		accelSlider.setValue(stats[1]);
		jumpnSlider.setValue(stats[2]);
		onResetClick();
	}

	public function setCustomStats(speed:Int, acceleration:Int, jumping:Int):Void {
		speedSlider.setValue(speed);
		accelSlider.setValue(acceleration);
		jumpnSlider.setValue(jumping);
	}

	public function setResetSelected(selected:Bool):Void {
		if (resetCheck != null) {
			resetCheck.selected = selected;
		}
		onResetClick();
	}

	override public function remove():Void {
		onResetMouse();
		if (resetCheck != null) {
			resetCheck.removeEventListener(Event.CHANGE, onResetClick);
			resetCheck.removeEventListener(MouseEvent.MOUSE_OVER, onResetMouse);
			resetCheck.removeEventListener(MouseEvent.MOUSE_OUT, onResetMouse);
		}
		block.setOptions(EditorBlockOptions.applyCustomStats(resetCheck != null && resetCheck.selected, speedSlider.value, accelSlider.value,
			jumpnSlider.value));
		speedSlider.remove();
		accelSlider.remove();
		jumpnSlider.remove();
		super.remove();
	}

	private function makeSlider(label:String, sliderName:String, sliderX:Float, sliderY:Float):StatSlider {
		var slider = new StatSlider(label, null);
		slider.name = sliderName;
		slider.x = sliderX;
		slider.y = sliderY;
		addChild(slider);
		return slider;
	}

	private function onResetClick(?_):Void {
		var resetting = resetCheck != null && resetCheck.selected;
		for (slider in [speedSlider, accelSlider, jumpnSlider]) {
			slider.alpha = resetting ? 0.25 : 1;
			slider.mouseEnabled = !resetting;
			slider.mouseChildren = !resetting;
		}
	}

	private function onResetMouse(?event:MouseEvent):Void {
		if (event != null && event.type == MouseEvent.MOUSE_OVER && resetPop == null && resetCheck != null) {
			resetPop = new HoverPopup("Reset To Starting Stats",
				"Checking this box will reset the bumping player's stats to those with which they entered the course.", resetCheck);
		} else if (resetPop != null) {
			resetPop.remove();
			resetPop = null;
		}
	}
}

typedef EditorValueSettingSpec = {
	final id:String;
	final title:String;
	final desc:String;
	final value:String;
	final maxChars:Int;
	final restrict:Null<String>;
	final defaultVal:String;
	final displayAsPassword:Bool;
};

class EditorValueSettingsPopup extends Sprite {
	public final editor:LevelEditor;
	public final art:PR2MovieClip;
	public final settingId:String;
	private var valueInput:Null<FlTextInput>;
	private var armTimer:Null<Timer>;
	private var armed:Bool = false;
	private var removed:Bool = false;
	private var defaultVal:String = "0";

	public function new(editor:LevelEditor, target:DisplayObject, settingId:String) {
		super();
		this.editor = editor;
		this.settingId = settingId;
		art = PR2MovieClip.fromLinkage("ValueMenuGraphic", {maxNestedDepth: 6});
		addChild(art);
		configure();
		mountNear(target);
		armTimer = Timer.delay(armAutoDismiss, 25);
	}

	public static function handles(settingId:String):Bool {
		return switch (settingId) {
			case "rank" | "gravity" | "time" | "sfcm" | "pass": true;
			default: false;
		}
	}

	public function value():String {
		return valueInput == null ? "" : valueInput.text;
	}

	public function setValue(nextValue:String):Void {
		if (valueInput != null) {
			valueInput.text = nextValue == null ? "" : nextValue;
		}
		commitValue();
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		if (armTimer != null) {
			armTimer.stop();
			armTimer = null;
		}
		if (armed && AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
		}
		if (valueInput != null) {
			valueInput.removeEventListener(Event.CHANGE, commitValue);
		}
		art.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
		editor.valueSettingsPopupRemoved(this);
	}

	private function configure():Void {
		var spec = specFor(settingId);
		defaultVal = spec.defaultVal;
		var titleBox = FlComponents.asTextField(DisplayUtil.findByName(art, "titleBox"));
		var descBox = FlComponents.asTextField(DisplayUtil.findByName(art, "descBox"));
		if (titleBox != null) {
			titleBox.htmlText = "<b>-- " + spec.title + " --</b>";
		}
		if (descBox != null) {
			descBox.htmlText = spec.desc;
		}
		valueInput = Std.downcast(DisplayUtil.findByName(art, "valueBox"), FlTextInput);
		if (valueInput != null) {
			valueInput.text = spec.value;
			valueInput.maxChars = spec.maxChars;
			if (spec.restrict != null) {
				valueInput.restrict = spec.restrict;
			}
			valueInput.displayAsPassword = spec.displayAsPassword;
			valueInput.addEventListener(Event.CHANGE, commitValue);
			if (AppStage.stage != null) {
				AppStage.stage.focus = valueInput.textField;
			}
		}
	}

	private function specFor(settingId:String):EditorValueSettingSpec {
		return switch (settingId) {
			case "rank":
				{id: "rank", title: "Minimum Rank", desc: "Players below this rank will not be able to race on this course.",
					value: editor.minRank, maxChars: 2, restrict: "0123456789", defaultVal: "0", displayAsPassword: false};
			case "gravity":
				{id: "gravity", title: "Gravity Multiplier", desc: "Normal gravity will be multiplied by the number you provide.",
					value: editor.gravity, maxChars: 4, restrict: "-.0123456789", defaultVal: "0", displayAsPassword: false};
			case "time":
				{id: "time", title: "Time Limit",
					desc: "Racers will have this amount of seconds to complete this course. Enter 0 for infinite time.", value: editor.maxTime,
					maxChars: 4, restrict: "0123456789", defaultVal: "0", displayAsPassword: false};
			case "sfcm":
				{id: "sfcm", title: "Chance of Cowboy Mode", desc: "Super Flying Cowboy Mode will appear this often out of 100.",
					value: editor.cowboyChance, maxChars: 3, restrict: "0123456789", defaultVal: "0", displayAsPassword: false};
			case "pass":
				{id: "pass", title: "Secret Password", desc: "This password lets players play your course while unpublished.",
					value: editor.pass == null ? "" : editor.pass, maxChars: 32, restrict: null, defaultVal: "", displayAsPassword: false};
			default:
				{id: settingId, title: settingId, desc: "", value: "", maxChars: 9, restrict: "0123456789", defaultVal: "0",
					displayAsPassword: false};
		}
	}

	private function commitValue(?_):Void {
		var text = valueInput == null ? "" : valueInput.text;
		if (text == "") {
			text = defaultVal;
		}
		switch (settingId) {
			case "rank":
				editor.setMinRank(text);
			case "gravity":
				editor.setGravity(text);
			case "time":
				editor.setMaxTime(text);
			case "sfcm":
				editor.setCowboyChance(text);
			case "pass":
				editor.setPass(text);
			default:
		}
		if (AppStage.stage != null) {
			AppStage.stage.focus = AppStage.stage;
		}
	}

	private function mountNear(target:DisplayObject):Void {
		if (AppStage.stage == null) {
			return;
		}
		AppStage.stage.addChild(this);
		var targetBounds = target.getBounds(AppStage.stage);
		var popupBounds = getBounds(this);
		var popupWidth = popupBounds.width <= 0 ? 250 : popupBounds.width;
		var popupHeight = popupBounds.height <= 0 ? 95 : popupBounds.height;
		x = targetBounds.left > popupWidth ? targetBounds.left - popupWidth - 7 : targetBounds.right + 7;
		y = targetBounds.top;
		if (y < 0) {
			y = 0;
		}
		if (y + popupHeight > 400) {
			y = 400 - popupHeight;
		}
		x = Math.round(x);
		y = Math.round(y);
	}

	private function armAutoDismiss():Void {
		armTimer = null;
		if (removed || AppStage.stage == null) {
			return;
		}
		armed = true;
		AppStage.stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
	}

	private function onStageMouseDown(event:MouseEvent):Void {
		if (!hitTestPoint(event.stageX, event.stageY, true)) {
			remove();
		}
	}
}

class EditorItemSettingsPopup extends Sprite {
	public final editor:LevelEditor;
	public final art:PR2MovieClip;
	private final checks:Map<Int, FlCheckBox> = new Map();
	private var armTimer:Null<Timer>;
	private var armed:Bool = false;
	private var removed:Bool = false;

	public function new(editor:LevelEditor, target:DisplayObject) {
		super();
		this.editor = editor;
		art = PR2MovieClip.fromLinkage("ItemMenuGraphic", {maxNestedDepth: 6});
		addChild(art);
		for (itemId in Items.getAllCodes()) {
			var check = Std.downcast(DisplayUtil.findByName(art, "check" + itemId), FlCheckBox);
			if (check != null) {
				check.selected = editor.allowedItems.indexOf(itemId) >= 0;
				checks.set(itemId, check);
			}
		}
		mountNear(target);
		armTimer = Timer.delay(armAutoDismiss, 25);
	}

	public function isItemSelected(itemId:Int):Bool {
		var check = checks.get(itemId);
		return check != null && check.selected;
	}

	public function setItemSelected(itemId:Int, selected:Bool):Void {
		var check = checks.get(itemId);
		if (check != null) {
			check.selected = selected;
		}
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		if (armTimer != null) {
			armTimer.stop();
			armTimer = null;
		}
		if (armed && AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
		}
		var selected:Array<Int> = [];
		for (itemId in Items.getAllCodes()) {
			var check = checks.get(itemId);
			if (check != null && check.selected) {
				selected.push(itemId);
			}
		}
		editor.setAllowedItems(selected);
		art.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
		editor.itemSettingsPopupRemoved(this);
	}

	private function mountNear(target:DisplayObject):Void {
		if (AppStage.stage == null) {
			return;
		}
		AppStage.stage.addChild(this);
		var targetBounds = target.getBounds(AppStage.stage);
		var popupBounds = getBounds(this);
		var popupWidth = popupBounds.width <= 0 ? 180 : popupBounds.width;
		var popupHeight = popupBounds.height <= 0 ? 150 : popupBounds.height;
		x = targetBounds.left > popupWidth ? targetBounds.left - popupWidth - 7 : targetBounds.right + 7;
		y = targetBounds.top;
		if (y < 0) {
			y = 0;
		}
		if (y + popupHeight > 400) {
			y = 400 - popupHeight;
		}
		x = Math.round(x);
		y = Math.round(y);
	}

	private function armAutoDismiss():Void {
		armTimer = null;
		if (removed || AppStage.stage == null) {
			return;
		}
		armed = true;
		AppStage.stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
	}

	private function onStageMouseDown(event:MouseEvent):Void {
		if (!hitTestPoint(event.stageX, event.stageY, true)) {
			remove();
		}
	}
}

class EditorMusicSettingsPopup extends Sprite {
	public final editor:LevelEditor;
	public final art:PR2MovieClip;
	public final dropdown:FlComboBox;
	private final songs:Array<MusicTrack>;
	private var armTimer:Null<Timer>;
	private var armed:Bool = false;
	private var removed:Bool = false;

	public function new(editor:LevelEditor, target:DisplayObject) {
		super();
		this.editor = editor;
		art = PR2MovieClip.fromLinkage("MusicMenuGraphic", {maxNestedDepth: 6});
		addChild(art);
		songs = MusicCatalog.enabled([], true);
		dropdown = new FlComboBox();
		dropdown.x = -100;
		dropdown.y = -15;
		dropdown.setSize(200, 22);
		dropdown.rowCount = 4;
		for (song in songs) {
			dropdown.addItem(song);
		}
		selectSong(editor.song == "" ? "random" : editor.song);
		dropdown.addEventListener(Event.CHANGE, changeSong);
		addChild(dropdown);
		mountNear(target);
		armTimer = Timer.delay(armAutoDismiss, 25);
	}

	public function selectedSongId():String {
		var selected:MusicTrack = cast dropdown.selectedItem;
		return selected == null ? "" : selected.id;
	}

	public function setSelectedSongId(songId:String):Void {
		selectSong(songId);
		changeSong(null);
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		if (armTimer != null) {
			armTimer.stop();
			armTimer = null;
		}
		if (armed && AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
		}
		dropdown.removeEventListener(Event.CHANGE, changeSong);
		if (dropdown.parent == this) {
			removeChild(dropdown);
		}
		art.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
		editor.musicSettingsPopupRemoved(this);
	}

	private function selectSong(songId:String):Void {
		for (i in 0...songs.length) {
			if (songs[i].id == songId) {
				dropdown.selectedIndex = i;
				return;
			}
		}
		dropdown.selectedIndex = songs.length > 1 ? 1 : 0;
	}

	private function changeSong(_:Event):Void {
		var selected:MusicTrack = cast dropdown.selectedItem;
		if (selected != null) {
			editor.setSong(selected.id);
		}
		if (AppStage.stage != null) {
			AppStage.stage.focus = AppStage.stage;
		}
	}

	private function mountNear(target:DisplayObject):Void {
		if (AppStage.stage == null) {
			return;
		}
		AppStage.stage.addChild(this);
		var targetBounds = target.getBounds(AppStage.stage);
		var popupBounds = getBounds(this);
		var popupWidth = popupBounds.width <= 0 ? 240 : popupBounds.width;
		var popupHeight = popupBounds.height <= 0 ? 115 : popupBounds.height;
		x = targetBounds.left > popupWidth ? targetBounds.left - popupWidth - 7 : targetBounds.right + 7;
		y = targetBounds.top;
		if (y < 0) {
			y = 0;
		}
		if (y + popupHeight > 400) {
			y = 400 - popupHeight;
		}
		x = Math.round(x);
		y = Math.round(y);
	}

	private function armAutoDismiss():Void {
		armTimer = null;
		if (removed || AppStage.stage == null) {
			return;
		}
		armed = true;
		AppStage.stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
	}

	private function onStageMouseDown(event:MouseEvent):Void {
		if (!hitTestPoint(event.stageX, event.stageY, true)) {
			remove();
		}
	}
}

class EditorModeSettingsPopup extends Sprite {
	public final editor:LevelEditor;
	public final art:PR2MovieClip;
	public final dropdown:Null<FlComboBox>;
	private var armTimer:Null<Timer>;
	private var armed:Bool = false;
	private var removed:Bool = false;

	public function new(editor:LevelEditor, target:DisplayObject) {
		super();
		this.editor = editor;
		art = PR2MovieClip.fromLinkage("ModeMenuGraphic", {maxNestedDepth: 6});
		addChild(art);
		dropdown = Std.downcast(DisplayUtil.findByName(art, "modeSelect"), FlComboBox);
		if (dropdown != null) {
			selectMode(editor.gameMode);
			dropdown.addEventListener(Event.CHANGE, changeMode);
		}
		mountNear(target);
		armTimer = Timer.delay(armAutoDismiss, 25);
	}

	public function selectedMode():String {
		return dropdown == null || dropdown.selectedItem == null ? "" : Std.string(Reflect.field(dropdown.selectedItem, "data"));
	}

	public function setSelectedMode(mode:String):Void {
		selectMode(mode);
		changeMode(null);
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		if (armTimer != null) {
			armTimer.stop();
			armTimer = null;
		}
		if (armed && AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
		}
		if (dropdown != null) {
			dropdown.removeEventListener(Event.CHANGE, changeMode);
		}
		art.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
		editor.modeSettingsPopupRemoved(this);
	}

	private function selectMode(mode:String):Void {
		if (dropdown == null) {
			return;
		}
		var normalized = mode == "eggs" ? "egg" : (mode == null || mode == "" ? "race" : mode);
		for (i in 0...dropdown.length) {
			var item = dropdown.dataProvider.getItemAt(i);
			if (Std.string(Reflect.field(item, "data")) == normalized) {
				dropdown.selectedIndex = i;
				return;
			}
		}
		dropdown.selectedIndex = 0;
	}

	private function changeMode(_:Event):Void {
		if (dropdown != null && dropdown.selectedItem != null) {
			editor.setGameMode(Std.string(Reflect.field(dropdown.selectedItem, "data")));
		}
		if (AppStage.stage != null) {
			AppStage.stage.focus = AppStage.stage;
		}
	}

	private function mountNear(target:DisplayObject):Void {
		if (AppStage.stage == null) {
			return;
		}
		AppStage.stage.addChild(this);
		var targetBounds = target.getBounds(AppStage.stage);
		var popupBounds = getBounds(this);
		var popupWidth = popupBounds.width <= 0 ? 240 : popupBounds.width;
		var popupHeight = popupBounds.height <= 0 ? 115 : popupBounds.height;
		x = targetBounds.left > popupWidth ? targetBounds.left - popupWidth - 7 : targetBounds.right + 7;
		y = targetBounds.top;
		if (y < 0) {
			y = 0;
		}
		if (y + popupHeight > 400) {
			y = 400 - popupHeight;
		}
		x = Math.round(x);
		y = Math.round(y);
	}

	private function armAutoDismiss():Void {
		armTimer = null;
		if (removed || AppStage.stage == null) {
			return;
		}
		armed = true;
		AppStage.stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
	}

	private function onStageMouseDown(event:MouseEvent):Void {
		if (!hitTestPoint(event.stageX, event.stageY, true)) {
			remove();
		}
	}
}

class EditorHatsSettingsPopup extends Sprite {
	public final editor:LevelEditor;
	public final art:PR2MovieClip;
	private static inline final LOWEST_HAT_ID:Int = 2;
	private static inline final HIGHEST_HAT_ID:Int = 16;
	private final checks:Map<Int, FlCheckBox> = new Map();
	private var armTimer:Null<Timer>;
	private var armed:Bool = false;
	private var removed:Bool = false;
	private var cowboyHover:Null<HoverPopup>;
	private var artifactHover:Null<HoverPopup>;

	public function new(editor:LevelEditor, target:DisplayObject) {
		super();
		this.editor = editor;
		art = PR2MovieClip.fromLinkage("HatsMenuGraphic", {maxNestedDepth: 6});
		addChild(art);
		for (hatId in LOWEST_HAT_ID...HIGHEST_HAT_ID + 1) {
			var check = Std.downcast(DisplayUtil.findByName(art, "hat" + hatId), FlCheckBox);
			if (check != null) {
				check.selected = editor.badHats.indexOf(hatId) < 0;
				checks.set(hatId, check);
			}
		}
		var artifact = checks.get(14);
		if (artifact != null && editor.gameMode == "hat") {
			artifact.selected = false;
		}
		bindHover(5);
		bindHover(14);
		mountNear(target);
		armTimer = Timer.delay(armAutoDismiss, 25);
	}

	public function isHatAllowed(hatId:Int):Bool {
		var check = checks.get(hatId);
		return check != null && check.selected;
	}

	public function setHatAllowed(hatId:Int, allowed:Bool):Void {
		var check = checks.get(hatId);
		if (check != null) {
			check.selected = allowed;
		}
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		if (armTimer != null) {
			armTimer.stop();
			armTimer = null;
		}
		if (armed && AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
		}
		removeHover();
		for (hatId in [5, 14]) {
			var check = checks.get(hatId);
			if (check != null) {
				check.removeEventListener(MouseEvent.MOUSE_OVER, maybeAddHover);
				check.removeEventListener(Event.CHANGE, maybeAddHover);
				check.removeEventListener(MouseEvent.MOUSE_OUT, removeHover);
			}
		}
		var banned:Array<Int> = [];
		for (hatId in LOWEST_HAT_ID...HIGHEST_HAT_ID + 1) {
			var check = checks.get(hatId);
			if (check != null && !check.selected) {
				banned.push(hatId);
			}
		}
		editor.setBadHats(banned.join(","));
		art.dispose();
		if (parent != null) {
			parent.removeChild(this);
		}
		editor.hatsSettingsPopupRemoved(this);
	}

	private function bindHover(hatId:Int):Void {
		var check = checks.get(hatId);
		if (check == null) {
			return;
		}
		check.addEventListener(MouseEvent.MOUSE_OVER, maybeAddHover);
		check.addEventListener(Event.CHANGE, maybeAddHover);
		check.addEventListener(MouseEvent.MOUSE_OUT, removeHover);
	}

	private function maybeAddHover(event:Event):Void {
		var target = Std.downcast(event.currentTarget, FlCheckBox);
		if (target == null) {
			return;
		}
		if (target == checks.get(5)) {
			if (cowboyHover == null && Std.parseInt(editor.cowboyChance) > 0 && !target.selected) {
				cowboyHover = new HoverPopup("Cowboy Mode",
					"Disabling the cowboy hat here won't override your setting for chance of cowboy mode.", target);
			} else {
				removeHover();
			}
		} else if (target == checks.get(14) && editor.gameMode == "hat") {
			removeHover();
			if (event.type != MouseEvent.MOUSE_OUT) {
				artifactHover = new HoverPopup("Artifact in Hat Attack",
					"This setting won't have any effect since the artifact hat cannot be used in hat attack mode.", target);
			}
		}
	}

	private function removeHover(?_):Void {
		if (cowboyHover != null) {
			cowboyHover.remove();
			cowboyHover = null;
		}
		if (artifactHover != null) {
			artifactHover.remove();
			artifactHover = null;
		}
	}

	private function mountNear(target:DisplayObject):Void {
		if (AppStage.stage == null) {
			return;
		}
		AppStage.stage.addChild(this);
		var targetBounds = target.getBounds(AppStage.stage);
		var popupBounds = getBounds(this);
		var popupWidth = popupBounds.width <= 0 ? 290 : popupBounds.width;
		var popupHeight = popupBounds.height <= 0 ? 210 : popupBounds.height;
		x = targetBounds.left > popupWidth ? targetBounds.left - popupWidth - 7 : targetBounds.right + 7;
		y = targetBounds.top;
		if (y < 0) {
			y = 0;
		}
		if (y + popupHeight > 400) {
			y = 400 - popupHeight;
		}
		x = Math.round(x);
		y = Math.round(y);
	}

	private function armAutoDismiss():Void {
		armTimer = null;
		if (removed || AppStage.stage == null) {
			return;
		}
		armed = true;
		AppStage.stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
	}

	private function onStageMouseDown(event:MouseEvent):Void {
		if (!hitTestPoint(event.stageX, event.stageY, true)) {
			remove();
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

	public function setOptions(nextOptions:String, record:Bool = true):Void {
		var normalized = nextOptions == null ? "" : nextOptions;
		if (options == normalized) {
			return;
		}
		options = normalized;
		if (record && deleteable && editor.blockLayer != null && parent == editor.blockLayer) {
			editor.blockLayer.recordBlockOptionsChanged();
		}
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
		if (editor.selectedToolSidebar == "blocks" && editor.selectedToolId == "delete") {
			editor.deleteBlock(this);
			event.stopImmediatePropagation();
			return;
		}
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
	public final redoArray:Array<String> = [];
	private final placedDisplays:Array<Sprite> = [];
	private final initialTextActions:Array<String> = [];

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
		var display = createStampDisplay(placed, size);
		placedObjects.push(placed);
		placedDisplays.push(display);
		addChild(display);
		return placed;
	}

	public function loadArtLayer(layer:Null<DecodedArtLayer>):Void {
		clearPlacedObjects();
		clearTextObjects();
		saveArray.resize(0);
		redoArray.resize(0);
		initialTextActions.resize(0);
		if (layer != null) {
			for (object in layer.objects) {
				addLoadedStamp(object);
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
		if (startEditing) {
			placed.startEditing();
		}
		return placed;
	}

	public function recordChangeText(textObject:EditorTextObject):Void {
		var textId = textObjects.indexOf(textObject);
		if (textId >= 0) {
			recordAction("y" + textId + ";" + textObject.getEscapedText() + ";" + textObject.color);
		}
	}

	public function recordMoveText(textObject:EditorTextObject):Void {
		var textId = textObjects.indexOf(textObject);
		if (textId >= 0) {
			recordAction("m" + textId + ";" + textObject.x + ";" + textObject.y);
		}
	}

	public function recordResizeText(textObject:EditorTextObject):Void {
		var textId = textObjects.indexOf(textObject);
		if (textId >= 0) {
			recordAction("r" + textId + ";" + textObject.scaleX + ";" + textObject.scaleY);
		}
	}

	public function removeTextObject(textObject:EditorTextObject, record:Bool = true):Void {
		var textId = textObjects.indexOf(textObject);
		if (textId < 0) {
			return;
		}
		if (record) {
			recordAction("d" + textId);
		}
		textObjects.splice(textId, 1);
		textObject.remove();
	}

	public function removeObjectsTouchingPoint(stageX:Float, stageY:Float):Bool {
		var removed = false;
		for (i in 0...placedDisplays.length) {
			var index = placedDisplays.length - 1 - i;
			var display = placedDisplays[index];
			if (display != null && touchesStagePoint(display, stageX, stageY)) {
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
		rebuildTextObjects();
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
		rebuildTextObjects();
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

	private function rebuildTextObjects():Void {
		clearTextObjects();
		for (action in initialTextActions) {
			replayTextAction(action);
		}
		for (action in saveArray) {
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
				var index = parseActionIndex(parts[0]);
				if (index >= 0 && index < textObjects.length) {
					var removed = textObjects.splice(index, 1)[0];
					removed.remove();
				}
			default:
		}
	}

	private function textObjectForAction(parts:Array<String>):Null<EditorTextObject> {
		var index = parseActionIndex(parts[0]);
		return index >= 0 && index < textObjects.length ? textObjects[index] : null;
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
		placedObjects.splice(index, 1);
		placedDisplays.splice(index, 1);
		if (display != null && display.parent != null) {
			display.parent.removeChild(display);
		}
	}

	private function clearPlacedObjects():Void {
		while (placedObjects.length > 0) {
			removePlacedObjectAt(placedObjects.length - 1);
		}
	}

	private function clearTextObjects():Void {
		for (textObject in textObjects.copy()) {
			textObject.remove();
		}
		textObjects.resize(0);
	}

	private function addLoadedStamp(object:DecodedArtObject):Void {
		var placed = new EditorPlacedObject(object.code, Math.round(object.x), Math.round(object.y), object.scaleX, object.scaleY);
		var display = createStampDisplay(placed, stampDisplaySize(object.code));
		placedObjects.push(placed);
		placedDisplays.push(display);
		addChild(display);
	}

	private static function encodedTextAction(text:DecodedTextObject):String {
		return "u" + text.text + ";" + Math.round(text.x) + ";" + Math.round(text.y) + ";" + text.color + ";"
			+ Std.int(text.scaleX * 100) + ";" + Std.int(text.scaleY * 100);
	}

	private function touchesStagePoint(display:DisplayObject, stageX:Float, stageY:Float):Bool {
		var point = globalToLocal(new Point(stageX, stageY));
		return display.getBounds(this).contains(point.x, point.y);
	}

	private static function createStampDisplay(placed:EditorPlacedObject, size:StampSize):Sprite {
		var holder = new Sprite();
		holder.x = placed.x;
		holder.y = placed.y;
		holder.scaleX = placed.scaleX;
		holder.scaleY = placed.scaleY;
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
	public final redoArray:Array<String> = [];
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

	public function beginStroke(stageX:Float, stageY:Float, nextMode:String, nextSize:Float, nextColor:Int):Void {
		recordColor(nextColor);
		setBrushSize(nextSize);
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
		notifyHistoryChanged();
	}

	public function isDrawing():Bool {
		return drawing;
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

class EditorPlacedObject {
	public final code:Int;
	public final x:Int;
	public final y:Int;
	public final scaleX:Float;
	public final scaleY:Float;

	public function new(code:Int, x:Int, y:Int, scaleX:Float = 1, scaleY:Float = 1) {
		this.code = code;
		this.x = x;
		this.y = y;
		this.scaleX = scaleX;
		this.scaleY = scaleY;
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
			var entry = if (id == "backgrounds" && itemId == "color") {
				new EditorBackgroundColorPickerButton();
			} else if (id == "tools" && itemId == "size") {
				new EditorBrushSizePickerButton();
			} else if (id == "tools" && itemId == "color") {
				new EditorBrushColorPickerButton();
			} else {
				new EditorSideBarEntry(itemId);
			}
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
		if (editor != null && id == "tools" && entry.id == "landscape" && editor.menu != null) {
			editor.menu.changeSideBar(editor.menu.stamps);
			return;
		}
		if (editor != null && id == "tools" && entry.id == "size") {
			var sizeEntry = Std.downcast(entry, EditorBrushSizePickerButton);
			if (sizeEntry != null) {
				sizeEntry.openMenu();
			}
			return;
		}
		if (editor != null && id == "tools" && entry.id == "color") {
			return;
		}
		if (editor != null && id == "settings" && entry.id == "items") {
			editor.openItemSettingsMenu(entry);
			return;
		}
		if (editor != null && id == "settings" && entry.id == "hats") {
			editor.openHatsSettingsMenu(entry);
			return;
		}
		if (editor != null && id == "settings" && entry.id == "music") {
			editor.openMusicSettingsMenu(entry);
			return;
		}
		if (editor != null && id == "settings" && entry.id == "mode") {
			editor.openModeSettingsMenu(entry);
			return;
		}
		if (editor != null && id == "settings" && EditorValueSettingsPopup.handles(entry.id)) {
			editor.openValueSettingsMenu(entry.id, entry);
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
			var colorEntry = Std.downcast(child, EditorBackgroundColorPickerButton);
			if (colorEntry != null) {
				colorEntry.remove();
			}
			var sizeEntry = Std.downcast(child, EditorBrushSizePickerButton);
			if (sizeEntry != null) {
				sizeEntry.remove();
			}
			var brushColorEntry = Std.downcast(child, EditorBrushColorPickerButton);
			if (brushColorEntry != null) {
				brushColorEntry.remove();
			}
		}
		selectedEntry = null;
	}

	public function updateColor():Void {
		for (i in 0...numChildren) {
			var colorEntry = Std.downcast(getChildAt(i), EditorBackgroundColorPickerButton);
			if (colorEntry != null) {
				colorEntry.updateColor();
			}
		}
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

class EditorBackgroundColorPickerButton extends EditorSideBarEntry {
	private final picker:ColorPicker;

	public function new() {
		super("color");
		picker = new ColorPicker();
		picker.name = "colorPicker";
		picker.width = 30;
		picker.height = 30;
		picker.addEventListener(Event.CHANGE, commitColor);
		addChild(picker);
		updateColor();
	}

	public function updateColor():Void {
		var editor = LevelEditor.editor;
		if (editor != null) {
			picker.setColor(editor.color);
		}
	}

	public function setPickedColor(color:Int):Void {
		picker.setColor(color);
		commitColor();
	}

	public function pickerColor():Int {
		return picker.getColor();
	}

	public function remove():Void {
		picker.removeEventListener(Event.CHANGE, commitColor);
		picker.remove();
	}

	private function commitColor(?_):Void {
		var editor = LevelEditor.editor;
		if (editor != null) {
			editor.setColor(picker.getColor());
		}
		if (AppStage.stage != null) {
			AppStage.stage.focus = AppStage.stage;
		}
	}
}

class EditorBrushSizePickerButton extends EditorSideBarEntry {
	private final art:PR2MovieClip;
	private var circle:Null<DisplayObject>;

	public function new() {
		super("size");
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

	public function remove():Void {
		var editor = LevelEditor.editor;
		if (editor != null && editor.activeBrushSizeMenu != null) {
			editor.closeBrushSizeMenu();
		}
		art.dispose();
	}
}

class EditorBrushSizePickerMenu extends Sprite {
	public final editor:LevelEditor;
	public final target:EditorBrushSizePickerButton;
	public final art:PR2MovieClip;
	private var slider:Null<FlSlider>;
	private var textInput:Null<FlTextInput>;

	public function new(editor:LevelEditor, target:EditorBrushSizePickerButton) {
		super();
		this.editor = editor;
		this.target = target;
		art = PR2MovieClip.fromLinkage("SizePickerMenuGraphic", {maxNestedDepth: 6});
		addChild(art);
		var origin = editor.globalToLocal(target.localToGlobal(new Point(0, 0)));
		x = origin.x - 85;
		y = origin.y - 35;
		slider = Std.downcast(DisplayUtil.findByName(art, "slider"), FlSlider);
		textInput = Std.downcast(DisplayUtil.findByName(art, "textBox"), FlTextInput);
		if (slider != null) {
			slider.minimum = 1;
			slider.maximum = 255;
			slider.snapInterval = 1;
			slider.addEventListener(FlSliderEvent.CHANGE, slideChange);
			slider.addEventListener(FlSliderEvent.THUMB_DRAG, slideChange);
		}
		if (textInput != null) {
			textInput.restrict = "0-9";
			textInput.maxChars = 3;
			textInput.addEventListener(Event.CHANGE, textChange);
		}
		setSize(editor.brushSize);
	}

	public function setSize(size:Float):Void {
		if (Math.isNaN(size)) {
			size = EditorDrawableLayer.DEFAULT_BRUSH_SIZE;
		}
		size = Math.max(1, Math.min(255, Math.round(size)));
		editor.setBrushSize(size);
		target.updateCircle();
		if (textInput != null) {
			textInput.text = Std.string(Std.int(editor.brushSize));
		}
		if (slider != null) {
			slider.value = editor.brushSize;
		}
	}

	public function remove():Void {
		if (slider != null) {
			slider.removeEventListener(FlSliderEvent.CHANGE, slideChange);
			slider.removeEventListener(FlSliderEvent.THUMB_DRAG, slideChange);
			slider = null;
		}
		if (textInput != null) {
			textInput.removeEventListener(Event.CHANGE, textChange);
			textInput = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
		art.dispose();
		editor.brushSizeMenuRemoved(this);
		if (editor.stage != null) {
			editor.stage.focus = editor.stage;
		}
	}

	private function slideChange(event:FlSliderEvent):Void {
		setSize(event.value);
	}

	private function textChange(_:Event):Void {
		if (textInput == null) {
			return;
		}
		var parsed = Std.parseFloat(textInput.text);
		setSize(Math.isNaN(parsed) ? EditorDrawableLayer.DEFAULT_BRUSH_SIZE : parsed);
	}
}

class EditorBrushColorPickerButton extends EditorSideBarEntry {
	private final picker:ColorPicker;

	public function new() {
		super("color");
		picker = new ColorPicker();
		picker.name = "brushColorPicker";
		picker.width = 30;
		picker.height = 30;
		picker.addEventListener(Event.CHANGE, commitColor);
		addChild(picker);
		updateColor();
	}

	public function updateColor():Void {
		var editor = LevelEditor.editor;
		if (editor != null) {
			picker.setColor(editor.brushColor);
		}
	}

	public function setPickedColor(color:Int):Void {
		picker.setColor(color);
		commitColor();
	}

	public function pickerColor():Int {
		return picker.getColor();
	}

	public function remove():Void {
		picker.removeEventListener(Event.CHANGE, commitColor);
		picker.remove();
	}

	private function commitColor(?_):Void {
		var editor = LevelEditor.editor;
		if (editor != null) {
			editor.setBrushColor(picker.getColor());
		}
		if (AppStage.stage != null) {
			AppStage.stage.focus = AppStage.stage;
		}
	}
}
