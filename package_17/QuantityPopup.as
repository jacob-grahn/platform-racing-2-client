package package_17
{
    import fl.controls.Slider;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import package_4.MessagePopup;
    import package_4.Popup;

    public class QuantityPopup extends Popup
    {

        public static var instance:QuantityPopup = null;

        public var numSelected:int = 1;
        public var totalCost:int = 0;

        private var item:StoreListing;
        private var slug:String;
        private var singlePrice:int;
        private var maxQuantity:int;
        private var m:QuantityPopupGraphic = new QuantityPopupGraphic();

        public function QuantityPopup(item:StoreListing)
        {
            if (QuantityPopup.instance != null) {
                QuantityPopup.instance.remove();
            }
            QuantityPopup.instance = this;

            this.item = item;
            this.slug = this.item.slug;
            this.singlePrice = this.totalCost = this.item.currentPrice;
            this.maxQuantity = this.m.quantitySlider.maximum = (this.slug === 'rank_rental' ? this.item.listing.max_quantity - this.item.listing.rented_tokens : this.item.listing.max_quantity);
            this.m.maxBox.text = this.maxQuantity.toString();
            this.m.numSelectedBox.text = 'Selected: 1';
            this.m.costBox.htmlText = '<font color="#006600">Cost: ' + this.singlePrice + ' Coins</font>';
            this.m.buy_bt.addEventListener(MouseEvent.CLICK, this.onClickBuy, false, 0, true);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.onClickCancel, false, 0, true);
            this.m.quantitySlider.addEventListener(Event.CHANGE, this.onSliderChange, false, 0, true);
            addChild(this.m);
        }

        private function onSliderChange(e:Event)
        {
            var quantity:int = this.numSelected = this.m.quantitySlider.value;
            this.m.numSelectedBox.text = 'Selected: ' + quantity;

            if (this.slug === 'rank_rental') {
                var rankTokenPrice:int = 50 * quantity;
                for (var i:int = this.item.listing.rented_tokens; i < quantity + this.item.listing.rented_tokens; i++) {
                    rankTokenPrice += 20 * i;
                }
            }
            this.totalCost = this.slug === 'rank_rental' ? rankTokenPrice * this.item.saleMultiplier : this.singlePrice * quantity;
            var canAfford:Boolean = this.totalCost <= StorePopup.userCoins;
            var color:String = canAfford ? '006600' : 'BB0000';
            this.m.costBox.htmlText = '<font color="#' + color + '">Cost: ' + this.totalCost + ' Coins</font>';
            this.m.buy_bt.enabled = canAfford;
        }

        private function onClickBuy(e:MouseEvent)
        {
            if (this.m.buy_bt.enabled) {
                this.item.dispatchEvent(new Event(StoreListing.EVENT_QUANTITY_PURCHASE));
            }
        }

        private function onClickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            if (QuantityPopup.instance === this) {
                QuantityPopup.instance = null;
            }
            this.m.buy_bt.removeEventListener(MouseEvent.CLICK, this.onClickBuy);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.onClickCancel);
            this.m.quantitySlider.removeEventListener(Event.CHANGE, this.onSliderChange);
            super.remove();
        }
    }
}
