// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_4.GetLevelsPopup = package_4.class_173

package package_4
{
    import ui.class_229;
    import ui.CustomScrollBar;
    import flash.events.MouseEvent;

    public class GetLevelsPopup extends Popup 
    {

        protected var m:GetLevelsPopupGraphic = new GetLevelsPopupGraphic();
        protected var var_454:int = 25;
        protected var listings:Vector.<class_229> = new Vector.<class_229>();
        private var scroll:CustomScrollBar;
        private var selected:class_229;

        public function GetLevelsPopup()
        {
            addChild(this.m);
            this.scroll = new CustomScrollBar();
            this.scroll.width = 16;
            this.scroll.height = 160;
            this.scroll.x = 119;
            this.scroll.y = -86;
            this.scroll.init(this.m.levelsHolder, 160, 158);
            this.m.addChild(this.scroll);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.load_bt.addEventListener(MouseEvent.CLICK, this.clickLoad);
            this.m.delete_bt.addEventListener(MouseEvent.CLICK, this.clickDelete);
            this.m.levelsHolder.addEventListener(MouseEvent.CLICK, this.method_401, false, 0, true);
            this.m.levelsHolder.addEventListener(MouseEvent.DOUBLE_CLICK, this.method_222, false, 0, true);
            this.method_394();
        }

         // method_321 = getSelected
        public function getSelected():class_229
        {
            return this.selected;
        }

        // method_57 = hideLoadingGraphic
        protected function hideLoadingGraphic()
        {
            this.m.removeChild(this.m.loadingGraphic);
        }

        protected function method_455(listing:class_229)
        {
            listing.y = this.listings.length * this.var_454;
            this.m.levelsHolder.addChild(listing);
            this.listings.push(listing);
        }

        // _loc1 = listing
        protected function method_539()
        {
            var listing:class_229;
            for each (listing in this.listings) {
                listing.method_368(false);
            }
        }

        // _loc1 = listing
        protected function method_825()
        {
            var listing:class_229;
            for each (listing in this.listings) {
                listing.remove();
            }
            this.listings = new Vector.<class_229>();
        }

        protected function method_491(listing:class_229)
        {
            this.selected = listing;
            this.method_539();
            if (this.selected != null) {
                this.selected.method_368(true);
                this.m.load_bt.enabled = this.m.delete_bt.enabled = true;
            } else {
                this.m.load_bt.enabled = this.m.delete_bt.enabled = false;
            }
            this.method_394();
        }

        protected function loadListing(_arg_1:class_229)
        {
        }

        protected function deleteListing(_arg_1:class_229)
        {
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        private function clickLoad(e:MouseEvent)
        {
            if (this.selected != null) {
                this.loadListing(this.selected);
            }
        }

        private function clickDelete(e:MouseEvent)
        {
            if (this.selected != null) {
                this.deleteListing(this.selected);
            }
        }

        // _loc2 = listing
        private function method_401(e:MouseEvent)
        {
            if (e.target is class_229) {
                var listing:class_229 = class_229(e.target);
                this.method_491(listing);
            }
        }

        // _loc2 = listing
        private function method_222(e:MouseEvent)
        {
            if (e.target is class_229) {
                var listing:class_229 = class_229(e.target);
                this.loadListing(listing);
            }
        }

        private function method_394()
        {
            this.m.load_bt.enabled = this.m.delete_bt.enabled = (this.selected != null);
        }

        override public function remove()
        {
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.load_bt.removeEventListener(MouseEvent.CLICK, this.clickLoad);
            this.m.delete_bt.removeEventListener(MouseEvent.CLICK, this.clickDelete);
            this.m.levelsHolder.removeEventListener(MouseEvent.CLICK, this.method_401);
            this.m.levelsHolder.removeEventListener(MouseEvent.DOUBLE_CLICK, this.method_222);
            this.method_825();
            this.scroll.remove();
            this.scroll = null;
            removeChild(this.m);
            this.m = null;
            this.selected = null;
            super.remove();
        }


    }
}
