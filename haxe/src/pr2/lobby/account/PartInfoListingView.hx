package pr2.lobby.account;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.view.NativeView;

/** Native catalog tile for a character part. */
class PartInfoListingView extends NativeView {
	public function new() {
		super();
		var bg = new Sprite();
		bg.name = "bg";
		bg.graphics.beginFill(0xE3E2C3);
		bg.graphics.lineStyle(1, 0x9A987F);
		bg.graphics.drawRoundRect(0, 0, 122, 145, 8, 8);
		bg.graphics.endFill();
		addChild(bg);
		field("titleBox", 7, 5, 108, 18, 10, true, TextFormatAlign.CENTER);
		var owned = field("ownedBox", 8, 24, 48, 18, 9, true, TextFormatAlign.LEFT);
		owned.text = "Owned!";
		owned.textColor = 0x286828;
		var epic = field("epicBox", 60, 75, 60, 18, 8, true, TextFormatAlign.CENTER);
		epic.text = "Purchased!";
		epic.textColor = 0x713E92;
		var desc = field("descBox", 7, 96, 108, 42, 9, false, TextFormatAlign.LEFT);
		desc.multiline = true;
		desc.wordWrap = true;
		var cover = new Sprite();
		cover.name = "cover";
		cover.graphics.beginFill(0x000000, 0);
		cover.graphics.drawRect(0, 0, 122, 145);
		cover.graphics.endFill();
		addChild(cover);
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign):TextField {
		var text = new TextField();
		text.name = name;
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
