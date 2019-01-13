// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_23.PlayersTabUserGuildList = package_23.class_291

package package_23
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
        private var listingHeight:Number = 16; // var_388

        public function PlayersTabListHolder(_arg_1:DisplayObjectContainer)
        {
            this.holder = _arg_1;
            this.scrollBar.x = 175;
            this.scrollBar.y = 20;
            this.scrollBar.init(_arg_1, 330, 325);
            addChild(this.scrollBar);
            this.loadingGraphic.x = 85;
            this.loadingGraphic.y = 140;
            addChild(this.loadingGraphic);
        }

        /*public function method_833()
        {
            this.loadingGraphic.visible = true;
        }*/

        // hideLoadingGraphic = hideLoadingGraphic
        public function hideLoadingGraphic(e:* = null)
        {
            this.loadingGraphic.visible = false;
        }

        public function method_179(d:DisplayObject)
        {
            this.listings.push(d);
            d.y = this.holder.numChildren * this.listingHeight;
            this.holder.addChild(d);
        }

        public function clear()
        {
            var _local_1:class_7;
            for each (_local_1 in this.listings) {
                _local_1.remove();
            }
            this.listings = new Array();
        }

        public function sortOn(_arg_1:String, _arg_2:int=0)
        {
            this.listings.sortOn(_arg_1, _arg_2);
            this.method_545();
        }

        public function method_545()
        {
            var _local_1:int;
            var _local_3:class_7;
            var _local_2:int = this.listings.length;
            _local_1 = 0;
            while (_local_1 < _local_2) {
                _local_3 = this.listings[_local_1];
                _local_3.y = (_local_1 * this.listingHeight);
                _local_1++;
            }
        }

        override public function remove()
        {
            this.clear();
            super.remove();
        }


    }
}//package package_23

