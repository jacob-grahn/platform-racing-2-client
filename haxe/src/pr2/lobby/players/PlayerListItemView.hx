package pr2.lobby.players;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.view.NativeView;

/** Native three-column player/guild list row. */
class PlayerListItemView extends NativeView {
	public function new() {
		super();
		graphics.beginFill(0xFFFFFF, 0.72);
		graphics.lineStyle(0, 0xBBBBBB);
		graphics.drawRect(0, 0, 238, 22);
		graphics.endFill();
		field(2, 0, 116, TextFormatAlign.LEFT);
		field(122, 0, 52, TextFormatAlign.CENTER);
		field(178, 0, 58, TextFormatAlign.CENTER);
	}

	private function field(x:Float, y:Float, width:Float, align:TextFormatAlign):Void {
		var text = new TextField();
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = 21;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0x222222, false, null, null, null, null, align);
		addChild(text);
	}
}
