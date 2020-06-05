// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// lobby.LobbyRight = lobby.class_197

package lobby
{
    import ui.LobbyTab;
    import package_22.Campaign;
    import package_22.Best;
    import package_22.BestToday;
    import package_22.Newest;
    import package_22.Search;
    import package_22.Favorites;
    //import package_22.class_251;

    public class LobbyRight extends class_196 
    {

        public static var lobbyRight:LobbyRight;

        private var campaignTab:LobbyTab = new LobbyTab(this.clickCampaign, "Campaign"); 
        private var atbTab:LobbyTab = new LobbyTab(this.clickBest, "All Time Best");
        private var tbTab:LobbyTab = new LobbyTab(this.clickBestToday, "Today's Best");
        private var newTab:LobbyTab = new LobbyTab(this.clickNew, "Newest");
        private var searchTab:LobbyTab = new LobbyTab(this.clickSearch, "Search");
        private var favsTab:LobbyTab = new LobbyTab(this.clickFavs, "♥");
        //private var guildsTab:LobbyTab = new LobbyTab(this.clickGuilds, "Guilds");

        public function LobbyRight()
        {
            LobbyRight.lobbyRight = this;
            x = 200;
            y = 3;
            var tabsArray:Array = [this.campaignTab, this.atbTab, this.tbTab, this.newTab, this.searchTab];
            if (Main.group >= 1) {
                tabsArray.push(this.favsTab);
            }
            super(tabsArray, 347, 356, 0, "lobbyRight");
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

        // method_537 = clickBestToday
        private function clickBestToday()
        {
            changePage(new BestToday());
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
            changePage(new class_251());
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
            this.campaignTab = this.atbTab = this.tbTab = this.newTab = this.searchTab = this.favsTab = /*this.guildsTab =*/ null;
            super.remove();
        }


    }
}
