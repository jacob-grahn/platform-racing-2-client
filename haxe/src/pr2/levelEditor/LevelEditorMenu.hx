package pr2.levelEditor;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.ui.controls.GameSelect;
import pr2.util.DisplayUtil;

class LevelEditorMenu extends Sprite {
	public final editor:LevelEditor;
	public final art:LevelEditorMenuView;
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
		art = new LevelEditorMenuView();
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
		bind("newButton", clickNew);
		bind("exitButton", clickExit);
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

	private function zoomCombo():Null<GameSelect<String>> {
		return Std.downcast(find("zoomSelect"), GameSelect);
	}

	private function bind(name:String, handler:Void->Void):Void {
		var binding = LobbyArt.bind(DisplayUtil.findByName(art, name), handler);
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
			Reflect.setProperty(find("undoButton"), "enabled", editor.blockLayer.saveArray.length > 0);
			Reflect.setProperty(find("redoButton"), "enabled", editor.blockLayer.redoArray.length > 0);
			return;
		}
		if (editor.focusedEditorLayer == "draw" && editor.activeDrawLayer != null) {
			Reflect.setProperty(find("undoButton"), "enabled", editor.activeDrawLayer.saveArray.length > 0);
			Reflect.setProperty(find("redoButton"), "enabled", editor.activeDrawLayer.redoArray.length > 0);
			return;
		}
		var activeLayer = editor.focusedEditorLayer == "objects" ? editor.activeObjectLayer : null;
		Reflect.setProperty(find("undoButton"), "enabled", activeLayer != null && activeLayer.saveArray.length > 0);
		Reflect.setProperty(find("redoButton"), "enabled", activeLayer != null && activeLayer.redoArray.length > 0);
	}

	private function setUndoRedoEnabled(undo:Bool, redo:Bool):Void {
		Reflect.setProperty(find("undoButton"), "enabled", undo);
		Reflect.setProperty(find("redoButton"), "enabled", redo);
	}

	public function updateBackgroundColor():Void {
		bg.updateColor();
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
