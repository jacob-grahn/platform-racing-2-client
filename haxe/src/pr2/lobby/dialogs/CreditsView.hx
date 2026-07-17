package pr2.lobby.dialogs;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native paginated credits presentation. */
class CreditsView extends NativeView {
	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-220, -170, 440, 340, 14, 14);
		graphics.endFill();
		label("-- Platform Racing 2 Credits --", null, -190, -154, 380, 25, 17, true, TextFormatAlign.CENTER);
		label("", "versionBox", -195, -126, 190, 18, 10, false, TextFormatAlign.LEFT);
		label("", "buildBox", 5, -126, 190, 18, 10, false, TextFormatAlign.RIGHT);
		label("Art", null, -198, -96, 184, 20, 13, true, TextFormatAlign.CENTER);
		label("Music", null, 14, -96, 184, 20, 13, true, TextFormatAlign.CENTER);
		page("artPg1", -198, -72, "Original game and character art\nJiggmin\n\nInterface and environment art\nPR2 contributors");
		page("artPg2", -198, -72, "Additional hats and parts\nCommunity artists\n\nVector restoration\nOpen-source contributors");
		page("artPg3", -198, -72, "Special thanks\nPR2 players, moderators,\nand preservation communities");
		page("musicPg1", 14, -72, "Noodle Town\nThe Wires\nBefore Mydnite\nMiniature Fantasy\nWe Are Loud");
		page("musicPg2", 14, -72, "Crysalina\nInstrumental tracks and loops\nby the original PR2 musicians");
		label("", "art_nav_bts", -198, 86, 184, 22, 10, false, TextFormatAlign.CENTER);
		label("", "music_nav_bt", 14, 86, 184, 22, 10, false, TextFormatAlign.CENTER);
		var close = ownControl(new GameButton("Close"));
		close.name = "close_bt";
		close.x = -44;
		close.y = 126;
		close.setSize(88, 25);
		addChild(close);
	}

	private function page(name:String, x:Float, y:Float, content:String):Void {
		var page = new Sprite();
		page.name = name;
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = 184;
		field.height = 154;
		field.multiline = true;
		field.wordWrap = true;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0x333333, false, null, null, null, null,
			TextFormatAlign.CENTER);
		field.text = content;
		page.addChild(field);
		addChild(page);
	}

	private function label(value:String, name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign):TextField {
		var field = new TextField();
		if (name != null) field.name = name;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		field.text = value;
		addChild(field);
		return field;
	}
}
