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
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.lobby.LobbyArt;
import pr2.lobby.account.AccountCharacter;
import pr2.runtime.EpicFlash;
import pr2.util.DisplayUtil;

class StoreListing extends Sprite {
	public static inline var PURCHASE:String = "itemPurchase";
	public static inline var INFO:String = "itemInfo";
	public final listing:StoreListingData;
	private var art:Sprite;
	private var loader:Null<Loader>;
	private var cover:Null<Sprite>;
	private var desc:Null<TextField>;
	private var randomCharacters:Array<AccountCharacter> = [];

	public function new(listing:StoreListingData, ?saleFlash:EpicFlash) {
		super(); this.listing = listing;
		art = createArt(); addChild(art);
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

	private function createArt():Sprite {
		var root = new Sprite();
		var cover = new Sprite();
		cover.name = "cover";
		cover.graphics.beginFill(0xFFFFFF, 0.001);
		cover.graphics.drawRoundRect(0, 0, 220, 118, 8, 8);
		cover.graphics.endFill();
		root.addChild(cover);
		var hover = new Sprite();
		hover.name = "bg";
		hover.graphics.beginFill(0xDCEBFF, 0.45);
		hover.graphics.lineStyle(1, 0x6B91C2);
		hover.graphics.drawRoundRect(0, 0, 220, 118, 8, 8);
		hover.graphics.endFill();
		hover.visible = false;
		root.addChild(hover);
		var pic = new Sprite();
		pic.name = "picHolder";
		pic.x = 8;
		pic.y = 8;
		root.addChild(pic);
		var priceBG = new Sprite();
		priceBG.name = "priceBG";
		priceBG.x = 112;
		priceBG.y = 7;
		priceBG.graphics.beginFill(0xFFF3B0, 0.9);
		priceBG.graphics.drawRoundRect(0, 0, 96, 20, 6, 6);
		priceBG.graphics.endFill();
		root.addChild(priceBG);
		root.addChild(createField("titleBox", 72, 31, 136, 18, 13, true));
		root.addChild(createField("descBox", 72, 55, 136, 55, 10, false));
		root.addChild(createField("priceBox", 117, 9, 35, 16, 11, true));
		root.addChild(createField("saleBox", 170, 9, 50, 16, 10, false));
		var coin = new Sprite();
		coin.name = "coin";
		coin.x = 154;
		coin.y = 11;
		coin.graphics.beginFill(0xF4C542);
		coin.graphics.lineStyle(1, 0x8A6913);
		coin.graphics.drawCircle(5, 5, 5);
		coin.graphics.endFill();
		root.addChild(coin);
		root.addChild(cover);
		return root;
	}

	private function createField(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool):TextField {
		var field = new TextField();
		field.name = name;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.multiline = true;
		field.wordWrap = true;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0, bold);
		return field;
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
		if (art.parent != null) art.parent.removeChild(art); if (parent != null) parent.removeChild(this);
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
