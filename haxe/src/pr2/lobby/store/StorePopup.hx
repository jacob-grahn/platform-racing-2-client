package pr2.lobby.store;

import haxe.Json;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.TextEvent;
import com.jiggmin.data.Data;
import pr2.crypto.PR2Encryptor;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbySession;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.net.ServerConfig;
import pr2.net.TextLoader;
import pr2.runtime.EpicFlash;
import pr2.ui.view.LoadingView;
import pr2.ui.CustomScrollBar;
import pr2.util.AsyncRemovalGuard;
import pr2.util.DisplayUtil;

/** Flash-compatible Vault of Magics catalog and purchase flow. */
class StorePopup extends Popup {
	public static var userCoins(default, null):Int = 0;
	private static inline var URL_KEY = "OTkhX24+S0VVaHlAIXhqbA==";
	private static inline var URL_IV = "J1N0QSJzSWV6ZT4mIz5vKA==";
	private var art:StorePopupView;
	private var holder:Null<DisplayObjectContainer>;
	private var listings:Array<StoreListing> = [];
	private var bindings:Array<LobbyArt.Binding> = [];
	private var loading:Null<LoadingView>;
	private var scroll:Null<CustomScrollBar>;
	private var saleFlash:EpicFlash = new EpicFlash();
	private var asyncGuard:AsyncRemovalGuard = new AsyncRemovalGuard();

	/** `fixture` is used by deterministic tests; production always loads the API. */
	public function new(?fixture:Dynamic) {
		super();
		art = new StorePopupView(); addChild(art);
		holder = Std.downcast(DisplayUtil.directChildByName(art, "itemsHolder"), DisplayObjectContainer);
		var coins = LobbyArt.directText(art, "coinsLeftBox");
		if (coins != null) { coins.visible = false; coins.addEventListener(TextEvent.LINK, needMore); }
		var close = LobbyArt.bind(DisplayUtil.directChildByName(art, "close_bt"), startFadeOut); if (close != null) bindings.push(close);
		if (holder != null) {
			scroll = new CustomScrollBar();
			scroll.x = 202;
			scroll.y = -115;
			scroll.height = 225;
			addChild(scroll);
			scroll.init(holder, 225, 225);
		}
		if (fixture != null) populate(fixture); else load();
	}

	private function load():Void {
		loading = new LoadingView(); addChild(loading);
		var join = ServerConfig.vaultUrl().indexOf("?") < 0 ? "?" : "&";
		var url = ServerConfig.vaultUrl() + join + "rand=" + Std.random(10000000) + "&token=" + StringTools.urlEncode(LobbySession.token);
		asyncGuard.watch(TextLoader.load(url, asyncGuard.wrap(function(body:String):Void {
			try {
				var data:Dynamic = Json.parse(body);
				var error = Reflect.field(data, "error");
				if (error != null || Reflect.field(data, "success") == false) throw error == null ? "An unknown error occurred." : Std.string(error);
				populate(data);
			} catch (error:Dynamic) fail(Std.string(error));
		}), asyncGuard.wrap(fail)));
	}

	private function fail(message:String):Void { new MessagePopup("Error: " + message); startFadeOut(); }

	private function populate(data:Dynamic):Void {
		if (loading != null) { loading.dispose(); if (loading.parent != null) loading.parent.removeChild(loading); loading = null; }
		var info = Reflect.field(data, "info");
		var user = info == null ? null : Reflect.field(info, "user");
		userCoins = intField(user, "coins");
		var coins = LobbyArt.directText(art, "coinsLeftBox");
		if (coins != null) {
			coins.htmlText = '<b><font color="#' + (userCoins == 0 ? "BB0000" : "006600") + '">You have ' + Data.formatNumber(userCoins) + ' Coins remaining.</font> <u><font color="#4E4EFE"><a href="event:clickNeedMore">Need more?</a></font></u></b>';
			coins.visible = true;
		}
		var title = info == null ? null : Reflect.field(info, "title");
		if (title != null) {
			var box = LobbyArt.directText(art, "titleBox");
			if (box != null) {
				box.text = "-- " + stringField(title, "title") + " --";
				if (boolField(title, "flashing")) {
					saleFlash.addItem(box);
				}
			}
		}
		var values:Array<Dynamic> = cast Reflect.field(data, "listings");
		if (values == null) return;
		for (value in values) addListing(new StoreListingData(value));
		if (!saleFlash.isEmpty()) {
			saleFlash.start();
		}
	}

	private function addListing(data:StoreListingData):Void {
		var listing = new StoreListing(data, saleFlash);
		listing.x = (listings.length % 3) * 137;
		listing.y = Math.floor(listings.length / 3) * 160;
		listing.addEventListener(StoreListing.PURCHASE, purchase);
		listing.addEventListener(StoreListing.INFO, info);
		if (holder != null) holder.addChild(listing);
		listings.push(listing);
	}

	private function purchase(event:Event):Void {
		var item = Std.downcast(event.currentTarget, StoreListing); if (item == null) return;
		if (!LobbySession.isMember()) { new MessagePopup("Error: You must be logged in to use the Vault of Magics."); startFadeOut(); return; }
		if (item.listing.slug == "stats_boost") { postPurchase(ServerConfig.vaultSuperBoosterUrl(), ["server_id" => LobbySession.server == null ? "0" : Std.string(LobbySession.server.serverId)], "Powering up..."); startFadeOut(); return; }
		if (userCoins < item.listing.currentPrice()) { new MessagePopup("Error: You don't have enough coins to purchase this item."); return; }
		if (item.listing.maxQuantity > 1) {
			new QuantityPopup(item.listing, function(quantity:Int):Void confirmPurchase(item.listing, quantity));
		} else confirmPurchase(item.listing, 1);
	}

	private function confirmPurchase(item:StoreListingData, quantity:Int):Void {
		new ConfirmPopup(function():Void postPurchase(ServerConfig.vaultPurchaseUrl(), ["slug" => item.slug, "quantity" => Std.string(quantity)], "Purchasing item..."),
			confirmationMessage(item, quantity));
	}

	private function postPurchase(url:String, fields:Map<String, String>, label:String):Void {
		fields.set("token", LobbySession.token); fields.set("rand", Std.string(Std.random(10000000)));
		if (QuantityPopup.instance != null) {
			QuantityPopup.instance.startFadeOut();
		}
		new UploadingPopup(url, fields, label, function(result:Dynamic):Void {
			if (result != null && Reflect.field(result, "success") == true) startFadeOut();
			else if (result != null && Reflect.field(result, "error") != null) new MessagePopup("Error: " + Std.string(Reflect.field(result, "error")));
		}, function(message:String):Void new MessagePopup("Error: " + message));
	}

	private function info(event:Event):Void { var item = Std.downcast(event.currentTarget, StoreListing); if (item != null) new MessagePopup('<b>--- ${item.listing.title} FAQ ---</b> \n\n${item.listing.faq}'); }
	private function needMore(_:TextEvent):Void new ConfirmPopup(openBuyCoins, "You will be routed to pr2hub.com in order to complete this transaction.");
	private function openBuyCoins():Void {
		#if js
		var payload = Json.stringify({token: LobbySession.token, time: Std.int(Date.now().getTime() / 1000), rand: Std.random(10000000)});
		var encrypted = PR2Encryptor.encryptBase64(payload, URL_KEY, URL_IV);
		var document = js.Browser.document;
		var form = document.createFormElement(); form.method = "POST"; form.action = ServerConfig.vaultBuyCoinsUrl(); form.target = "_blank";
		var input = document.createInputElement(); input.name = "data"; input.value = encrypted; form.appendChild(input); document.body.appendChild(form); form.submit(); document.body.removeChild(form);
		#end
		startFadeOut();
	}
	private static function intField(o:Dynamic, name:String):Int { var n = o == null ? null : Std.parseInt(Std.string(Reflect.field(o, name))); return n == null ? 0 : n; }
	private static function stringField(o:Dynamic, name:String):String { var v = o == null ? null : Reflect.field(o, name); return v == null ? "" : Std.string(v); }
	private static function boolField(o:Dynamic, name:String):Bool {
		var v = o == null ? null : Reflect.field(o, name);
		var normalized = Std.string(v).toLowerCase();
		return normalized == "true" || normalized == "1";
	}

	public static function confirmationMessage(item:StoreListingData, quantity:Int):String {
		var cost = item.quantityCost(quantity);
		var quantityCopy = quantity > 1 ? '<b>$quantity</b> of ' : "";
		var terms = Data.urlify(ServerConfig.getHost() + "/terms_of_use.php", "PR2 Terms of Use");
		return 'Are you sure you\'d like to purchase ' + quantityCopy + 'this lovely <b>${item.title}</b>? Your account will be debited <b>$cost coins</b>.\n\nPlease see the ' + terms + ' for more information.';
	}

	public function scrollForTests():Null<CustomScrollBar> {
		return scroll;
	}

	public function holderForTests():Null<DisplayObjectContainer> {
		return holder;
	}

	public function listingsForTests():Array<StoreListing> {
		return listings.copy();
	}

	public function saleFlashHasItemsForTests():Bool {
		return !saleFlash.isEmpty();
	}

	override public function remove():Void {
		asyncGuard.remove();
		userCoins = 0;
		saleFlash.remove();
		var coins = LobbyArt.directText(art, "coinsLeftBox"); if (coins != null) coins.removeEventListener(TextEvent.LINK, needMore);
		for (binding in bindings) LobbyArt.unbind(binding); bindings = [];
		for (listing in listings) {
			listing.removeEventListener(StoreListing.PURCHASE, purchase);
			listing.removeEventListener(StoreListing.INFO, info);
			listing.remove();
		}
		listings = [];
		if (scroll != null) {
			scroll.remove();
			scroll = null;
		}
		if (loading != null) {
			if (loading.parent != null) loading.parent.removeChild(loading);
			loading.dispose();
			loading = null;
		}
		holder = null;
		art.dispose();
		super.remove();
	}
}
