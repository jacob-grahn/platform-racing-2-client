// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_23.PlayersTabList = package_23.class_292

package package_23
{
    import flash.events.MouseEvent;
    import flash.utils.setInterval;
    import flash.utils.clearInterval;

    public class PlayersTabList extends PlayersTabListHolder 
    {

        private var m:PlayersTabListGraphic = new PlayersTabListGraphic();
        private var sortInterval:uint; // var_570
        private var sortMode:String = "rank"; // var_229
        private var sortOrder:String = 'desc';
        private var updateSort:Boolean = false; // var_412

        public function PlayersTabList()
        {
            addChild(this.m);
            super(this.m.listHolder);
            this.m.name_bt.addEventListener(MouseEvent.CLICK, this.clickName, false, 0, true);
            this.m.rank_bt.addEventListener(MouseEvent.CLICK, this.clickRank, false, 0, true);
            this.m.hats_bt.addEventListener(MouseEvent.CLICK, this.clickHats, false, 0, true);
            this.sortInterval = setInterval(this.sortListener, 500);
        }

        // method_276 = clickName
        private function clickName(e:MouseEvent)
        {
            this.sortPlayersBy('userName');
        }

        // method_436 = clickRank
        private function clickRank(e:MouseEvent)
        {
            this.sortPlayersBy('rank');
        }

        // method_243 = clickHats
        private function clickHats(e:MouseEvent)
        {
            this.sortPlayersBy('hats');
        }

        protected function method_138(name:String, group:String, rank:Number, hats:int, status:String="")
        {
            var listName:PlayersTabListItemInfo = new PlayersTabListItemInfo(name, group, rank, hats, status);
            super.method_179(listName);
            this.updateSort = true;
        }

        // method_486 = sortListener
        private function sortListener()
        {
            if (this.updateSort) {
                this.updateSort = false;
                this.sortPlayersBy();
            }
        }

        // method_110 = sortPlayersBy
        private function sortPlayersBy(newSort:String = null)
        {
            var sort1:String, sort2:String;
            if (newSort != this.sortMode || newSort == null) {
                this.sortMode = newSort != null ? newSort : this.sortMode;
                if (this.sortMode == "userName") {
                    this.sortOrder = 'asc';
                    super.sortOn(this.sortMode, Array.CASEINSENSITIVE);
                } else {
                    this.sortOrder = 'desc';
                    sort1 = this.sortMode;
                    sort2 = this.sortMode == 'rank' ? 'hats' : 'rank';
                    super.sortOn([sort1, sort2, 'userName'], Array.NUMERIC | Array.DESCENDING);
                }
            } else if (newSort == this.sortMode) {
                // toggle sort order
                this.sortOrder = this.sortOrder == 'desc' ? 'asc' : 'desc';

                // determine the option that corresponds to the mode
                var modeOpt:uint = this.sortMode == 'userName' ? Array.CASEINSENSITIVE : Array.NUMERIC;

                // determine the ordering to use
                var sortOpts = this.sortOrder == 'desc' ? modeOpt | Array.DESCENDING : modeOpt;

                // do the sort
                if (this.sortMode == 'userName') {
                    super.sortOn(this.sortMode, sortOpts);
                } else {
                    sort1 = this.sortMode;
                    sort2 = this.sortMode == 'rank' ? 'hats' : 'rank';
                    super.sortOn([sort1, sort2, 'userName'], [sortOpts, sortOpts, Array.CASEINSENSITIVE]);
                } // There's a problem here. Alpha is always broken. Find something to fix this.
            }
        }

        override public function remove()
        {
            clearInterval(this.sortInterval);
            this.m.name_bt.removeEventListener(MouseEvent.CLICK, this.clickName);
            this.m.rank_bt.removeEventListener(MouseEvent.CLICK, this.clickRank);
            this.m.hats_bt.removeEventListener(MouseEvent.CLICK, this.clickHats);
            super.remove();
        }


    }
}//package package_23

