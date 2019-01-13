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
    import package_22.class_251;

    public class LobbyRight extends class_196 
    {

        public static var lobbyRight:LobbyRight;

        private var campaignTab:LobbyTab = new LobbyTab(clickCampaign, "Campaign"); // clickCampaign = method_631
        private var atbTab:LobbyTab = new LobbyTab(clickAtb, "All Time Best"); // clickAtb = method_555
        private var tbTab:LobbyTab = new LobbyTab(clickTb, "Today's Best"); // clickTb = method_537
        private var newTab:LobbyTab = new LobbyTab(clickNew, "Newest"); // clickNew = method_616
        private var searchTab:LobbyTab = new LobbyTab(clickSearch, "Search");
        private var guildsTab:LobbyTab = new LobbyTab(clickGuilds, "Guilds"); // clickGuilds = method_484

        public function LobbyRight()
        {
            LobbyRight.lobbyRight = this;
            x = 200;
            y = 3;
            var tabsArray:Array = new Array(this.campaignTab, this.atbTab, this.tbTab, this.newTab, this.searchTab);
            super(tabsArray, 347, 356, 0, "lobbyRight");
        }

        private function clickCampaign()
        {
            changePage(new Campaign());
        }

        private function clickAtb()
        {
            changePage(new Best());
        }

        private function clickTb()
        {
            changePage(new BestToday());
        }

        private function clickNew()
        {
            changePage(new Newest());
        }

        private function clickSearch()
        {
            changePage(new Search());
        }

        private function clickGuilds()
        {
            changePage(new class_251());
        }

        public function lookupUser(userName:String = "")
        {
            this.searchTab.select();
            changePage(new Search(userName));
        }

        override public function remove()
        {
            LobbyRight.lobbyRight = null;
            this.campaignTab = this.atbTab = this.tbTab = this.newTab = this.searchTab = this.guildsTab = null;
            super.remove();
        }


    }
}
