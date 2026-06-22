package pr2.lobby.store;

/** Validated view of one `/vault/vault.php` listing. */
class StoreListingData {
	public final slug:String;
	public final title:String;
	public final description:String;
	public final faq:String;
	public final imageUrl:String;
	public final price:Int;
	public final available:Bool;
	public final maxQuantity:Int;
	public final rentedTokens:Int;
	public final saleActive:Bool;
	public final saleValue:Int;
	public final saleExpires:Int;

	public function new(value:Dynamic) {
		slug = string(value, "slug");
		title = string(value, "title");
		description = string(value, "description");
		faq = string(value, "faq");
		imageUrl = string(value, "img_url");
		price = integer(value, "price");
		available = boolean(value, "available");
		maxQuantity = Std.int(Math.max(1, integer(value, "max_quantity")));
		rentedTokens = integer(value, "rented_tokens");
		var sale = Reflect.field(value, "sale");
		saleActive = sale != null && boolean(sale, "active");
		saleValue = sale == null ? 0 : integer(sale, "value");
		saleExpires = sale == null ? 0 : integer(sale, "expires");
	}

	public function saleMultiplier(?now:Int):Float {
		if (now == null) now = Std.int(Date.now().getTime() / 1000);
		return available && price != 0 && saleActive && (saleExpires == 0 || saleExpires > now) ? (100 - saleValue) / 100 : 1;
	}

	public function currentPrice(?now:Int):Int return Math.round(price * saleMultiplier(now));

	public function quantityLimit():Int return slug == "rank_rental" ? Std.int(Math.max(0, maxQuantity - rentedTokens)) : maxQuantity;

	public function quantityCost(quantity:Int, ?now:Int):Int {
		quantity = Std.int(Math.max(1, Math.min(quantity, quantityLimit())));
		if (slug != "rank_rental") return currentPrice(now) * quantity;
		var cost = 50 * quantity;
		for (i in rentedTokens...(rentedTokens + quantity)) cost += 20 * i;
		return Std.int(cost * saleMultiplier(now));
	}

	private static function string(o:Dynamic, name:String):String {
		var value = o == null ? null : Reflect.field(o, name);
		return value == null ? "" : Std.string(value);
	}
	private static function integer(o:Dynamic, name:String):Int {
		var value = o == null ? null : Reflect.field(o, name);
		if (value == null) return 0;
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? 0 : parsed;
	}
	private static function boolean(o:Dynamic, name:String):Bool {
		var value:Dynamic = o == null ? null : Reflect.field(o, name);
		var normalized = Std.string(value).toLowerCase();
		return normalized == "true" || normalized == "1";
	}
}
