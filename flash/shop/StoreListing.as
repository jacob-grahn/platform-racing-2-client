package shop
{
    import com.jiggmin.data.Data;
    import com.jiggmin.data.EpicFlash;
    import flash.display.Loader;
    import flash.text.TextFieldAutoSize;
    import flash.events.TextEvent;
    import flash.net.URLRequest;
    import character.Character;
    import flash.events.MouseEvent;
    import flash.events.Event;

    public class StoreListing extends Removable 
    {

        public static const EVENT_QUANTITY_PURCHASE:String = 'itemPurchaseFromQuantity';
        public static const EVENT_PURCHASE:String = "itemPurchase";
        public static const EVENT_INFO:String = "itemInfo";

        private var m:StoreListingGraphic = new StoreListingGraphic();
        private var _listing:Object;
        private var loader:Loader;

        public function StoreListing(o:Object, flash:EpicFlash = null)
        {
            this._listing = o;
            addChild(this.m);
            this.m.bg.visible = false;
            this.m.titleBox.text = this._listing.title;
            this.m.priceBox.autoSize = TextFieldAutoSize.LEFT;
            this.m.saleBox.autoSize = TextFieldAutoSize.LEFT;
            //this.m.removeChild(this.m.coin); // added after paypal conversion
            if (this._listing.price == 0) {
                this.m.priceBox.text = "free!";
                this.m.priceBG.width = this.m.priceBox.width + 7;
                this.m.removeChild(this.m.coin);
            } else {
                this.m.priceBox.text = this._listing.price.toString();
                this.m.coin.x = Math.round(this.m.priceBox.width + this.m.priceBox.x + 3);
                this.m.priceBG.width = Math.round(this.m.coin.x + this.m.coin.width);
            }
            //this.m.priceBG.width = this.m.priceBox.width + 7; // added after paypal conversion
            if (this._listing.available && this._listing.price != 0 && this._listing.sale.active && (this._listing.sale.expires === 0 || this._listing.sale.expires > Data.getTimestamp())) {
                this.m.priceBox.text = Math.round(this._listing.price * (100 - this.listing.sale.value) / 100).toString();
                this.m.coin.x = Math.round(this.m.priceBox.width + this.m.priceBox.x + 3);
                this.m.saleBox.x = Math.round(this.m.coin.x + this.m.coin.width + 3);//PayPal: Math.round(this.m.priceBox.x + this.m.priceBox.width + 3);
                this.m.saleBox.text = this._listing.sale.value.toString() + '% off!';
                this.m.priceBG.width = Math.round(this.m.coin.x + this.m.coin.width) + this.m.saleBox.width;
                if (flash != null) {
                    flash.addItem(this.m.titleBox);
                }
            } else {
                this.m.removeChild(this.m.saleBox);
            }
            if (this._listing.slug === "epic_everything") {
                this.generateRandomCharacter(30);
                this.generateRandomCharacter(65);
                this.generateRandomCharacter(100);
            }
            this.m.descBox.htmlText = this._listing.description + " " + this.makeTextButtons(this._listing);
            this.m.descBox.addEventListener(TextEvent.LINK, this.clickTextLink, false, 0, true);
            if (this._listing.available) {
                this.activate();
            } else {
                this.deactivate();
            }
            this.loader = new Loader();
            this.loader.load(new URLRequest(this._listing.img_url));
            this.m.picHolder.addChild(this.loader);
            this.m.bg.mouseEnabled = this.m.titleBox.mouseEnabled = this.m.coin.mouseEnabled = this.m.priceBG.mouseEnabled = this.m.picHolder.mouseEnabled = false;
        }

        // _loc2, _loc3, _loc4, _loc5 = hat, head, body, feet
        // _loc6, _loc7 = hatColor, hatColor2
        // _loc8, _loc9 = headColor, headColor2
        // _loc10, _loc11 = bodyColor, bodyColor2
        // _loc12, _loc13 = feetColor, feetColor2
        // _loc14 = player
        private function generateRandomCharacter(x:Number)
        {
            var hat:int = int(Math.ceil(Math.random() * 12));
            var head:int = int(Math.ceil(Math.random() * 39));
            var body:int = int(Math.ceil(Math.random() * 39));
            var feet:int = int(Math.ceil(Math.random() * 39));
            var hatColor:int = int(Math.round(Math.random() * 0xFFFFFF));
            var hatColor2:int = int(Math.round(Math.random() * 0xFFFFFF));
            var headColor:int = int(Math.round(Math.random() * 0xFFFFFF));
            var headColor2:int = int(Math.round(Math.random() * 0xFFFFFF));
            var bodyColor:int = int(Math.round(Math.random() * 0xFFFFFF));
            var bodyColor2:int = int(Math.round(Math.random() * 0xFFFFFF));
            var feetColor:int = int(Math.round(Math.random() * 0xFFFFFF));
            var feetColor2:int = int(Math.round(Math.random() * 0xFFFFFF));
            var player:Character = new Character(hat, head, body, feet);
            this.m.addChildAt(player, 2);
            player.setHatColors(hatColor, hatColor2);
            player.setHeadColors(headColor, headColor2);
            player.setBodyColors(bodyColor, bodyColor2);
            player.setFeetColors(feetColor, feetColor2);
            player.scaleX = player.scaleY = 1;
            player.x = x;
            player.y = 85;
        }

        public function activate()
        {
            this.m.cover.buttonMode = true;
            this.m.cover.useHandCursor = true;
            this.m.cover.addEventListener(MouseEvent.MOUSE_OVER, this.onMouseOver);
            this.m.cover.addEventListener(MouseEvent.MOUSE_OUT, this.onMouseOut);
            this.m.cover.addEventListener(MouseEvent.CLICK, this.clickHandler);
            alpha = 1;
        }

        public function deactivate()
        {
            this.m.cover.buttonMode = false;
            this.m.cover.useHandCursor = false;
            this.m.cover.removeEventListener(MouseEvent.MOUSE_OVER, this.onMouseOver);
            this.m.cover.removeEventListener(MouseEvent.MOUSE_OUT, this.onMouseOut);
            this.m.cover.removeEventListener(MouseEvent.CLICK, this.clickHandler);
            alpha = 0.33;
        }

        public function get listing():Object
        {
            return this._listing;
        }

        // _loc2 = infoBtn
        // _loc3 = purchaseBtn
        // DELETED _loc4 (what's returned), _loc5 (ternary for use/buy text)
        private function makeTextButtons(item:Object):String
        {
            var purchaseBtn:String = '<u><font color="#4E4EFE"><a href="event:itemPurchase">' + (item.price == 0 ? 'use' : 'buy') + "</a></font></u>";
            var infoBtn:String = '<u><font color="#4E4EFE"><a href="event:itemInfo">more info</a></font></u>';
            return (item.available ? purchaseBtn + " / " : '') + infoBtn;
        }

        private function clickTextLink(te:TextEvent)
        {
            if (te.text == "itemPurchase") {
                dispatchEvent(new Event(StoreListing.EVENT_PURCHASE));
            }
            if (te.text == "itemInfo") {
                dispatchEvent(new Event(StoreListing.EVENT_INFO));
            }
        }

        private function clickHandler(me:MouseEvent)
        {
            dispatchEvent(new Event(StoreListing.EVENT_PURCHASE));
        }

        public function get slug():String
        {
            return this._listing.slug;
        }

        public function get available():Boolean
        {
            return this._listing.available;
        }

        public function get title():String
        {
            return this._listing.title;
        }

        // returns 1 if no sale
        public function get saleMultiplier():Number
        {
            return this._listing.available && this._listing.price != 0 && this._listing.sale.active && (this._listing.sale.expires === 0 || this._listing.sale.expires > Data.getTimestamp()) ? (100 - this._listing.sale.value) / 100 : 1.0;
        }

        // this is the current price of the item; base price - sale amount.
        public function get currentPrice():int
        {
            return int(this.m.priceBox.text);
        }

        private function onMouseOver(me:MouseEvent)
        {
            this.m.bg.visible = true;
        }

        private function onMouseOut(me:MouseEvent)
        {
            this.m.bg.visible = false;
        }

        override public function remove()
        {
            this.deactivate();
            this.m.descBox.removeEventListener(TextEvent.LINK, this.clickTextLink);
            removeChild(this.m);
            this.m = null;
            this._listing = null;
            super.remove();
        }


    }
}//package shop

