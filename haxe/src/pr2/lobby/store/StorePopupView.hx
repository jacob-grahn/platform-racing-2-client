package pr2.lobby.store;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native catalog shell shared by the Vault and part-information browser. */
class StorePopupView extends NativeView {
	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-215, -150, 430, 300, 14, 14);
		graphics.endFill();
		field("titleBox", -170, -137, 340, 24, 17, true, TextFormatAlign.CENTER);
		var coinsBg = new Sprite();
		coinsBg.name = "coinsLeftBg";
		coinsBg.graphics.beginFill(0xE7E7E7);
		coinsBg.graphics.drawRoundRect(-190, -108, 380, 25, 7, 7);
		coinsBg.graphics.endFill();
		addChild(coinsBg);
		field("coinsLeftBox", -185, -105, 370, 20, 10, false, TextFormatAlign.CENTER);
		var holder = new Sprite();
		holder.name = "itemsHolder";
		holder.x = -202;
		holder.y = -74;
		addChild(holder);
		var close = ownControl(new GameButton("Close"));
		close.name = "close_bt";
		close.x = -44;
		close.y = 116;
		close.setSize(88, 24);
		addChild(close);
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign):Void {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		addChild(text);
	}
}
