package pr2.levelEditor;

import openfl.display.Sprite;
import pr2.runtime.SvgAsset;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameSelect;
import pr2.ui.view.NativeView;

/** Native editor command bar for tools, layers, history, files, and testing. */
class LevelEditorMenuView extends NativeView {
	public final zoomSelect:GameSelect<String>;

	public function new() {
		super();
		var background = SvgAsset.create("assets/svg/editor/level_editor_menu_background.svg");
		background.name = "background";
		addChild(background);
		var glow = SvgAsset.create("assets/svg/editor/level_editor_menu_glow.svg");
		glow.name = "selectedGlow";
		glow.x = -198.9;
		glow.y = -180;
		addChild(glow);

		// Exact component matrices from LevelEditorMenu.xml. Flash's components
		// have a 100x22 authored size; the XFL `a` values scale their width only.
		button("layer00Button", "Art 00", -255, -191, 49.9847412109375);
		button("layer0Button", "Art 0", -199, -191, 49.9847412109375);
		button("blocksButton", "Blocks", -143, -191, 49.9862670898438);
		button("layer1Button", "Art 1", -87, -191, 49.9847412109375);
		button("layer2Button", "Art 2", -31, -191, 49.9847412109375);
		button("layer3Button", "Art 3", 25, -191, 49.9847412109375);
		button("bgButton", "BG", 81, -191, 49.993896484375);
		button("settingsButton", "Settings", 137, -191, 54.9942016601562);
		button("saveButton", "Save", -254.6, 169, 46.1044311523438);
		button("loadButton", "Load", -202.6, 169, 46.1044311523438);
		button("testButton", "Test", -150.9, 169, 46.1044311523438);
		button("newButton", "New", -98.4, 169, 46.1044311523438);
		button("exitButton", "Exit", -47, 169, 46.09375);
		zoomSelect = ownControl(new GameSelect<String>());
		zoomSelect.name = "zoomSelect";
		zoomSelect.x = 30;
		zoomSelect.y = 169;
		zoomSelect.setSize(60.009765625, 22);
		for (value in ["25", "50", "75", "100", "150", "250", "500"]) zoomSelect.addOption(value + "%", value);
		addChild(zoomSelect);
		button("undoButton", "Undo", 94.65, 169, 46.09375);
		button("redoButton", "Redo", 146.15, 169, 46.09375);
	}

	private function button(name:String, label:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 22);
		addChild(control);
	}
}
