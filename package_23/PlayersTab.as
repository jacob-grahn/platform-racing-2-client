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
            if (Main.group > 0) {
                this.var_258 = new class_246([online, friends, following, ignored/*, guilds*/], 0, 186, "playerLists");
            } else {
                this.var_258 = new class_246([online, guilds], 0, 186, "playerLists");
            }
            addChild(this.var_258);
            this.pageHolder.y = 20;
            addChild(this.pageHolder);
        }

        // method_752 = clickOnline
        private function clickOnline()
        {
            this.pageHolder.changePage(new Online());
        }

        // method_666 = clickFriends
        private function clickFriends()
        {
            this.pageHolder.changePage(new Friends());
        }

        private function clickFollowing()
        {
            this.pageHolder.changePage(new Following());
        }

        // method_541 = clickIgnored
        private function clickIgnored()
        {
            this.pageHolder.changePage(new Ignored());
        }

        // method_484 = clickGuilds
        private function clickGuilds()
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

