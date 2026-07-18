package pr2.lobby.store;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Exact native composition of the authored StorePopupGraphic shell. */
class StorePopupView extends NativeView {
	public final panel:Sprite;
	public final coinsPanel:Sprite;

	public function new() {
		super();
		panel = panelAt("panel", -225, -175, 1.65446472167969, 1.62315368652344);
		coinsPanel = panelAt("coinsLeftBg", -225, 140, 1.65446472167969, 0.183242797851562);
		field("titleBox", -211.75, -162.05, 423.75, 14.55, 12, true, TextFormatAlign.CENTER, 0x000000);
		field("coinsLeftBox", -222.75, 149.5, 445.75, 14.55, 12, true, TextFormatAlign.CENTER, 0xBB0000);
		var holder = new Sprite();
		holder.name = "itemsHolder";
		holder.x = -213;
		holder.y = -135;
		addChild(holder);
		var itemsMask = new Sprite();
		itemsMask.name = "itemsMask";
		itemsMask.graphics.beginFill(0xCCCCCC);
		itemsMask.graphics.drawRect(0, 0, 410, 225);
		itemsMask.graphics.endFill();
		itemsMask.x = -213;
		itemsMask.y = -135;
		addChild(itemsMask);
		holder.mask = itemsMask;
		var close = ownControl(new GameButton("Close"));
		close.name = "close_bt";
		close.x = -50;
		close.y = 100.05;
		close.setSize(100, 22);
		addChild(close);
	}

	private function panelAt(name:String, x:Float, y:Float, scaleX:Float, scaleY:Float):Sprite {
		var holder = new Sprite();
		holder.name = name;
		holder.x = x;
		holder.y = y;
		holder.scaleX = scaleX;
		holder.scaleY = scaleY;
		holder.addChild(NativeAssets.svg(StaticSvg.QuantityPanel));
		addChild(holder);
		return holder;
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign,
		color:Int):Void {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, bold, null, null, null, null, align);
		addChild(text);
	}
}
