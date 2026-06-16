// dialogs.GetLevelsPopup = dialogs.class_173

package dialogs
{
    import ui.SelectableButton;
    import ui.CustomScrollBar;
    import flash.events.MouseEvent;

    public class GetLevelsPopup extends Popup 
    {

        protected var m:GetLevelsPopupGraphic = new GetLevelsPopupGraphic();
        protected var itemSpacing:int = 25;
        protected var listings:Vector.<SelectableButton> = new Vector.<SelectableButton>();
        private var scroll:CustomScrollBar;
        private var selected:SelectableButton;

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
            this.m.levelsHolder.addEventListener(MouseEvent.CLICK, this.onListingClick, false, 0, true);
            this.m.levelsHolder.addEventListener(MouseEvent.DOUBLE_CLICK, this.onListingDoubleClick, false, 0, true);
            this.updateButtons();
        }

        public function getSelected():SelectableButton
        {
            return this.selected;
        }

        protected function hideLoadingGraphic()
        {
            this.m.removeChild(this.m.loadingGraphic);
        }

        protected function addListing(listing:SelectableButton)
        {
            listing.y = this.listings.length * this.itemSpacing;
            this.m.levelsHolder.addChild(listing);
            this.listings.push(listing);
        }

        protected function deselectAll()
        {
            var listing:SelectableButton;
            for each (listing in this.listings) {
                listing.setSelected(false);
            }
        }

        protected function clearListings()
        {
            var listing:SelectableButton;
            for each (listing in this.listings) {
                listing.remove();
            }
            this.listings = new Vector.<SelectableButton>();
        }

        protected function selectListing(listing:SelectableButton)
        {
            this.selected = listing;
            this.deselectAll();
            if (this.selected != null) {
                this.selected.setSelected(true);
                this.m.load_bt.enabled = this.m.delete_bt.enabled = true;
            } else {
                this.m.load_bt.enabled = this.m.delete_bt.enabled = false;
            }
            this.updateButtons();
        }

        protected function loadListing(listing:SelectableButton)
        {
        }

        protected function deleteListing(listing:SelectableButton)
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

        private function onListingClick(e:MouseEvent)
        {
            if (e.target is SelectableButton) {
                var listing:SelectableButton = SelectableButton(e.target);
                this.selectListing(listing);
            }
        }

        private function onListingDoubleClick(e:MouseEvent)
        {
            if (e.target is SelectableButton) {
                var listing:SelectableButton = SelectableButton(e.target);
                this.loadListing(listing);
            }
        }

        private function updateButtons()
        {
            this.m.load_bt.enabled = this.m.delete_bt.enabled = (this.selected != null);
        }

        override public function remove()
        {
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.load_bt.removeEventListener(MouseEvent.CLICK, this.clickLoad);
            this.m.delete_bt.removeEventListener(MouseEvent.CLICK, this.clickDelete);
            this.m.levelsHolder.removeEventListener(MouseEvent.CLICK, this.onListingClick);
            this.m.levelsHolder.removeEventListener(MouseEvent.DOUBLE_CLICK, this.onListingDoubleClick);
            this.clearListings();
            this.scroll.remove();
            this.scroll = null;
            removeChild(this.m);
            this.m = null;
            this.selected = null;
            super.remove();
        }


    }
}
