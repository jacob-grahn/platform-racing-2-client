package pr2.levelEditor;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.gameplay.Modes;
import pr2.ui.controls.GameSelect;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

/** Native compact shell for mode, music, and scalar editor settings. */
class EditorSettingsMenuView extends NativeView {
	public function new(kind:String) {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-125, -48, 250, 96, 12, 12);
		graphics.endFill();
		if (kind == "mode") makeMode();
		if (kind == "value") makeValue();
		if (kind == "music") title("-- Course Music --");
	}

	private function makeMode():Void {
		title("-- Game Mode --");
		var select = ownControl(new GameSelect<String>());
		select.name = "modeSelect";
		select.x = -100;
		select.y = 8;
		select.setSize(200, 24);
		select.addOption("Race", Modes.race);
		select.addOption("Deathmatch", Modes.dm);
		select.addOption("Eggs", Modes.egg);
		select.addOption("Objective", Modes.obj);
		select.addOption("Hat Attack", Modes.hat);
		select.addOption("Roguelike", Modes.roguelike);
		addChild(select);
	}

	private function makeValue():Void {
		field("titleBox", -112, -39, 224, 20, 14, true, TextFormatAlign.CENTER);
		var desc = field("descBox", -112, -15, 170, 52, 9, false, TextFormatAlign.LEFT);
		desc.multiline = true;
		desc.wordWrap = true;
		var input = ownControl(new GameTextInput());
		input.name = "valueBox";
		input.x = 64;
		input.y = 2;
		input.setSize(48, 24);
		addChild(input);
	}

	private function title(value:String):Void {
		field(null, -112, -38, 224, 21, 14, true, TextFormatAlign.CENTER).text = value;
	}

	private function field(name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign):TextField {
		var text = new TextField();
		if (name != null) text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		addChild(text);
		return text;
	}
}
