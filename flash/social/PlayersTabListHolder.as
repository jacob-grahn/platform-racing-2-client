package social
{
    import page.Page;
    import flash.display.DisplayObjectContainer;
    import ui.CustomScrollBar;
    import flash.display.DisplayObject;

    public class PlayersTabListHolder extends Page 
    {

        private var holder:DisplayObjectContainer;
        private var scrollBar:CustomScrollBar = new CustomScrollBar();
        private var loadingGraphic:LoadingGraphic = new LoadingGraphic();
        private var listings:Array = new Array();
        private var listingHeight:Number = 16;
        
        // for numSort
        private var sortKeys:Array = new Array();
        private var sortOrder:String = 'desc';

        public function PlayersTabListHolder(d:DisplayObjectContainer)
        {
            this.holder = d;
            this.scrollBar.x = 175;
            this.scrollBar.y = 20;
            this.scrollBar.init(this.holder, 330, 325);
            addChild(this.scrollBar);
            this.loadingGraphic.x = 85;
            this.loadingGraphic.y = 140;
            addChild(this.loadingGraphic);
        }

        public function hideLoadingGraphic(e:* = null)
        {
            this.loadingGraphic.visible = false;
        }

        public function addListing(d:DisplayObject)
        {
            this.listings.push(d);
            d.y = this.holder.numChildren * this.listingHeight;
            this.holder.addChild(d);
        }

        public function clear()
        {
            for each (var listing:Removable in this.listings) {
                listing.remove();
            }
            this.listings = new Array();
        }

        public function sortOn(key:*, options:*=0)
        {
            this.listings.sortOn(key, options);
            this.populate();
        }

        public function numSort(keys:Array, direction:String = 'desc')
        {
            this.sortKeys = keys;
            this.sortOrder = direction;
            this.listings.sort(this.doNumSort);
            this.populate();
        }

        private function doNumSort(a:Removable, b:Removable)
        {
            var key1:String = this.sortKeys[0];
            var key2:String = this.sortKeys[1];
            var name:String = 'userName' in a ? 'userName' : 'guildName';

            if (this.sortOrder == 'desc') {
                if (a[key1] !== b[key1]) {
                    if (a[key1] > b[key1]) {
                        return -1;
                    } else if (a[key1] < b[key1]) {
                        return 1;
                    }
                } else if (a[key2] !== b[key2]) {
                    if (a[key2] > b[key2]) {
                        return -1;
                    } else if (a[key2] < b[key2]) {
                        return 1;
                    }
                } else {
                    return a[name].toLowerCase().localeCompare(b[name].toLowerCase());
                }
            } else if (this.sortOrder == 'asc') {
                if (a[key1] !== b[key1]) {
                    if (a[key1] > b[key1]) {
                        return 1;
                    } else if (a[key1] < b[key1]) {
                        return -1;
                    }
                } else if (a[key2] !== b[key2]) {
                    if (a[key2] > b[key2]) {
                        return 1;
                    } else if (a[key2] < b[key2]) {
                        return -1;
                    }
                } else {
                    return b[name].toLowerCase().localeCompare(a[name].toLowerCase());
                }
            }
            
        }

        // changed public -> private
        private function populate()
        {
            var i:int = 0;
            while (i < this.listings.length) {
                var listing:Removable = this.listings[i];
                listing.y = (i * this.listingHeight);
                i++;
            }
        }

        override public function remove()
        {
            this.clear();
            super.remove();
        }


    }
}

