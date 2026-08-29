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
import pr2.net.ServerConfig;
import pr2.page.LobbyPage;
import pr2.util.TestDisplayUtil as DisplayUtil;

@:access(pr2.page.LobbyPage)
@:access(pr2.lobby.store.StorePopup)
class StorePopupTest {
	private static var assertions = 0;

	public static function main():Void {
		var sale = listing({slug: "hat", price: 100, max_quantity: 3, sale: {active: true, value: 25, expires: 0}});
		pr2.DeterministicTestMode.runTest("StorePopupTest.testActiveSalePrice", function():Void {
		assertEquals(75, sale.currentPrice(100), "active sale price");
		});
		if (pr2.DeterministicTestMode.finishSmokeSuite("StorePopupTest")) return;

		pr2.DeterministicTestMode.runTest("StorePopupTest.testPurchaseUploadCallbacks", testPurchaseUploadCallbacks);
		pr2.DeterministicTestMode.runTest("StorePopupTest.testNativeQuantityPopupFlow", testNativeQuantityPopupFlow);
		pr2.DeterministicTestMode.runTest("StorePopupTest.testPanelScaleGrids", testPanelScaleGrids);

		pr2.DeterministicTestMode.runTest("StorePopupTest.testLobbyVaultRoute", function():Void {
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
		});

		trace('StorePopupTest passed $assertions assertions');
	}

	private static function listing(overrides:Dynamic):StoreListingData return new StoreListingData(raw(overrides));
	private static function testPanelScaleGrids():Void {
		var popup = new StorePopup({
			info: {user: {coins: 0}, title: {title: "Vault", flashing: false}},
			listings: []
		});
		assertEquals(true, popup.art.panel.scale9Grid != null, "store panel preserves the ShadowBG scale grid");
		assertEquals(true, popup.art.coinsPanel.scale9Grid != null, "store coins panel preserves the ShadowBG scale grid");
		popup.remove();
	}

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
