// Decompiled by AS3 Sorcerer 5.98


package social
{
    import page.Page;
    import ui.TabsHolder;
    import page.PageHolder;
    import ui.LobbyTab;

    public class PlayersTab extends Page 
    {

        private var tabsHolder:TabsHolder; // var_258
        private var pageHolder:PageHolder = new PageHolder();

        // _loc1 = online
        // _loc2 = friends
        // _loc3 = ignored
        // _loc4 = guilds
        // _loc5 = tabs (deleted)
        public function PlayersTab()
        {
            super();
            var online:LobbyTab = new LobbyTab(this.clickOnline, "Online");
            var friends:LobbyTab = new LobbyTab(this.clickFriends, "Friends");
            var following:LobbyTab = new LobbyTab(this.clickFollowing, "Following");
            var ignored:LobbyTab = new LobbyTab(this.clickIgnored, "Ignored");
            var guilds:LobbyTab = new LobbyTab(this.clickGuilds, "Guilds");
            var tabs:Array = Main.group > 0 ? [online, friends, following, ignored/*, guilds*/] : [online, guilds];
            this.tabsHolder = new TabsHolder(tabs, "playerLists", 0, 186);
            addChild(this.tabsHolder);
            this.pageHolder.y = 20;
            addChild(this.pageHolder);
        }

        private function clickOnline()
        {
            this.pageHolder.changePage(new Online());
        }

        private function clickFriends()
        {
            this.pageHolder.changePage(new Friends());
        }

        private function clickFollowing()
        {
            this.pageHolder.changePage(new Following());
        }

        private function clickIgnored()
        {
            this.pageHolder.changePage(new Ignored());
        }

        private function clickGuilds()
        {
            this.pageHolder.changePage(new Guilds());
        }

        override public function remove()
        {
            this.tabsHolder.remove();
            this.pageHolder.remove();
            super.remove();
        }


    }
}

