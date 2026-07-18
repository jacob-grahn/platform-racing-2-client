package pr2.lobby.account;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.view.NativeView;

/** Exact native composition of the authored PartInfoListingGraphic shell. */
class PartInfoListingView extends NativeView {
	public function new() {
		super();
		var bg = rect("bg", 0, 0, 122 * 1.04917907714844, 140 * 1.1142578125, 0xC3E2E7, 1);
		addChild(bg);
		var previewGuide = rect("previewGuide", 8, 21.5, 174 * 0.6436767578125, 350 * 0.200057983398438, 0xFFFFFF, 0.501960784313725);
		addChild(previewGuide);
		field("titleBox", 10.05, 5, 109, 14.55, 12, 0x000000, TextFormatAlign.LEFT);
		var owned = field("ownedBox", 10, 25.55, 42, 12.15, 10, 0x006600, TextFormatAlign.LEFT);
		owned.text = "Owned!";
		var epic = field("epicBox", 62.05, 77.35, 55.95, 12.15, 10, 0x006600, TextFormatAlign.RIGHT);
		epic.text = "Purchased!";
		var desc = field("descBox", 10, 96, 108, 65.65, 10, 0x000000, TextFormatAlign.LEFT);
		desc.multiline = true;
		desc.wordWrap = true;
		var cover = rect("cover", 0, 0, 122 * 1.04917907714844, 140 * 0.67132568359375, 0, 0);
		addChild(cover);
	}

	private function rect(name:String, x:Float, y:Float, width:Float, height:Float, color:Int, alpha:Float):Sprite {
		var sprite = new Sprite();
		sprite.name = name;
		sprite.x = x;
		sprite.y = y;
		sprite.graphics.beginFill(color, alpha);
		sprite.graphics.drawRect(0, 0, width, height);
		sprite.graphics.endFill();
		return sprite;
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, color:Int, align:TextFormatAlign):TextField {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, false, null, null, null, null, align);
		addChild(text);
		return text;
	}
}
