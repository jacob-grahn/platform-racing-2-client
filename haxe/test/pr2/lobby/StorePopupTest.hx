package pr2.lobby;

import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.ui.Keyboard;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.lobby.store.QuantityPopup;
import pr2.lobby.store.StoreListing;
import pr2.lobby.store.StoreListingData;
import pr2.lobby.store.StorePopup;
import pr2.page.LobbyPage;
import pr2.util.TestDisplayUtil as DisplayUtil;

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
		var listingBg = saleListing.displayChildForTests("bg");
		var previewGuide = saleListing.displayChildForTests("previewGuide");
		var listingCover = saleListing.displayChildForTests("cover");
		assertClose(8, previewGuide.x, "store preview guide keeps XFL X");
		assertClose(25, previewGuide.y, "store preview guide keeps XFL Y");
		assertClose(174 * 0.6436767578125, previewGuide.width, "store preview guide keeps XFL width");
		assertClose(350 * 0.17999267578125, previewGuide.height, "store preview guide keeps XFL height");
		assertClose(10.05, saleListing.displayChildForTests("titleBox").x, "store title keeps XFL X");
		assertClose(7, saleListing.displayChildForTests("titleBox").y, "store title keeps XFL Y");
		assertClose(10, saleListing.displayChildForTests("descBox").x, "store description keeps XFL X");
		assertClose(96, saleListing.displayChildForTests("descBox").y, "store description keeps XFL Y");
		assertClose(8, saleListing.displayChildForTests("priceBG").x, "store price background keeps XFL X");
		assertClose(70, saleListing.displayChildForTests("priceBG").y, "store price background keeps XFL Y");
		assertClose(122 * 1.04917907714844, listingBg.width, "store hover background keeps XFL width");
		assertClose(140 * 1.1142578125, listingBg.height, "store hover background keeps XFL height");
		assertClose(122 * 1.04917907714844, listingCover.width, "store cover keeps XFL width");
		assertClose(140 * 0.67132568359375, listingCover.height, "store cover keeps XFL height");
		assertEquals(false, listingBg.visible, "store hover background starts hidden");
		listingCover.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals(true, listingBg.visible, "available store cover reveals authored hover background");
		listingCover.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals(false, listingBg.visible, "store hover background hides on pointer exit");
		assertEquals(true, saleListing.displayChildForTests("saleBox").x > saleListing.displayChildForTests("coin").x,
			"sale text sits after the coin icon");
		assertEquals(true, saleListing.displayChildForTests("priceBG").width > saleListing.displayChildForTests("coin").x,
			"sale price background expands past the coin icon");
		saleListing.remove();

		var unavailableListing = new StoreListing(listing({slug: "locked", price: 10, available: false}));
		assertClose(0.33, unavailableListing.alpha, "unavailable store listings keep Flash dimming");
		unavailableListing.displayChildForTests("cover").dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals(false, unavailableListing.displayChildForTests("bg").visible, "unavailable listings do not install hover behavior");
		unavailableListing.remove();

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
		var panel = DisplayUtil.findByName(popup, "panel");
		var coinsPanel = DisplayUtil.findByName(popup, "coinsLeftBg");
		var holder = DisplayUtil.findByName(popup, "itemsHolder");
		var close = DisplayUtil.findByName(popup, "close_bt");
		assertClose(-225, panel.x, "store ShadowBG keeps XFL X");
		assertClose(-175, panel.y, "store ShadowBG keeps XFL Y");
		assertClose(1.65446472167969, panel.scaleX, "store ShadowBG keeps XFL horizontal scale");
		assertClose(1.62315368652344, panel.scaleY, "store ShadowBG keeps XFL vertical scale");
		assertClose(140, coinsPanel.y, "coins ShadowBG keeps XFL Y");
		assertClose(0.183242797851562, coinsPanel.scaleY, "coins ShadowBG keeps XFL vertical scale");
		assertClose(-213, holder.x, "store items holder keeps XFL X");
		assertClose(-135, holder.y, "store items holder keeps XFL Y");
		assertClose(-50, close.x, "store Close keeps XFL X");
		assertClose(100.05, close.y, "store Close keeps XFL Y");
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

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++; if (Math.abs(expected - actual) > 0.000001) throw '$message: expected $expected, got $actual';
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
