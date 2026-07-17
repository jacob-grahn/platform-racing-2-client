package pr2.levelEditor;

import openfl.display.Sprite;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameSelect;
import pr2.ui.view.NativeView;

/** Native editor command bar for tools, layers, history, files, and testing. */
class LevelEditorMenuView extends NativeView {
	public final zoomSelect:GameSelect<String>;

	public function new() {
		super();
		graphics.beginFill(0xE8EAED, 0.98);
		graphics.lineStyle(1, 0x555555);
		graphics.drawRoundRect(4, 4, 542, 66, 10, 10);
		graphics.endFill();
		var top = [
			{name: "blocksButton", label: "Blocks"}, {name: "settingsButton", label: "Settings"}, {name: "bgButton", label: "BG"},
			{name: "undoButton", label: "Undo"}, {name: "redoButton", label: "Redo"}, {name: "saveButton", label: "Save"},
			{name: "loadButton", label: "Load"}, {name: "testButton", label: "Test"}, {name: "newButton", label: "New"},
			{name: "exitButton", label: "Exit"}
		];
		for (i in 0...top.length) button(top[i].name, top[i].label, 10 + i * 49, 10, 46);
		var layers = ["layer00Button", "layer0Button", "layer1Button", "layer2Button", "layer3Button"];
		for (i in 0...layers.length) button(layers[i], i < 2 ? "BG " + i : "L" + (i - 1), 10 + i * 43, 40, 40);
		zoomSelect = ownControl(new GameSelect<String>());
		zoomSelect.name = "zoomSelect";
		zoomSelect.x = 236;
		zoomSelect.y = 40;
		zoomSelect.setSize(96, 22);
		for (value in ["25", "50", "75", "100", "125", "150", "200"]) zoomSelect.addOption(value + "%", value);
		addChild(zoomSelect);
		var glow = new Sprite();
		glow.name = "selectedGlow";
		glow.graphics.lineStyle(2, 0xE0B62E);
		glow.graphics.drawRoundRect(-24, 0, 48, 26, 7, 7);
		glow.y = 9;
		addChild(glow);
	}

	private function button(name:String, label:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 24);
		control.labelField.textColor = 0x555555;
		addChild(control);
	}
}
