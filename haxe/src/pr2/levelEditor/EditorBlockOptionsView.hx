package pr2.levelEditor;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.gameplay.Items;
import pr2.ui.controls.GameCheckBox;
import pr2.ui.controls.GameSlider;
import pr2.ui.view.NativeView;

/** Shared native shell for item, teleport, stat, and custom-stat block options. */
class EditorBlockOptionsView extends NativeView {
	public function new(kind:String) {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-118, -68, 236, kind == "ItemBlockOptionsGraphic" ? 220 : 136, 12, 12);
		graphics.endFill();
		switch (kind) {
			case "StatBlockOptionsGraphic": statView();
			case "ItemBlockOptionsGraphic": itemView();
			case "CustomStatsBlockOptionsGraphic": customStatsView();
			case "TeleportBlockOptionsGraphic": title("-- Teleport Color --");
			default: title("-- Block Options --");
		}
	}

	private function statView():Void {
		field("titleBox", -103, -56, 206, 21, 14, true, TextFormatAlign.CENTER);
		var desc = field("descBox", -101, -31, 202, 37, 10, false, TextFormatAlign.LEFT);
		desc.multiline = true;
		desc.wordWrap = true;
		var slider = ownControl(new GameSlider(5, 100, 5, 5));
		slider.name = "slider";
		slider.x = -90;
		slider.y = 26;
		slider.setSize(150, 22);
		addChild(slider);
		field("statBox", 68, 21, 35, 22, 12, true, TextFormatAlign.CENTER);
	}

	private function itemView():Void {
		title("-- Items in this Block --");
		var codes = Items.getAllCodes();
		for (i in 0...codes.length) {
			var code = codes[i];
			var check = ownControl(new GameCheckBox(Items.getNameFromCode(code)));
			check.name = "check" + code;
			check.x = i < 5 ? -100 : 8;
			check.y = -28 + (i % 5) * 29;
			addChild(check);
		}
	}

	private function customStatsView():Void {
		title("-- Custom Stats Block --");
		var reset = ownControl(new GameCheckBox("Reset to starting stats"));
		reset.name = "resetChk";
		reset.x = -82;
		reset.y = 48;
		addChild(reset);
	}

	private function title(value:String):Void {
		field(null, -103, -56, 206, 21, 14, true, TextFormatAlign.CENTER).text = value;
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
