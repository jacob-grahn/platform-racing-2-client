package player_profile.PartInfo
{
    import com.jiggmin.data.Data;
    import com.jiggmin.data.EpicFlash;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;
    import flash.net.URLVariables;
    import dialogs.MessagePopup;
    import dialogs.Popup;
    import ui.CustomScrollBar;

    public class PartInfoPopup extends Popup 
    {
        public static var instance:PartInfoPopup;

        private var m:StorePopupGraphic = new StorePopupGraphic();
        private var mode:String;
        private var ownedParts:Array;
        private var ownedEpics:Array;
        private var hasEE:Boolean = false;
        private var allParts:Array;
        private var itemsPerRow:int = 3;
        private var itemColWidth:int = 137;
        private var itemRowHeight:int = 160;
        private var listings:Vector.<PartInfoListing> = new Vector.<PartInfoListing>();
        private var scroll:CustomScrollBar;
        private var loadingGraphic:LoadingGraphic;
        public var epicFlash:EpicFlash = new EpicFlash();

        public function PartInfoPopup(type:String, parts:Array, epics:Array)
        {
            if (PartInfoPopup.instance != null) {
                PartInfoPopup.instance.startFadeOut();
            }
            PartInfoPopup.instance = this;
            this.mode = type;
            this.ownedParts = parts;
            this.ownedEpics = epics;
            if (this.ownedEpics.indexOf('*') != -1) {
                this.hasEE = true;
            }
            this.m.titleBox.text = "-- " + Data.ucfirst(Parts.getPlural(this.mode)) + " --";
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.onClose, false, 0, true);
            this.m.coinsLeftBg.visible = this.m.coinsLeftBox.visible = false;
            this.m.y += 20;
            addChild(this.m);
            this.scroll = new CustomScrollBar();
            this.scroll.x = 202;
            this.scroll.y = -115;
            this.scroll.height = 225;
            addChild(this.scroll);
            this.scroll.init(this.m.itemsHolder, 225, 225);
            this.allParts = Parts.getPartArray(this.mode);
            if (this.allParts == false) {
                new MessagePopup('Error: Invalid part mode specified.');
                this.remove();
            }
            this.populateParts();
        }

        private function populateParts()
        {
            for each (var part:Object in this.allParts) {
                this.createListing(part);
            }
            if (this.epicFlash.isEmpty() === false) {
                this.epicFlash.start();
            }
        }

        private function createListing(part:Object) : PartInfoListing
        {
            // check if part is in array, if epic is in epic array or for ee. add as part.has and part.hasEpic
            part.has = false;
            if (this.ownedParts.indexOf(part.id.toString()) != -1) {
                part.has = true;
            }
            part.hasEpic = false;
            if (this.ownedEpics.indexOf(part.id.toString()) != -1) {
                part.hasEpic = true;
            }
            var listing:PartInfoListing = new PartInfoListing(part, this.hasEE);
            //listing.addEventListener(MouseEvent.CLICK, this.onClick);
            listing.x = (this.listings.length % this.itemsPerRow) * this.itemColWidth;
            listing.y = Math.floor(this.listings.length / this.itemsPerRow) * this.itemRowHeight;
            if (part.hasEpic == true) {
                listing.addEpicFlash(this.epicFlash);
            }
            this.m.itemsHolder.addChild(listing);
            this.listings.push(listing);
            return listing;
        }

        // _loc2 = listing
        // _loc3 = part
        /*private function onClick(e:MouseEvent)
        {
            var listing:PartInfoListing = PartInfoListing(e.target);
            var part:Object = listing.getListing();
            new MessagePopup("--- " + part.name + " FAQ --- \n\n" + part.desc);
        }*/

        private function onClose(e:MouseEvent)
        {
            startFadeOut();
        }

        private function clear()
        {
            for each (var listing:PartInfoListing in this.listings) {
                listing.remove();
            }
        }

        override public function remove()
        {
            if (PartInfoPopup.instance === this) {
                PartInfoPopup.instance = null;
            }
            removeChild(this.m);
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.onClose);
            this.m = null;
            super.remove();
        }


    }
}
