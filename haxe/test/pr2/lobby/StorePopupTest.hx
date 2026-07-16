package pr2.lobby;

import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.lobby.store.QuantityPopup;
import pr2.lobby.store.StoreListing;
import pr2.lobby.store.StoreListingData;
import pr2.lobby.store.StorePopup;
import pr2.page.LobbyPage;

@:access(pr2.page.LobbyPage)
@:access(pr2.lobby.store.StorePopup)
class StorePopupTest {
	private static var assertions = 0;

	public static function main():Void {
		var sale = listing({slug: "hat", price: 100, max_quantity: 3, sale: {active: true, value: 25, expires: 0}});
		assertEquals(75, sale.currentPrice(100), "active sale price");
		if (pr2.DeterministicTestMode.finishSmokeSuite("StorePopupTest")) return;
		assertEquals(225, sale.quantityCost(3, 100), "regular quantity price");

		var expired = listing({slug: "hat", price: 100, max_quantity: 1, sale: {active: true, value: 25, expires: 99}});
		assertEquals(100, expired.currentPrice(100), "expired sale price");

		var rental = listing({slug: "rank_rental", price: 50, max_quantity: 10, rented_tokens: 2, sale: {active: true, value: 20, expires: 0}});
		assertEquals(8, rental.quantityLimit(), "rented tokens reduce quantity limit");
		assertEquals(160, rental.quantityCost(2, 100), "rank rental uses escalating Flash price");
		assertContains(StorePopup.confirmationMessage(sale, 3), "terms_of_use.php", "purchase confirmation links PR2 Terms of Use");
		assertContains(StorePopup.confirmationMessage(sale, 3), "<b>3</b> of", "quantity purchase confirmation includes selected count");

		var freeListing = new StoreListing(listing({slug: "freebie", price: 0, max_quantity: 1}));
		assertEquals(null, freeListing.displayChildForTests("coin"), "free listings remove the coin icon");
		assertEquals(null, freeListing.displayChildForTests("saleBox"), "free listings remove the sale text");
		freeListing.remove();

		var saleListing = new StoreListing(sale);
		assertEquals(true, saleListing.displayChildForTests("saleBox").x > saleListing.displayChildForTests("coin").x,
			"sale text sits after the coin icon");
		assertEquals(true, saleListing.displayChildForTests("priceBG").width > saleListing.displayChildForTests("coin").x,
			"sale price background expands past the coin icon");
		saleListing.remove();

		var popup = new StorePopup({
			info: {user: {coins: 1234567}, title: {title: "Vault Sale", flashing: true}},
			listings: [
				raw({slug: "epic_everything", title: "Magic Epic Everything", price: 100, max_quantity: 1, sale: {active: true, value: 50, expires: 0}}),
				raw({slug: "head", title: "Magic Head", price: 100, max_quantity: 1}),
				raw({slug: "body", title: "Magic Body", price: 100, max_quantity: 1}),
				raw({slug: "feet", title: "Magic Feet", price: 100, max_quantity: 1}),
				raw({slug: "rank", title: "Magic Rank", price: 100, max_quantity: 1}),
				raw({slug: "epic", title: "Magic Epic", price: 100, max_quantity: 1})
			]
		});
		assertEquals(1234567, StorePopup.userCoins, "catalog publishes user coin balance");
		assertEquals("-- Vault Sale --", LobbyArt.text(popup, "titleBox").text, "server title populates authored field");
		assertEquals(true, LobbyArt.text(popup, "coinsLeftBox").visible, "coin balance becomes visible");
		assertContains(LobbyArt.text(popup, "coinsLeftBox").htmlText, "1,234,567", "coin balance uses Flash number formatting");
		assertEquals(true, popup.saleFlashHasItemsForTests(), "sale title/listing text registers with EpicFlash");
		assertEquals(3, popup.listingsForTests()[0].randomCharactersForTests().length, "epic_everything listing renders three random characters");
		var scroll = popup.scrollForTests();
		assertNotNull(scroll, "store mounts authored CustomScrollBar");
		assertEquals(202.0, scroll.x, "store scrollbar x matches Flash placement");
		assertEquals(-115.0, scroll.y, "store scrollbar y matches Flash placement");
		scroll.position(scroll.thumbMaxYForTests());
		assertEquals(true, popup.holderForTests().y < 0, "store scrollbar moves the listings holder");
		popup.remove();
		assertEquals(true, scroll.removedForTests(), "store cleanup removes authored scrollbar listeners");
		assertEquals(0, StorePopup.userCoins, "cleanup clears coin balance");

		testPurchaseUploadCallbacks();
		testNativeQuantityPopupFlow();

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

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++; if (value == null) throw '$message: value was null';
	}

	private static function assertContains(haystack:String, needle:String, message:String):Void {
		assertions++; if (haystack == null || haystack.indexOf(needle) < 0) throw '$message: expected to find $needle in $haystack';
	}

	private static function testPurchaseUploadCallbacks():Void {
		closeAllPopups();
		var previousFactory = UploadingPopup.postFactory;
		var popup = new StorePopup({
			info: {user: {coins: 50}, title: {title: "Vault", flashing: false}},
			listings: []
		});
		var quantity = new QuantityPopup(listing({slug: "rank_rental", price: 50, max_quantity: 2}), function(_):Void {});
		UploadingPopup.postFactory = function(_url, _fields, onResult, _onError):Void {
			onResult('{"success":true}');
		};
		popup.postPurchase("test://purchase", new Map<String, String>(), "Purchasing item...");
		assertEquals(true, quantity.fadeOutStarted, "purchase upload fades open quantity popup");
		assertEquals(true, popup.fadeOutStarted, "successful purchase upload fades store popup");
		popup.remove();
		closeAllPopups();

		var errorPopup = new StorePopup({
			info: {user: {coins: 50}, title: {title: "Vault", flashing: false}},
			listings: []
		});
		UploadingPopup.postFactory = function(_url, _fields, _onResult, onError):Void {
			onError("Upload failed");
		};
		errorPopup.postPurchase("test://purchase", new Map<String, String>(), "Purchasing item...");
		var opened = Popup.getOpen();
		assertEquals(true, Std.downcast(opened[opened.length - 1], MessagePopup) != null, "purchase upload errors open a message popup");
		assertEquals(false, errorPopup.fadeOutStarted, "failed purchase upload keeps store popup open");
		errorPopup.remove();
		UploadingPopup.postFactory = previousFactory;
		closeAllPopups();
	}

	private static function testNativeQuantityPopupFlow():Void {
		StorePopup.userCoins = 125;
		var purchases = 0;
		var popup = new QuantityPopup(listing({slug: "hat", price: 50, max_quantity: 3}), function(quantity:Int):Void purchases += quantity);
		assertEquals("3", popup.view.maxQuantity.text, "native quantity view owns typed maximum text");
		assertEquals(true, popup.view.quantitySlider.focused == false, "native quantity slider begins unfocused");
		popup.view.quantitySlider.focus();
		assertEquals(true, popup.view.quantitySlider.focused, "native quantity slider accepts focus");
		popup.view.quantitySlider.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.RIGHT));
		assertEquals(2, popup.numSelected, "keyboard increments selected quantity");
		assertEquals(100, popup.totalCost, "keyboard selection recalculates regular cost");
		popup.view.quantitySlider.setValueFromPositionForTests(175);
		assertEquals(3, popup.numSelected, "pointer selection reaches slider maximum");
		assertEquals(false, popup.view.buyButton.enabled, "unaffordable maximum disables typed buy button");
		popup.view.quantitySlider.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.LEFT));
		assertEquals(true, popup.view.buyButton.enabled, "affordable keyboard selection re-enables buy button");
		popup.view.buyButton.activate();
		assertEquals(2, purchases, "typed buy action preserves selected quantity callback");
		popup.view.cancelButton.activate();
		assertEquals(true, popup.fadeOutStarted, "typed cancel action starts the existing close animation");
		popup.remove();
		assertEquals(true, popup.view.disposed, "native view disposes controls and listeners with popup");
	}

	private static function closeAllPopups():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}
}
