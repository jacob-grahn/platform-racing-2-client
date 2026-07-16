package pr2.lobby.store;

import pr2.lobby.dialogs.Popup;

class QuantityPopup extends Popup {
	public static var instance(default, null):Null<QuantityPopup>;
	public var numSelected(default, null):Int = 1;
	public var totalCost(default, null):Int;
	private var listing:StoreListingData;
	public final view:QuantityPopupView;

	public function new(listing:StoreListingData, onBuy:Int->Void) {
		if (instance != null) instance.remove();
		super();
		instance = this;
		this.listing = listing;
		view = new QuantityPopupView(listing.quantityLimit());
		view.quantitySlider.onChange = changed;
		view.onBuy = function():Void { if (totalCost <= StorePopup.userCoins) onBuy(numSelected); };
		view.onCancel = startFadeOut;
		addChild(view);
		update();
	}
	private function changed(value:Float):Void { numSelected = Std.int(value); update(); }
	private function update():Void {
		totalCost = listing.quantityCost(numSelected);
		view.showSelection(numSelected, totalCost, totalCost <= StorePopup.userCoins);
	}
	override public function remove():Void {
		if (instance == this) instance = null;
		view.dispose();
		super.remove();
	}
}
