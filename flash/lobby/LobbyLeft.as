// lobby.LobbyLeft = lobby.class_206

package lobby
{
    import ui.LobbyTab;
    import com.jiggmin.data.UnreadNotif;
    import chat.ChatInstance;
    import chat.Messages;
    import social.PlayersTab;
    import player_profile.AccountInfo;

    public class LobbyLeft extends LobbySide 
    {

        public function LobbyLeft()
        {
            x = y = 3;
            var chatTab:LobbyTab = new LobbyTab(this.changeTabChat, "Chat");
            var pmsTab:LobbyTab = new LobbyTab(this.changeTabPMs, "PMs");
            var playersTab:LobbyTab = new LobbyTab(this.changeTabPlayers, "Players");
            var accountTab:LobbyTab = new LobbyTab(this.changeTabAccount, "Account");
            var tabArray:Array;
            var lastArrKey:int;
            if (Main.group > 0) {
                tabArray = new Array(chatTab, pmsTab, playersTab, accountTab);
                lastArrKey = 3;
            } else {
                tabArray = new Array(chatTab, playersTab, accountTab);
                lastArrKey = 2;
            }
            super(tabArray, "lobbyLeft", lastArrKey, 194, 394);
            UnreadNotif.addNotifContainer(pmsTab);
        }

        private function changeTabChat()
        {
            changePage(new ChatInstance());
        }

        private function changeTabPMs()
        {
            changePage(new Messages());
        }

        private function changeTabPlayers()
        {
            changePage(new PlayersTab());
        }

        private function changeTabAccount()
        {
            changePage(new AccountInfo());
        }

        override public function remove()
        {
            super.remove();
        }


    }
}//package lobby

