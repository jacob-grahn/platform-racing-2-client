// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_17.StoreListing = package_17.class_257

package package_17
{
    import flash.display.Loader;
    import flash.text.TextFieldAutoSize;
    import flash.events.TextEvent;
    import flash.net.URLRequest;
    import package_8.Character;
    import flash.events.MouseEvent;
    import flash.events.Event;

    public class StoreListing extends Removable 
    {

        public static const EVENT_PURCHASE:String = "itemPurchase";
        public static const EVENT_INFO:String = "itemInfo";

        private var m:StoreListingGraphic = new StoreListingGraphic();
        private var listing:Object; // var_315
        private var loader:Loader;

        public function StoreListing(o:Object)
        {
            this.listing = o;
            addChild(this.m);
            this.m.bg.visible = false;
            this.m.titleBox.text = this.listing.title;
            this.m.priceBox.autoSize = TextFieldAutoSize.LEFT;
            this.m.saleBox.autoSize = TextFieldAutoSize.LEFT;
            if (this.listing.price == 0) {
                this.m.priceBox.text = "free";
                this.m.priceBG.width = this.m.priceBox.width + 7;
                this.m.removeChild(this.m.kred);
            } else {
                this.m.priceBox.text = this.listing.price.toString();
                this.m.kred.x = Math.round(this.m.priceBox.width + this.m.priceBox.x + 3);
                this.m.priceBG.width = Math.round(this.m.kred.x + this.m.kred.width);
            }
            if (this.listing.available && this.listing.price != 0 && this.listing.discount != null) {
                this.m.saleBox.x = Math.round(this.m.kred.x + this.m.kred.width + 3);
                this.m.saleBox.text = this.listing.discount;
                this.m.priceBG.width = this.m.priceBG.width + this.m.saleBox.width;
            } else {
                this.m.removeChild(this.m.saleBox);
            }
            if (this.listing.slug === "epic-everything") {
                this.method_191(30);
                this.method_191(65);
                this.method_191(100);
            }
            this.m.descBox.htmlText = this.listing.description + " " + this.method_709(this.listing);
            this.m.descBox.addEventListener(TextEvent.LINK, this.method_237, false, 0, true);
            if (this.listing.available) {
                this.activate();
            } else {
                this.deactivate();
            }
            this.loader = new Loader();
            this.loader.load(new URLRequest(this.listing.imgUrl));
            this.m.picHolder.addChild(this.loader);
            this.m.bg.mouseEnabled = this.m.titleBox.mouseEnabled = this.m.kred.mouseEnabled = this.m.priceBG.mouseEnabled = this.m.picHolder.mouseEnabled = false;
        }

        private function method_191(_arg_1:Number)
        {
            var _local_2:int = int(Math.ceil(Math.random() * 12));
            var _local_3:int = int(Math.ceil(Math.random() * 39));
            var _local_4:int = int(Math.ceil(Math.random() * 39));
            var _local_5:int = int(Math.ceil(Math.random() * 39));
            var _local_6:int = int(Math.round(Math.random() * 0xFFFFFF));
            var _local_7:int = int(Math.round(Math.random() * 0xFFFFFF));
            var _local_8:int = int(Math.round(Math.random() * 0xFFFFFF));
            var _local_9:int = int(Math.round(Math.random() * 0xFFFFFF));
            var _local_10:int = int(Math.round(Math.random() * 0xFFFFFF));
            var _local_11:int = int(Math.round(Math.random() * 0xFFFFFF));
            var _local_12:int = int(Math.round(Math.random() * 0xFFFFFF));
            var _local_13:int = int(Math.round(Math.random() * 0xFFFFFF));
            var _local_14:Character = new Character(_local_2, _local_3, _local_4, _local_5);
            this.m.addChildAt(_local_14, 2);
            _local_14.method_133(_local_6, _local_7);
            _local_14.method_132(_local_8, _local_9);
            _local_14.method_134(_local_10, _local_11);
            _local_14.method_90(_local_12, _local_13);
            _local_14.scaleX = _local_14.scaleY = 1;
            _local_14.x = _arg_1;
            _local_14.y = 85;
        }

        public function activate()
        {
            this.m.cover.buttonMode = true;
            this.m.cover.useHandCursor = true;
            this.m.cover.addEventListener(MouseEvent.MOUSE_OVER, this.method_269);
            this.m.cover.addEventListener(MouseEvent.MOUSE_OUT, this.method_378);
            this.m.cover.addEventListener(MouseEvent.CLICK, this.clickHandler);
            alpha = 1;
        }

        public function deactivate()
        {
            this.m.cover.buttonMode = false;
            this.m.cover.useHandCursor = false;
            this.m.cover.removeEventListener(MouseEvent.MOUSE_OVER, this.method_269);
            this.m.cover.removeEventListener(MouseEvent.MOUSE_OUT, this.method_378);
            this.m.cover.removeEventListener(MouseEvent.CLICK, this.clickHandler);
            alpha = 0.33;
        }

        public function method_653():Object
        {
            return this.listing;
        }

        private function method_709(_arg_1:Object):String
        {
            var _local_2:* = "";
            var _local_3:* = "";
            var _local_4:* = "";
            var _local_5:* = "buy";
            if (_arg_1.price == 0) {
                _local_5 = "use";
            }
            _local_3 = '<u><font color="#4E4EFE"><a href="event:itemPurchase">' + _local_5 + "</a></font></u>";
            _local_2 = '<u><font color="#4E4EFE"><a href="event:itemInfo">more info</a></font></u>';
            if (_arg_1.available) {
                _local_4 = _local_3 + " / " + _local_2;
            } else {
                _local_4 = _local_2;
            }
            return _local_4;
        }

        private function method_237(_arg_1:TextEvent)
        {
            if (_arg_1.text == "itemPurchase") {
                dispatchEvent(new Event(StoreListing.EVENT_PURCHASE));
            }
            if (_arg_1.text == "itemInfo") {
                dispatchEvent(new Event(StoreListing.EVENT_INFO));
            }
        }

        private function clickHandler(_arg_1:MouseEvent)
        {
            dispatchEvent(new Event(StoreListing.EVENT_PURCHASE));
        }

        public function method_738():String
        {
            return this.listing.slug;
        }

        public function method_668():Boolean
        {
            return this.listing.available;
        }

        private function method_269(_arg_1:MouseEvent)
        {
            this.m.bg.visible = true;
        }

        private function method_378(_arg_1:MouseEvent)
        {
            this.m.bg.visible = false;
        }

        override public function remove()
        {
            this.deactivate();
            this.m.descBox.removeEventListener(TextEvent.LINK, this.method_237);
            removeChild(this.m);
            this.m = null;
            this.listing = null;
            super.remove();
        }


    }
}//package package_17

