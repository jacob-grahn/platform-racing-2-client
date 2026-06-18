package pr2.lobby;

import pr2.lobby.tabs.AccountTab;
import pr2.lobby.tabs.ChatTab;
import pr2.lobby.tabs.MessagesTab;
import pr2.lobby.tabs.PlayersTab;
import pr2.ui.LobbyTab;

/**
	Port of Flash `lobby.LobbyLeft`: the left pane (`194 x 394` at `(3, 3)`).

	Members see Chat / PMs / Players / Account with Account selected by default;
	guests drop the PMs tab and default to Account (the last index). The pane size
	and holder id (`lobbyLeft`) match the original so tab memory and overlap behave
	identically.
**/
class LobbyLeft extends LobbySide {
	/** Tab labels for the pane given an access group — exercised by parity tests. */
	public static function tabLabels(group:Int):Array<String> {
		return group > 0 ? ["Chat", "PMs", "Players", "Account"] : ["Chat", "Players", "Account"];
	}

	public function new() {
		super();
		var chatTab = new LobbyTab(changeTabChat, "Chat");
		var pmsTab = new LobbyTab(changeTabPMs, "PMs");
		var playersTab = new LobbyTab(changeTabPlayers, "Players");
		var accountTab = new LobbyTab(changeTabAccount, "Account");

		var tabArray:Array<LobbyTab>;
		var lastArrKey:Int;
		if (LobbySession.isMember()) {
			tabArray = [chatTab, pmsTab, playersTab, accountTab];
			lastArrKey = 3;
		} else {
			tabArray = [chatTab, playersTab, accountTab];
			lastArrKey = 2;
		}
		x = 3;
		y = 3;
		configure(tabArray, "lobbyLeft", lastArrKey, 194, 394);
	}

	private function changeTabChat():Void {
		changePage(new ChatTab());
	}

	private function changeTabPMs():Void {
		changePage(new MessagesTab());
	}

	private function changeTabPlayers():Void {
		changePage(new PlayersTab());
	}

	private function changeTabAccount():Void {
		changePage(new AccountTab());
	}
}
