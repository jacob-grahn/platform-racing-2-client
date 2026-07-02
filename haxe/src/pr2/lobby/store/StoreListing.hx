package pr2.lobby.store;

import openfl.display.Loader;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.TextEvent;
import openfl.net.URLRequest;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class StoreListing extends Sprite {
	public static inline var PURCHASE:String = "itemPurchase";
	public static inline var INFO:String = "itemInfo";
	public final listing:StoreListingData;
	private var art:PR2MovieClip;
	private var loader:Null<Loader>;
	private var cover:Null<Sprite>;
	private var desc:Null<TextField>;

	public function new(listing:StoreListingData) {
		super(); this.listing = listing;
		art = PR2MovieClip.fromLinkage("StoreListingGraphic", {maxNestedDepth: 6}); addChild(art);
		setText("titleBox", listing.title);
		setText("priceBox", listing.price == 0 ? "free!" : Std.string(listing.currentPrice()));
		var sale = LobbyArt.text(art, "saleBox");
		if (sale != null) { sale.text = listing.saleMultiplier() < 1 ? listing.saleValue + "% off!" : ""; sale.visible = sale.text != ""; }
		desc = LobbyArt.text(art, "descBox");
		if (desc != null) {
			desc.htmlText = listing.description + " " + (listing.available ? link(PURCHASE, listing.price == 0 ? "use" : "buy") + " / " : "") + link(INFO, "more info");
			desc.addEventListener(TextEvent.LINK, textLink);
		}
		cover = Std.downcast(DisplayUtil.findByName(art, "cover"), Sprite);
		if (cover != null && listing.available) {
			cover.buttonMode = cover.useHandCursor = true;
			cover.addEventListener(MouseEvent.CLICK, click);
			cover.addEventListener(MouseEvent.MOUSE_OVER, hover);
			cover.addEventListener(MouseEvent.MOUSE_OUT, hover);
		}
		alpha = listing.available ? 1 : .33;
		if (listing.imageUrl != "") {
			var holder = Std.downcast(DisplayUtil.findByName(art, "picHolder"), Sprite);
			if (holder != null) { loader = new Loader(); holder.addChild(loader); loader.load(new URLRequest(listing.imageUrl)); }
		}
	}

	private function setText(name:String, value:String):Void { var field = LobbyArt.text(art, name); if (field != null) field.text = value; }
	private static function link(event:String, label:String):String return '<u><font color="#4E4EFE"><a href="event:$event">$label</a></font></u>';
	private function textLink(e:TextEvent):Void dispatchEvent(new Event(e.text));
	private function click(_:MouseEvent):Void dispatchEvent(new Event(PURCHASE));
	private function hover(e:MouseEvent):Void { var bg = DisplayUtil.findByName(art, "bg"); if (bg != null) bg.visible = e.type == MouseEvent.MOUSE_OVER; }

	public function remove():Void {
		if (desc != null) desc.removeEventListener(TextEvent.LINK, textLink);
		if (cover != null) { cover.removeEventListener(MouseEvent.CLICK, click); cover.removeEventListener(MouseEvent.MOUSE_OVER, hover); cover.removeEventListener(MouseEvent.MOUSE_OUT, hover); }
		if (loader != null) { try loader.unload() catch (_:Dynamic) {}; loader = null; }
		art.dispose(); if (parent != null) parent.removeChild(this);
	}
}
