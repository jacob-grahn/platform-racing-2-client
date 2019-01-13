// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_17.class_257

package package_17
{
    import flash.display.Loader;
    import flash.text.TextFieldAutoSize;
    import flash.events.TextEvent;
    import flash.net.URLRequest;
    import package_8.Character;
    import flash.events.MouseEvent;
    import flash.events.Event;

    public class class_257 extends class_7 
    {

        public static const EVENT_PURCHASE:String = "itemPurchase";
        public static const EVENT_INFO:String = "itemInfo";

        private var m:StoreListingGraphic = new StoreListingGraphic();
        private var var_315:Object;
        private var loader:Loader;

        public function class_257(_arg_1:Object)
        {
            this.var_315 = _arg_1;
            addChild(this.m);
            this.m.bg.visible = false;
            this.m.titleBox.text = _arg_1.title;
            this.m.var_264.autoSize = TextFieldAutoSize.LEFT;
            this.m.var_288.autoSize = TextFieldAutoSize.LEFT;
            if (_arg_1.price == 0) {
                this.m.var_264.text = "free";
                this.m.var_310.width = (this.m.var_264.width + 7);
                this.m.removeChild(this.m.var_213);
            } else {
                this.m.var_264.text = _arg_1.price.toString();
                this.m.var_213.x = Math.round(((this.m.var_264.width + this.m.var_264.x) + 3));
                this.m.var_310.width = Math.round((this.m.var_213.x + this.m.var_213.width));
            }
            if ((((_arg_1.available) && (!(_arg_1.price == 0))) && (!(_arg_1.discount == null)))) {
                this.m.var_288.x = Math.round(((this.m.var_213.x + this.m.var_213.width) + 3));
                this.m.var_288.text = _arg_1.discount;
                this.m.var_310.width = (this.m.var_310.width + this.m.var_288.width);
            } else {
                this.m.removeChild(this.m.var_288);
            }
            if (_arg_1.slug === "epic-everything") {
                this.method_191(30);
                this.method_191(65);
                this.method_191(100);
            }
            this.m.var_283.htmlText = ((_arg_1.description + " ") + this.method_709(_arg_1));
            this.m.var_283.addEventListener(TextEvent.LINK, this.method_237, false, 0, true);
            if (_arg_1.available) {
                this.activate();
            } else {
                this.deactivate();
            }
            this.loader = new Loader();
            this.loader.load(new URLRequest(_arg_1.imgUrl));
            this.m.var_546.addChild(this.loader);
            this.m.bg.mouseEnabled = (this.m.titleBox.mouseEnabled = (this.m.var_213.mouseEnabled = (this.m.var_310.mouseEnabled = (this.m.var_546.mouseEnabled = false))));
        }

        private function method_191(_arg_1:Number)
        {
            var _local_14:Character;
            var _local_2:int = int(Math.ceil((Math.random() * 12)));
            var _local_3:int = int(Math.ceil((Math.random() * 39)));
            var _local_4:int = int(Math.ceil((Math.random() * 39)));
            var _local_5:int = int(Math.ceil((Math.random() * 39)));
            var _local_6:int = int(Math.round((Math.random() * 0xFFFFFF)));
            var _local_7:int = int(Math.round((Math.random() * 0xFFFFFF)));
            var _local_8:int = int(Math.round((Math.random() * 0xFFFFFF)));
            var _local_9:int = int(Math.round((Math.random() * 0xFFFFFF)));
            var _local_10:int = int(Math.round((Math.random() * 0xFFFFFF)));
            var _local_11:int = int(Math.round((Math.random() * 0xFFFFFF)));
            var _local_12:int = int(Math.round((Math.random() * 0xFFFFFF)));
            var _local_13:int = int(Math.round((Math.random() * 0xFFFFFF)));
            _local_14 = new Character(_local_2, _local_3, _local_4, _local_5);
            this.m.addChildAt(_local_14, 2);
            _local_14.method_133(_local_6, _local_7);
            _local_14.method_132(_local_8, _local_9);
            _local_14.method_134(_local_10, _local_11);
            _local_14.method_90(_local_12, _local_13);
            _local_14.scaleX = (_local_14.scaleY = 1);
            _local_14.x = _arg_1;
            _local_14.y = 85;
        }

        public function activate()
        {
            this.m.var_138.buttonMode = true;
            this.m.var_138.useHandCursor = true;
            this.m.var_138.addEventListener(MouseEvent.MOUSE_OVER, this.method_269);
            this.m.var_138.addEventListener(MouseEvent.MOUSE_OUT, this.method_378);
            this.m.var_138.addEventListener(MouseEvent.CLICK, this.clickHandler);
            alpha = 1;
        }

        public function deactivate()
        {
            this.m.var_138.buttonMode = false;
            this.m.var_138.useHandCursor = false;
            this.m.var_138.removeEventListener(MouseEvent.MOUSE_OVER, this.method_269);
            this.m.var_138.removeEventListener(MouseEvent.MOUSE_OUT, this.method_378);
            this.m.var_138.removeEventListener(MouseEvent.CLICK, this.clickHandler);
            alpha = 0.33;
        }

        public function method_653():Object
        {
            return (this.var_315);
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
            _local_3 = (('<u><font color="#4E4EFE"><a href="event:itemPurchase">' + _local_5) + "</a></font></u>");
            _local_2 = '<u><font color="#4E4EFE"><a href="event:itemInfo">more info</a></font></u>';
            if (_arg_1.available) {
                _local_4 = ((_local_3 + " / ") + _local_2);
            } else {
                _local_4 = _local_2;
            }
            return (_local_4);
        }

        private function method_237(_arg_1:TextEvent)
        {
            if (_arg_1.text == "itemPurchase") {
                dispatchEvent(new Event(class_257.EVENT_PURCHASE));
            }
            if (_arg_1.text == "itemInfo") {
                dispatchEvent(new Event(class_257.EVENT_INFO));
            }
        }

        private function clickHandler(_arg_1:MouseEvent)
        {
            dispatchEvent(new Event(class_257.EVENT_PURCHASE));
        }

        public function method_738():String
        {
            return (this.var_315.slug);
        }

        public function method_668():Boolean
        {
            return (this.var_315.available);
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
            this.m.var_283.removeEventListener(TextEvent.LINK, this.method_237);
            removeChild(this.m);
            this.m = null;
            this.var_315 = null;
            super.remove();
        }


    }
}//package package_17

