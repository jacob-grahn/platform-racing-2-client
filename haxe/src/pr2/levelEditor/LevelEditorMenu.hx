package pr2.levelEditor;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.ui.controls.GameSelect;
import pr2.ui.controls.GameButton;
import pr2.util.DisplayUtil;

class LevelEditorMenu extends Sprite {
	public final editor:LevelEditor;
	public final art:LevelEditorMenuView;
	public var blocks(get, never):EditorSideBar;
	public var settings(get, never):EditorSideBar;
	public var stamps(get, never):EditorSideBar;
	public var tools(get, never):EditorSideBar;
	public var bg(get, never):EditorSideBar;
	public var sideBar(default, null):Null<EditorSideBar>;
	private var blocksSideBar:Null<EditorSideBar>;
	private var settingsSideBar:Null<EditorSideBar>;
	private var stampsSideBar:Null<EditorSideBar>;
	private var toolsSideBar:Null<EditorSideBar>;
	private var backgroundSideBar:Null<EditorSideBar>;
	private var pendingSettingValues:Map<String, String> = new Map();
	private var bindings:Array<Binding> = [];

	public function new(editor:LevelEditor) {
		super();
		this.editor = editor;
		art = new LevelEditorMenuView();
		addChild(art);
	}

	private function get_blocks():EditorSideBar {
		if (blocksSideBar == null) {
			blocksSideBar = new EditorSideBar("blocks", ["delete", "basic1", "basic2", "basic3", "basic4", "brick", "finish", "ice", "item", "infItem", "left",
				"right", "up", "down", "teleport", "mine", "crumble", "vanish", "move", "water", "rotateR", "rotateL", "push", "happy", "sad",
				"custom", "safety", "heart", "time", "egg"]);
		}
		return blocksSideBar;
	}

	private function get_settings():EditorSideBar {
		if (settingsSideBar == null) {
			settingsSideBar = new EditorSideBar("settings", ["music", "items", "hats", "rank", "gravity", "time", "mode", "sfcm", "pass"]);
			for (itemId in pendingSettingValues.keys()) {
				settingsSideBar.setEntryValue(itemId, pendingSettingValues.get(itemId));
			}
		}
		return settingsSideBar;
	}

	private function get_stamps():EditorSideBar {
		if (stampsSideBar == null) {
			stampsSideBar = new EditorSideBar("stamps", ["brush", "delete", "text", "stamp0", "stamp1", "stamp2", "stamp3", "stamp4", "stamp5", "stamp6",
				"stamp7", "stamp8", "stamp9"]);
		}
		return stampsSideBar;
	}

	private function get_tools():EditorSideBar {
		if (toolsSideBar == null) {
			toolsSideBar = new EditorSideBar("tools", ["landscape", "brush", "eraser", "size", "color"]);
		}
		return toolsSideBar;
	}

	private function get_bg():EditorSideBar {
		if (backgroundSideBar == null) {
			backgroundSideBar = new EditorSideBar("backgrounds", ["color", "bg1", "bg2", "bg3", "bg4", "bg5", "bg6", "bg7"]);
		}
		return backgroundSideBar;
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
		bind("newButton", clickNew);
		bind("exitButton", clickExit);
		var zoomSelect = zoomCombo();
		if (zoomSelect != null) {
			zoomSelect.addEventListener(Event.CHANGE, chooseZoom);
			zoomSelect.selectedIndex = 3;
		}
		editor.setZoom(1);
		updateUndoRedoState();
		if (pr2.lobby.LobbySession.group <= 0) {
			setButtonEnabled("saveButton", false);
			setButtonEnabled("loadButton", false);
		}
		reset();
	}

	public function setReportsMode(on:Bool = false):Void {
		// Reports mode may be applied immediately after init. Do not let that
		// second state pass re-enable Save for guests, whose Flash menu keeps both
		// persistence commands disabled.
		setButtonEnabled("saveButton", !on && LobbySession.group > 0);
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
		if (toolsSideBar != null) toolsSideBar.exit();
	}

	public function remove():Void {
		var zoomSelect = zoomCombo();
		if (zoomSelect != null) {
			zoomSelect.removeEventListener(Event.CHANGE, chooseZoom);
		}
		for (binding in bindings) LobbyArt.unbind(binding);
		bindings = [];
		if (blocksSideBar != null) blocksSideBar.remove();
		if (settingsSideBar != null) settingsSideBar.remove();
		if (stampsSideBar != null) stampsSideBar.remove();
		if (toolsSideBar != null) toolsSideBar.remove();
		if (backgroundSideBar != null) backgroundSideBar.remove();
		blocksSideBar = null;
		settingsSideBar = null;
		stampsSideBar = null;
		toolsSideBar = null;
		backgroundSideBar = null;
		sideBar = null;
		art.dispose();
	}

	private function find(name:String):Null<DisplayObject> {
		return pr2.util.DisplayUtil.directChildByName(art, name);
	}

	private function setButtonEnabled(name:String, enabled:Bool):Void {
		var button = Std.downcast(find(name), GameButton);
		if (button != null) button.enabled = enabled;
	}

	private function zoomCombo():Null<GameSelect<String>> {
		return Std.downcast(find("zoomSelect"), GameSelect);
	}

	private function bind(name:String, handler:Void->Void):Void {
		var binding = LobbyArt.bind(DisplayUtil.directChildByName(art, name), handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	private function clickBlocks():Void {
		changeSideBar(blocks);
		editor.focusOnBlocks();
		updateUndoRedoState();
		moveGlow(find("blocksButton"));
	}

	private function clickSettings():Void {
		changeSideBar(settings);
		editor.focusNone();
		setUndoRedoEnabled(false, false);
		moveGlow(find("settingsButton"));
	}

	private function clickBackgrounds():Void {
		changeSideBar(bg);
		editor.focusNone();
		setUndoRedoEnabled(false, false);
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
		if (LobbySession.group <= 0 || editor.reportsMode) {
			return;
		}
		new SaveLevelPopup(editor);
	}

	private function clickLoad():Void {
		if (LobbySession.group <= 0) {
			return;
		}
		if (editor.canViewLevelReports()) {
			new ChooseLevelsModePopup();
		} else {
			new GetLevelsPopup();
		}
	}

	private function clickTest():Void {
		if (!editor.isDrawing() && editor.pageHolder != null) {
			editor.pageHolder.changePage(new TestCoursePage(editor.getLevelVars(), editor.canViewLevelReports(), editor.reportsMode));
		}
	}

	private function clickNew():Void {
		new ConfirmPopup(clearEditor, "Are you sure you want to clear this level? All unsaved data will be lost.");
	}

	public function clearEditor():Void {
		editor.clear();
		updateBackgroundColor();
	}

	private function clickExit():Void {
		new ConfirmPopup(exitEditor, "Are you sure you want exit? All unsaved data will be lost.");
	}

	public function exitEditor():Void {
		new LevelEditorConnectingPopup();
	}

	private function chooseZoom(_):Void {
		var combo = zoomCombo();
		if (combo == null || combo.selectedOption == null) {
			return;
		}
		var data = combo.selectedOption.value;
		var percent = Std.parseFloat(data);
		if (Math.isNaN(percent)) {
			return;
		}
		editor.setZoom(percent / 100);
		tools.setZoom(editor.zoom);
		if (editor.stage != null) {
			editor.stage.focus = editor.stage;
		}
	}

	public function updateUndoRedoState():Void {
		if (editor.blockLayer != null && editor.focusedEditorLayer == "blocks") {
			setButtonEnabled("undoButton", editor.blockLayer.saveArray.length > 0);
			setButtonEnabled("redoButton", editor.blockLayer.redoArray.length > 0);
			return;
		}
		if (editor.focusedEditorLayer == "draw" && editor.activeDrawLayer != null) {
			setButtonEnabled("undoButton", editor.activeDrawLayer.saveArray.length > 0);
			setButtonEnabled("redoButton", editor.activeDrawLayer.redoArray.length > 0);
			return;
		}
		var activeLayer = editor.focusedEditorLayer == "objects" ? editor.activeObjectLayer : null;
		setButtonEnabled("undoButton", activeLayer != null && activeLayer.saveArray.length > 0);
		setButtonEnabled("redoButton", activeLayer != null && activeLayer.redoArray.length > 0);
	}

	private function setUndoRedoEnabled(undo:Bool, redo:Bool):Void {
		setButtonEnabled("undoButton", undo);
		setButtonEnabled("redoButton", redo);
	}

	public function updateBackgroundColor():Void {
		if (backgroundSideBar != null) backgroundSideBar.updateColor();
	}

	public function setSettingValue(itemId:String, value:String):Void {
		pendingSettingValues.set(itemId, value);
		if (settingsSideBar != null) settingsSideBar.setEntryValue(itemId, value);
	}

	private function setLayer(layerNum:Int):Void {
		if (sideBar != stamps && sideBar != tools) {
			changeSideBar(stamps);
		}
		editor.setActiveObjectLayer(layerNum);
		if (sideBar == tools) {
			editor.focusOnActiveDrawLayer();
		} else {
			editor.focusOnActiveObjectLayer();
		}
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
