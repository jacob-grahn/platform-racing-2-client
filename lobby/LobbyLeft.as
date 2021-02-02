// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// lobby.LobbyLeft = lobby.class_206

package lobby
{
    import ui.LobbyTab;
    import com.jiggmin.data.UnreadNotif;
    import package_21.ChatInstance;
    import package_21.Messages;
    import package_23.PlayersTab;
    import package_18.AccountInfo;

    public class LobbyLeft extends class_196 
    {

        public function LobbyLeft()
        {
            x = y = 3;
            var chatTab:LobbyTab = new LobbyTab(this.changeTabChat, "Chat"); // method_472 = changeTabChat
            var pmsTab:LobbyTab = new LobbyTab(this.changeTabPMs, "PMs"); // method_538 = changeTabPMs
            var playersTab:LobbyTab = new LobbyTab(this.changeTabPlayers, "Players"); // method_805 = changeTabPlayers
            var accountTab:LobbyTab = new LobbyTab(this.changeTabAccount, "Account"); // method_510 = changeTabAccount
            var tabArray:Array;
            var lastArrKey:int;
            if (Main.group > 0) {
                tabArray = new Array(chatTab, pmsTab, playersTab, accountTab);
                lastArrKey = 3;
            } else {
                tabArray = new Array(chatTab, playersTab, accountTab);
                lastArrKey = 2;
            }
            super(tabArray, 194, 394, lastArrKey, "lobbyLeft");
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

