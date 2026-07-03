package pr2.page;

import haxe.crypto.Md5;
import haxe.Timer;
import openfl.display.Bitmap;
import openfl.display.DisplayObject;
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
import pr2.gameplay.Course;
import pr2.gameplay.Items;
import pr2.gameplay.LevelConfig;
import pr2.level.ServerLevel.DecodedDrawAction;
import pr2.level.BlockType;
import pr2.level.ObjectCodes;
import pr2.level.ServerLevelDecoder;
import pr2.level.ServerLevelRenderer;
import pr2.lobby.account.ColorPicker;
import pr2.lobby.account.StatSlider;
import pr2.lobby.dialogs.HoverPopup;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.net.ServerLevelData;
import pr2.net.ServerConfig;
import pr2.runtime.FlCheckBox;
import pr2.runtime.FlComboBox;
import pr2.runtime.FlComponents;
import pr2.runtime.FlSlider;
import pr2.runtime.FlSliderEvent;
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
	public var levelConfig(default, null):LevelConfig = new LevelConfig();
	public var allowedItems(default, null):Array<Int> = Items.getAllCodes();
	public var badHats(default, null):Array<Int> = [];
	public var title:String = "";
	public var note:String = "";
	public var live(default, null):Float = 0;
	public var minRank(default, null):String = "0";
	public var pass(default, null):Null<String> = null;
	public var hasPass(default, null):Int = 0;
	public var song(get, never):String;
	public var gravity(get, never):String;
	public var maxTime(get, never):String;
	public var gameMode(get, never):String;
	public var cowboyChance(get, never):String;
	public var color(get, never):Int;
	public var zoom(default, null):Float = 1;
	public var posX(default, null):Float = 0;
	public var posY(default, null):Float = 0;
	private var layerContainer:Null<Sprite>;
	private var drawingLayer:Null<EditorDrawableLayer>;
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
		}
	}

	private function stopSelectedToolFromMouse(event:MouseEvent):Void {
		if (endSelectedBrush()) {
			event.stopImmediatePropagation();
		}
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
}

class TestCoursePage extends Page {
	public final variables:Map<String, String>;
	public final isMod:Bool;
	public final reportsMode:Bool;
	public var course(default, null):Null<Course>;
	public var art(default, null):Null<PR2MovieClip>;
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
	}

	override public function remove():Void {
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
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
		course.beginRace();
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
		if (course != null) {
			course.remove();
			course = null;
		}
		mountCourse();
		if (art != null) {
			addChild(art);
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
		bind("undoButton", clickUndo);
		bind("redoButton", clickRedo);
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
		for (textObject in textObjects.copy()) {
			textObject.remove();
		}
		textObjects.resize(0);
		saveArray.resize(0);
		redoArray.resize(0);
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
		for (textObject in textObjects.copy()) {
			textObject.remove();
		}
		textObjects.resize(0);
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
		notifyHistoryChanged();
	}

	public function getSaveString():String {
		return saveArray.join(",");
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
		rasterize();
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
