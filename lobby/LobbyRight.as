// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// lobby.LobbyRight = lobby.class_197

package lobby
{
    import ui.LobbyTab;
    import level_browser.Campaign;
    import level_browser.Best;
    import level_browser.BestWeek;
    import level_browser.Newest;
    import level_browser.Search;
    import level_browser.Favorites;
    //import level_browser.ListingPage;

    public class LobbyRight extends LobbySide 
    {

        public static var lobbyRight:LobbyRight;

        private var campaignTab:LobbyTab = new LobbyTab(this.clickCampaign, "Campaign"); 
        private var atbTab:LobbyTab = new LobbyTab(this.clickBest, "All Time Best");
        private var wbTab:LobbyTab = new LobbyTab(this.clickBestWeek, "Week's Best");
        private var newTab:LobbyTab = new LobbyTab(this.clickNew, "Newest");
        private var searchTab:LobbyTab = new LobbyTab(this.clickSearch, "Search");
        private var favsTab:LobbyTab = new LobbyTab(this.clickFavs, "♥");
        //private var guildsTab:LobbyTab = new LobbyTab(this.clickGuilds, "Guilds");

        public function LobbyRight()
        {
            LobbyRight.lobbyRight = this;
            x = 200;
            y = 3;
            var tabsArray:Array = [this.campaignTab, this.atbTab, this.wbTab, this.newTab, this.searchTab];
            if (Main.group >= 1) {
                tabsArray.push(this.favsTab);
            }
            super(tabsArray, "lobbyRight", 0, 347, 356);
        }

        // method_631 = clickCampaign
        private function clickCampaign()
        {
            changePage(new Campaign());
        }

         // method_555 = clickBest
        private function clickBest()
        {
            changePage(new Best());
        }

        // method_537 = clickBestWeek
        private function clickBestWeek()
        {
            changePage(new BestWeek());
        }

        // method_616 = clickNew
        private function clickNew()
        {
            changePage(new Newest());
        }

        private function clickSearch()
        {
            changePage(new Search());
        }

        private function clickFavs()
        {
            changePage(new Favorites());
        }

        /*
        // method_484 = clickGuilds
        private function clickGuilds()
        {
            changePage(new ListingPage());
        }
        */

        public function lookupUser(userName:String = "")
        {
            this.searchTab.select();
            changePage(new Search(userName));
        }

        public function lookupLevel(levelID:String = "")
        {
            this.searchTab.select();
            changePage(new Search(levelID, 'id'));
        }

        override public function remove()
        {
            LobbyRight.lobbyRight = null;
            this.campaignTab = this.atbTab = this.wbTab = this.newTab = this.searchTab = this.favsTab = /*this.guildsTab =*/ null;
            super.remove();
        }


    }
}
