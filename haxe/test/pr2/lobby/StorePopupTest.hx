package pr2.lobby;

import pr2.lobby.store.StoreListingData;
import pr2.lobby.store.StorePopup;
import pr2.page.LobbyPage;

@:access(pr2.page.LobbyPage)
class StorePopupTest {
	private static var assertions = 0;

	public static function main():Void {
		var sale = listing({slug: "hat", price: 100, max_quantity: 3, sale: {active: true, value: 25, expires: 0}});
		assertEquals(75, sale.currentPrice(100), "active sale price");
		assertEquals(225, sale.quantityCost(3, 100), "regular quantity price");

		var expired = listing({slug: "hat", price: 100, max_quantity: 1, sale: {active: true, value: 25, expires: 99}});
		assertEquals(100, expired.currentPrice(100), "expired sale price");

		var rental = listing({slug: "rank_rental", price: 50, max_quantity: 10, rented_tokens: 2, sale: {active: true, value: 20, expires: 0}});
		assertEquals(8, rental.quantityLimit(), "rented tokens reduce quantity limit");
		assertEquals(160, rental.quantityCost(2, 100), "rank rental uses escalating Flash price");

		var popup = new StorePopup({
			info: {user: {coins: 321}, title: {title: "Vault Sale", flashing: false}},
			listings: [raw({slug: "hat", title: "Magic Hat", price: 100, max_quantity: 1})]
		});
		assertEquals(321, StorePopup.userCoins, "catalog publishes user coin balance");
		assertEquals("-- Vault Sale --", LobbyArt.text(popup, "titleBox").text, "server title populates authored field");
		assertEquals(true, LobbyArt.text(popup, "coinsLeftBox").visible, "coin balance becomes visible");
		popup.remove();
		assertEquals(0, StorePopup.userCoins, "cleanup clears coin balance");

		var opened = 0;
		var previousFactory = LobbyPage.createStorePopup;
		LobbyPage.createStorePopup = function():Void {
			opened++;
		};
		LobbyPopups.lastRequest = "sentinel";
		var page = new LobbyPage();
		Reflect.callMethod(page, Reflect.field(page, "clickStore"), []);
		assertEquals(1, opened, "lobby vault route opens the authored store popup");
		assertEquals("sentinel", LobbyPopups.lastRequest, "lobby vault route is no longer record-only");
		LobbyPage.createStorePopup = previousFactory;

		trace('StorePopupTest passed $assertions assertions');
	}

	private static function listing(overrides:Dynamic):StoreListingData return new StoreListingData(raw(overrides));
	private static function raw(overrides:Dynamic):Dynamic {
		var value:Dynamic = {slug: "", title: "Item", description: "Description", faq: "FAQ", img_url: "", price: 0, available: true, max_quantity: 1, rented_tokens: 0, sale: {active: false, value: 0, expires: 0}};
		for (field in Reflect.fields(overrides)) Reflect.setField(value, field, Reflect.field(overrides, field));
		return value;
	}
	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++; if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
