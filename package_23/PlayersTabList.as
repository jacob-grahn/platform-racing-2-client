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
            this.sortMode = "userName";
            this.sortPlayersBy();
        }

        // method_436 = clickRank
        private function clickRank(e:MouseEvent)
        {
            this.sortMode = "rank";
            this.sortPlayersBy();
        }

        // method_243 = clickHats
        private function clickHats(e:MouseEvent)
        {
            this.sortMode = "hats";
            this.sortPlayersBy();
        }

        protected function method_138(_arg_1:String, _arg_2:Number, _arg_3:Number, _arg_4:int, _arg_5:String="")
        {
            var listName:PlayersTabListItemInfo = new PlayersTabListItemInfo(_arg_1, _arg_2, _arg_3, _arg_4, _arg_5);
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
        private function sortPlayersBy()
        {
            if (this.sortMode == "userName") {
                super.sortOn(this.sortMode, (Array.CASEINSENSITIVE));
            } else {
                super.sortOn(this.sortMode, (Array.NUMERIC | Array.DESCENDING));
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

