package pr2.lobby.store;

import openfl.events.Event;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.Popup;
import pr2.runtime.FlButton;
import pr2.runtime.FlSlider;
import pr2.runtime.PR2MovieClip;

class QuantityPopup extends Popup {
	public static var instance(default, null):Null<QuantityPopup>;
	public var numSelected(default, null):Int = 1;
	public var totalCost(default, null):Int;
	private var listing:StoreListingData;
	private var art:PR2MovieClip;
	private var bindings:Array<LobbyArt.Binding> = [];

	public function new(listing:StoreListingData, onBuy:Int->Void) {
		if (instance != null) instance.remove();
		super(); instance = this; this.listing = listing;
		art = PR2MovieClip.fromLinkage("QuantityPopupGraphic", {maxNestedDepth: 5}); addChild(art);
		var slider = Std.downcast(LobbyArt.findByName(art, "quantitySlider"), FlSlider);
		if (slider != null) { slider.minimum = 1; slider.maximum = listing.quantityLimit(); slider.value = 1; slider.addEventListener(Event.CHANGE, changed); }
		setText("maxBox", Std.string(listing.quantityLimit())); update();
		bind("buy_bt", function() { if (totalCost <= StorePopup.userCoins) onBuy(numSelected); });
		bind("cancel_bt", startFadeOut);
	}
	private function bind(name:String, fn:Void->Void):Void { var b = LobbyArt.bind(LobbyArt.findByName(art, name), fn); if (b != null) bindings.push(b); }
	private function changed(_:Event):Void { var slider = Std.downcast(LobbyArt.findByName(art, "quantitySlider"), FlSlider); if (slider != null) numSelected = Std.int(slider.value); update(); }
	private function update():Void {
		totalCost = listing.quantityCost(numSelected); setText("numSelectedBox", "Selected: " + numSelected);
		var cost = LobbyArt.text(art, "costBox"); if (cost != null) cost.htmlText = '<font color="#' + (totalCost <= StorePopup.userCoins ? "006600" : "BB0000") + '">Cost: $totalCost Coins</font>';
		var buy = Std.downcast(LobbyArt.findByName(art, "buy_bt"), FlButton); if (buy != null) buy.enabled = totalCost <= StorePopup.userCoins;
	}
	private function setText(name:String, value:String):Void { var field = LobbyArt.text(art, name); if (field != null) field.text = value; }
	override public function remove():Void {
		if (instance == this) instance = null;
		var slider = Std.downcast(LobbyArt.findByName(art, "quantitySlider"), FlSlider); if (slider != null) slider.removeEventListener(Event.CHANGE, changed);
		for (b in bindings) LobbyArt.unbind(b); bindings = []; art.dispose(); super.remove();
	}
}
