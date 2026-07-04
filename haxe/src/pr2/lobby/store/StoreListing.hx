package pr2.lobby.store;

import openfl.display.DisplayObject;
import openfl.display.Loader;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.TextEvent;
import openfl.net.URLRequest;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import pr2.lobby.LobbyArt;
import pr2.lobby.account.AccountCharacter;
import pr2.runtime.EpicFlash;
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
	private var randomCharacters:Array<AccountCharacter> = [];

	public function new(listing:StoreListingData, ?saleFlash:EpicFlash) {
		super(); this.listing = listing;
		art = PR2MovieClip.fromLinkage("StoreListingGraphic", {maxNestedDepth: 6}); addChild(art);
		var title = LobbyArt.text(art, "titleBox");
		if (title != null) title.text = listing.title;
		layoutPrice();
		var sale = LobbyArt.text(art, "saleBox");
		if (listing.saleMultiplier() < 1 && saleFlash != null && title != null) {
			saleFlash.addItem(title);
		}
		if (listing.slug == "epic_everything") {
			generateRandomCharacter(30);
			generateRandomCharacter(65);
			generateRandomCharacter(100);
		}
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

	public function randomCharactersForTests():Array<AccountCharacter> {
		return randomCharacters.copy();
	}

	public function displayChildForTests(name:String):Null<DisplayObject> {
		return DisplayUtil.findByName(art, name);
	}

	public function remove():Void {
		if (desc != null) desc.removeEventListener(TextEvent.LINK, textLink);
		if (cover != null) { cover.removeEventListener(MouseEvent.CLICK, click); cover.removeEventListener(MouseEvent.MOUSE_OVER, hover); cover.removeEventListener(MouseEvent.MOUSE_OUT, hover); }
		if (loader != null) { try loader.unload() catch (_:Dynamic) {}; loader = null; }
		for (character in randomCharacters) character.remove();
		randomCharacters = [];
		art.dispose(); if (parent != null) parent.removeChild(this);
	}

	private function generateRandomCharacter(x:Float):Void {
		var character = new AccountCharacter(randPart(12), randPart(39), randPart(39), randPart(39));
		character.setColors(randColor(), randColor(), randColor(), randColor(), randColor(), randColor(), randColor(), randColor());
		character.scaleX = character.scaleY = 1;
		character.x = x;
		character.y = 85;
		art.addChildAt(character, Std.int(Math.min(2, art.numChildren)));
		randomCharacters.push(character);
	}

	private static function randPart(max:Int):Int {
		return Std.int(Math.ceil(Math.random() * max));
	}

	private static function randColor():Int {
		return Std.int(Math.round(Math.random() * 0xFFFFFF));
	}

	private function layoutPrice():Void {
		var priceBox = LobbyArt.text(art, "priceBox");
		var saleBox = LobbyArt.text(art, "saleBox");
		var coin = DisplayUtil.findByName(art, "coin");
		var priceBG = DisplayUtil.findByName(art, "priceBG");
		if (priceBox != null) priceBox.autoSize = TextFieldAutoSize.LEFT;
		if (saleBox != null) saleBox.autoSize = TextFieldAutoSize.LEFT;
		if (listing.price == 0) {
			if (priceBox != null) priceBox.text = "free!";
			if (priceBG != null && priceBox != null) priceBG.width = priceBox.width + 7;
			removeFromParent(coin);
			removeFromParent(saleBox);
			return;
		}
		if (priceBox != null) priceBox.text = Std.string(listing.currentPrice());
		if (coin != null && priceBox != null) {
			coin.x = Math.round(priceBox.width + priceBox.x + 3);
		}
		if (listing.saleMultiplier() < 1) {
			if (saleBox != null) {
				if (coin != null) saleBox.x = Math.round(coin.x + coin.width + 3);
				saleBox.text = listing.saleValue + "% off!";
			}
			if (priceBG != null && coin != null && saleBox != null) {
				priceBG.width = Math.round(coin.x + coin.width) + saleBox.width;
			}
		} else {
			if (priceBG != null && coin != null) {
				priceBG.width = Math.round(coin.x + coin.width);
			}
			removeFromParent(saleBox);
		}
	}

	private static function removeFromParent(child:Null<DisplayObject>):Void {
		if (child != null && child.parent != null) {
			child.parent.removeChild(child);
		}
	}
}
