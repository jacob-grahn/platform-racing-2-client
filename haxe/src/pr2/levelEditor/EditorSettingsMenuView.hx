package pr2.levelEditor;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.gameplay.Modes;
import pr2.runtime.SvgAsset;
import pr2.ui.controls.GameSelect;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

/** Native compact shell for mode, music, and scalar editor settings. */
class EditorSettingsMenuView extends NativeView {
	public var modeSelect(default, null):Null<GameSelect<String>>;
	public var titleBox(default, null):Null<TextField>;
	public var descBox(default, null):Null<TextField>;
	public var valueInput(default, null):Null<GameTextInput>;

	public function new(kind:String) {
		super();
		if (kind == "mode") makeMode();
		if (kind == "value") makeValue();
		if (kind == "music") makeMusic();
	}

	private function makeMode():Void {
		var background = SvgAsset.createNormalized("assets/svg/ui/shadow_bg.svg");
		background.name = "background";
		background.x = -116.5;
		background.y = -59.3;
		background.scaleX = 0.845672607421875;
		background.scaleY = 0.628204345703125;
		addChild(background);
		var title = field("title", -54.95, -49, 108.9, 14.55, 12, true, TextFormatAlign.LEFT);
		title.scaleX = 1.00047302246094;
		title.text = "-- Game Mode --";
		var desc = field("description", -103.5, -23, 206, 31.1, 12, false, TextFormatAlign.CENTER);
		desc.multiline = true;
		desc.wordWrap = true;
		desc.text = "Each game mode has a different goal and method of winning.";
		modeSelect = ownControl(new GameSelect<String>());
		var select = modeSelect;
		select.name = "modeSelect";
		select.x = -50;
		select.y = 23;
		select.setSize(100, 22);
		select.rowCount = 5;
		select.addOption("Race", Modes.race);
		select.addOption("Objective", Modes.obj);
		select.addOption("Deathmatch", Modes.dm);
		select.addOption("Alien Eggs", Modes.egg);
		select.addOption("Hat Attack", Modes.hat);
		addChild(select);
	}

	private function makeValue():Void {
		var background = SvgAsset.createNormalized("assets/svg/ui/shadow_bg.svg");
		background.name = "background";
		background.x = -114.95;
		background.y = -72.75;
		background.scaleX = 0.845291137695312;
		background.scaleY = 0.628173828125;
		addChild(background);
		var title = field("titleBox", -113.45, -61, 226.85, 14.55, 12, true, TextFormatAlign.CENTER);
		title.scaleX = 1.00047302246094;
		titleBox = title;
		descBox = field("descBox", -102.5, -35.05, 206, 31.1, 12, false, TextFormatAlign.CENTER);
		var desc = descBox;
		desc.multiline = true;
		desc.wordWrap = true;
		valueInput = ownControl(new GameTextInput());
		var input = valueInput;
		input.name = "valueBox";
		input.x = -39;
		input.y = 10;
		input.setSize(77.9998779296875, 22);
		addChild(input);
	}

	private function makeMusic():Void {
		var background = SvgAsset.createNormalized("assets/svg/ui/shadow_bg.svg");
		background.name = "background";
		background.x = -120;
		background.y = -50;
		background.scaleX = 0.882400512695312;
		background.scaleY = 0.785186767578125;
		addChild(background);
		var title = field("title", -34.8, -39, 69.5, 14.55, 12, true, TextFormatAlign.LEFT);
		title.scaleX = 1.00047302246094;
		title.text = "-- Music --";
		var desc = field("description", -109.5, 19, 219.9, 64.2, 12, false, TextFormatAlign.CENTER);
		desc.multiline = true;
		desc.wordWrap = true;
		desc.text = "This song will play by default for players playing your course. Choose none for no song and random for a random one from the list.";
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
