// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_23.PlayersTab = package_23.class_261

package package_23
{
    import page.Page;
    import ui.class_246;
    import page.PageHolder;
    import ui.LobbyTab;

    public class PlayersTab extends Page 
    {

        private var var_258:class_246;
        private var pageHolder:PageHolder = new PageHolder();

        public function PlayersTab()
        {
            var _local_5:Array;
            super();
            var _local_1:LobbyTab = new LobbyTab(this.method_752, "Online");
            var _local_2:LobbyTab = new LobbyTab(this.method_666, "Friends");
            var _local_3:LobbyTab = new LobbyTab(this.method_541, "Ignored");
            var _local_4:LobbyTab = new LobbyTab(this.method_484, "Guilds");
            if (Main.group > 0) {
                _local_5 = new Array(_local_1, _local_2, _local_3, _local_4);
                this.var_258 = new class_246(_local_5, 0, 186, "playerLists");
            } else {
                _local_5 = new Array(_local_1);
                this.var_258 = new class_246(_local_5, 0, 186, "playerLists");
            }
            addChild(this.var_258);
            this.pageHolder.y = 20;
            addChild(this.pageHolder);
        }

        private function method_752()
        {
            this.pageHolder.changePage(new Online());
        }

        private function method_666()
        {
            this.pageHolder.changePage(new Friends());
        }

        private function method_541()
        {
            this.pageHolder.changePage(new Ignored());
        }

        private function method_484()
        {
            this.pageHolder.changePage(new Guilds());
        }

        override public function remove()
        {
            this.var_258.remove();
            this.pageHolder.remove();
            super.remove();
        }


    }
}//package package_23

