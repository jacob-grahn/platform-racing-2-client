// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_17.StorePopup = package_17.class_201

package package_17
{
    import package_4.Popup;
    import ui.CustomScrollBar;
    import data.class_153;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;
    import flash.events.Event;
    import package_4.MessagePopup;
    import flash.net.URLVariables;

    public class StorePopup extends Popup 
    {

        private var m:StorePopupGraphic = new StorePopupGraphic();
        private var var_513:int = 3;
        private var var_640:int = 137;
        private var var_632:int = 160;
        private var listings:Vector.<StoreListing> = new Vector.<StoreListing>();
        private var scroll:CustomScrollBar;
        private var var_289:LoadingGraphic;
        private var superLoader:SuperLoader; // var_123
        private var var_207:class_153 = new class_153();

        public function StorePopup()
        {
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.method_377, false, 0, true);
            addChild(this.m);
            this.scroll = new CustomScrollBar();
            this.scroll.x = 202;
            this.scroll.y = -115;
            this.scroll.height = 225;
            addChild(this.scroll);
            this.scroll.init(this.m.itemsHolder, 225, 225);
            this.var_289 = new LoadingGraphic();
            addChild(this.var_289);
            this.superLoader = new SuperLoader(true, SuperLoader.j);
            this.superLoader.addEventListener(SuperLoader.d, this.method_228);
            this.superLoader.load(new URLRequest(Main.baseURL + "/vault/vault.php"));
        }

        private function method_228(_arg_1:Event)
        {
            var _local_3:Object;
            removeChild(this.var_289);
            this.m.titleBox.text = "-- " + this.superLoader.parsedData.title + " --";
            if (this.superLoader.parsedData.sale) {
                this.var_207.addItem(this.m.titleBox);
                this.var_207.start();
            }
            var _local_2:Array = this.superLoader.parsedData.listings;
            for each (_local_3 in _local_2) {
                this.method_179(_local_3);
            }
        }

        private function method_179(_arg_1:Object):StoreListing
        {
            var _local_2:StoreListing = new StoreListing(_arg_1);
            if (_local_2.method_668()) {
                _local_2.addEventListener(StoreListing.EVENT_PURCHASE, this.method_360);
            }
            _local_2.addEventListener(StoreListing.EVENT_INFO, this.method_396);
            _local_2.x = (this.listings.length % this.var_513) * this.var_640;
            _local_2.y = Math.floor(this.listings.length / this.var_513) * this.var_632;
            this.m.itemsHolder.addChild(_local_2);
            this.listings.push(_local_2);
            return (_local_2);
        }

        private function method_360(_arg_1:Event)
        {
            var _local_2:String = StoreListing(_arg_1.target).method_738();
            if (_local_2 == "stats-boost") {
                this.method_678();
                this.remove();
            } else {
                this.method_785(_local_2);
            }
        }

        private function method_396(_arg_1:Event)
        {
            var _local_2:StoreListing = StoreListing(_arg_1.target);
            var _local_3:Object = _local_2.method_653();
            new MessagePopup("--- " + _local_3.title + " FAQ --- \n\n" + _local_3.longDescription);
        }

        private function method_678()
        {
            var _local_1:SuperLoader = new SuperLoader(true, SuperLoader.j);
            var _local_2:URLVariables = new URLVariables();
            _local_2.server_id = Main.server.server_id;
            var _local_3:URLRequest = new URLRequest((Main.baseURL + "/vault/vault_super_booster.php"));
            _local_3.data = _local_2;
            _local_1.load(_local_3);
        }

        private function method_785(_arg_1:String)
        {
            var kongAPI:* = Main.instance.kongAPI;
            if (kongAPI == null) {
                new MessagePopup("PR2 requires you to log into Kongregate to use the store.");
				return;
            }
            if (kongAPI.services.isGuest()) {
                kongAPI.services.showRegistrationBox();
            } else {
                kongAPI.mtx.purchaseItemsRemote(Main.userId + "," + _arg_1, this.method_786);
            }
        }

        private function method_786(_arg_1:Object)
        {
            if (_arg_1.success) {
                this.method_665();
            }
        }

        private function method_665()
        {
            startFadeOut();
        }

        private function method_377(_arg_1:MouseEvent)
        {
            startFadeOut();
        }

        private function clear()
        {
            var _local_1:StoreListing;
            for each (_local_1 in this.listings) {
                _local_1.removeEventListener(StoreListing.EVENT_PURCHASE, this.method_360);
                _local_1.removeEventListener(StoreListing.EVENT_INFO, this.method_396);
                _local_1.remove();
            }
        }

        override public function remove()
        {
            this.var_207.remove();
            this.var_207 = null;
            this.superLoader.removeEventListener(SuperLoader.d, this.method_228);
            this.superLoader.remove();
            this.superLoader = null;
            removeChild(this.m);
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.method_377);
            this.m = null;
            super.remove();
        }


    }
}//package package_17

