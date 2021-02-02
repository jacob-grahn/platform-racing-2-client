// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_17.StorePopup = package_17.class_201

package package_17
{
    import com.jiggmin.data.EpicFlash;
    import com.jiggmin.data.Data;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.navigateToURL;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import package_4.Popup;
    import package_4.MessagePopup;
    import ui.CustomScrollBar;
    import package_4.ConfirmPopup;
    import flash.events.TextEvent;
    import package_4.UploadingPopup;
    import com.jiggmin.data.Encryptor;

    public class StorePopup extends Popup 
    {

        public static var userCoins:int = 0;

        private var m:StorePopupGraphic = new StorePopupGraphic();
        private var var_513:int = 3;
        private var var_640:int = 137;
        private var var_632:int = 160;
        private var listings:Vector.<StoreListing> = new Vector.<StoreListing>();
        private var scroll:CustomScrollBar;
        private var loading:LoadingGraphic; // var_289
        private var superLoader:SuperLoader; // var_123
        private var saleFlash:EpicFlash = new EpicFlash(); // var_207

        private var uploading:UploadingPopup;

        public function StorePopup()
        {
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.closePopup, false, 0, true);
            addChild(this.m);
            this.m.coinsLeftBox.visible = false;
            this.scroll = new CustomScrollBar();
            this.scroll.x = 202;
            this.scroll.y = -115;
            this.scroll.height = 225;
            addChild(this.scroll);
            this.scroll.init(this.m.itemsHolder, 225, 225);
            this.loading = new LoadingGraphic();
            addChild(this.loading);
            this.superLoader = new SuperLoader(true, SuperLoader.j);
            this.superLoader.addEventListener(SuperLoader.d, this.populateList);
            this.superLoader.addEventListener(SuperLoader.e, this.closePopup);
            this.superLoader.load(new URLRequest(Main.baseURL + "/vault/vault.php"));
        }

        // _loc2 (this.superLoader.parsedData)
        // _loc3 = listing
        private function populateList(e:Event)
        {
            removeChild(this.loading);
            this.m.coinsLeftBox.addEventListener(TextEvent.LINK, this.clickNeedMore, false, 0, true);
            var data:Object = this.superLoader.parsedData;
            var color:String = data.info.user.coins === 0 ? 'BB0000' : '006600';
            StorePopup.userCoins = data.info.user.coins;
            this.m.coinsLeftBox.htmlText = '<b><font color="#' + color + '">You have ' + Data.formatNumber(StorePopup.userCoins) + ' Coins remaining.</font> ' + Data.urlify('event:clickNeedMore', 'Need more?') + '</b>';
            this.m.coinsLeftBox.visible = true;
            if (this.superLoader.parsedData.info.hasOwnProperty('title')) {
                this.m.titleBox.text = "-- " + this.superLoader.parsedData.info.title.title + " --";
                if (this.superLoader.parsedData.info.title.flashing) {
                    this.saleFlash.addItem(this.m.titleBox);
                }
            }
            for each (var obj:Object in this.superLoader.parsedData.listings) {
                this.addListing(obj);
            }
            if (!this.saleFlash.isEmpty()) {
                this.saleFlash.start();
            }
        }

        // _loc2 = listing
        // method_179 = addListing
        private function addListing(obj:Object):StoreListing
        {
            var listing:StoreListing = new StoreListing(obj, this.saleFlash);
            if (listing.available) {
                listing.addEventListener(StoreListing.EVENT_PURCHASE, this.clickItem, false, 0, true);
                listing.addEventListener(StoreListing.EVENT_QUANTITY_PURCHASE, this.quantityClick, false, 0, true);
            }
            listing.addEventListener(StoreListing.EVENT_INFO, this.showFAQ, false, 0, true);
            listing.x = (this.listings.length % this.var_513) * this.var_640;
            listing.y = Math.floor(this.listings.length / this.var_513) * this.var_632;
            this.m.itemsHolder.addChild(listing);
            this.listings.push(listing);
            return listing;
        }

        private function quantityClick(e:Event)
        {
            this.clickItem(e, true);
        }

        private function clickNeedMore(e:TextEvent)
        {
            new ConfirmPopup(function () {
                sendToBuyCoinsPage();
            }, "You will be routed to pr2hub.com in order to complete this transaction.");
        }

        // _loc2 = slug
        // method_360 = clickItem
        private function clickItem(e:Event, fromQuantity:Boolean = false)
        {
            var gameUA:String = Data.urlify(Main.baseURL + '/terms_of_use.php', 'PR2 Terms of Use');
            if (Main.socket.connected) {
                var item:StoreListing = StoreListing(e.target);

                // super booster?
                if (item.slug == "stats_boost") {
                    this.useSuperBooster();
                    this.closePopup();
                    return;
                }

                // not enough coins?
                if (StorePopup.userCoins < item.currentPrice) {
                    new MessagePopup("Error: You don't have enough coins to purchase this item.");
                    return;
                }

                // do by quantity
                if (item.listing.max_quantity > 1) {
                    if (fromQuantity) {
                        trace('numSelected: ' + QuantityPopup.instance.numSelected);
                        new ConfirmPopup(function () {
                            purchaseItem(item.slug, QuantityPopup.instance.numSelected);
                        }, 'Are you sure you\'d like to purchase <b>' + QuantityPopup.instance.numSelected + '</b> of this lovely <b>' + item.title + '</b>? Your account will be debited <b>' + QuantityPopup.instance.totalCost + ' coins</b>.\n\nPlease see the ' + gameUA + ' for more information.');
                    } else {
                        new QuantityPopup(item);
                    }
                } else {
                    new ConfirmPopup(function () {
                        purchaseItem(item.slug, 1);
                    }, 'Are you sure you\'d like to purchase this lovely <b>' + item.title + '</b>? Your account will be debited <b>' + item.currentPrice + ' coins</b>.\n\nPlease see the ' + gameUA + ' for more information.');
                }
            } else {
                new MessagePopup('Error: You must be logged in to use the Vault of Magics.');
                this.closePopup();
            }
        }

        private function sendToBuyCoinsPage()
        {
            var send:Object = new Object();
            send.token = Main.token;
            send.time = Data.getTimestamp();
            send.rand = int(Math.random() * 10000000);
            var encryptor:Encryptor = new Encryptor();
            encryptor.setKey(Env.URL_PASS_KEY);
            encryptor.setIV(Env.URL_PASS_IV);
            var vars:URLVariables = new URLVariables();
            vars.data = encryptor.encrypt(JSON.stringify(send));
            var request:URLRequest = new URLRequest(Main.baseURL + "/vault/buy_coins.php");
            request.data = vars;
            request.method = URLRequestMethod.POST;
            navigateToURL(request, "_blank");
            this.closePopup();
        }

        // _loc2 = item
        // _loc3 = listing
        // method_396 = showFAQ
        private function showFAQ(e:Event)
        {
            var item:StoreListing = StoreListing(e.target);
            var listing:Object = item.listing;
            new MessagePopup("<b>--- " + listing.title + " FAQ ---</b> \n\n" + listing.faq);
        }

        // _loc1 = superLoader
        // _loc2 = vars
        // _loc3 = req
        // method_678 = useSuperBooster
        private function useSuperBooster()
        {
            var vars:URLVariables = new URLVariables();
            vars.server_id = Main.server.server_id;
            var req:URLRequest = new URLRequest(Main.baseURL + "/vault/use_super_booster.php");
            req.method = URLRequestMethod.POST;
            req.data = vars;
            var uploading:UploadingPopup = new UploadingPopup(req, SuperLoader.j);
            uploading.addEventListener(SuperLoader.d, this.onPurchaseComplete, false, 0, true);
        }

        private function purchaseItem(slug:String, quantity:int)
        {
            if (QuantityPopup.instance !== null) {
                QuantityPopup.instance.startFadeOut();
            }
            var vars:URLVariables = new URLVariables();
            vars.slug = slug;
            vars.quantity = quantity;
            var req:URLRequest = new URLRequest(Main.baseURL + '/vault/purchase_item.php');
            req.method = URLRequestMethod.POST;
            req.data = vars;
            var uploading:UploadingPopup = new UploadingPopup(req, SuperLoader.j);
            uploading.addEventListener(SuperLoader.d, this.onPurchaseComplete, false, 0, true);
            //this.uploading.addEventListener(SuperLoader.e, this.)
            //new MessagePopup('Placeholder!\n\nSlug: ' + slug + '\nQuantity: ' + quantity);
        }

        // method_785 = triggerKongPrompt
        /*private function triggerKongPrompt(slug:String)
        {
            var kongAPI:* = Main.instance.kongAPI;
            if (kongAPI == null) {
                new MessagePopup("PR2 requires you to log into Kongregate to use the store.");
				return;
            }
            if (kongAPI.services.isGuest()) {
                kongAPI.services.showRegistrationBox();
            } else {
                kongAPI.mtx.clickItemsRemote(Main.userId + "," + slug, this.onPurchaseComplete);
            }
        }*/

        // method_786 = onPurchaseComplete
        private function onPurchaseComplete(e:Event)
        {
            if (e.target.parsedData.success) {
                this.closePopup();
            }
        }

        /*
        private function method_665()
        {
            startFadeOut();
        }*/

        // method_377 = closePopup
        private function closePopup(e:Event = null)
        {
            startFadeOut();
        }

        // _loc1 = listing
        private function clear()
        {
            for each (var listing:StoreListing in this.listings) {
                listing.addEventListener(StoreListing.EVENT_QUANTITY_PURCHASE, this.quantityClick);
                listing.removeEventListener(StoreListing.EVENT_PURCHASE, this.clickItem);
                listing.removeEventListener(StoreListing.EVENT_INFO, this.showFAQ);
                listing.remove();
            }
        }

        override public function remove()
        {
            StorePopup.userCoins = 0;
            this.m.coinsLeftBox.removeEventListener(TextEvent.LINK, this.clickNeedMore);
            this.saleFlash.remove();
            this.saleFlash = null;
            this.superLoader.removeEventListener(SuperLoader.d, this.populateList);
            this.superLoader.remove();
            this.superLoader = null;
            removeChild(this.m);
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.closePopup);
            this.m = null;
            super.remove();
        }


    }
}//package package_17

