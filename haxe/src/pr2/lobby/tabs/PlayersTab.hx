package pr2.lobby.tabs;

import pr2.lobby.LobbySession;
import pr2.lobby.players.Following;
import pr2.lobby.players.Friends;
import pr2.lobby.players.Guilds;
import pr2.lobby.players.Ignored;
import pr2.lobby.players.Online;
import pr2.page.Page;
import pr2.page.PageHolder;
import pr2.ui.LobbyTab;
import pr2.ui.TabsHolder;

/**
	Port of Flash `social.PlayersTab`: the Players left-pane tab with its own
	nested tab strip. Members see Online / Friends / Following / Ignored; guests
	see Online / Guilds (the Flash client left the member Guilds tab commented
	out). Sub-tab selection is remembered under the `playerLists` holder id.
**/
class PlayersTab extends Page {
	private var tabsHolder:Null<TabsHolder>;
	private var innerHolder:Null<PageHolder>;

	override public function initialize():Void {
		innerHolder = new PageHolder();
		innerHolder.y = 20;

		var online = new LobbyTab(clickOnline, "Online");
		var friends = new LobbyTab(clickFriends, "Friends");
		var following = new LobbyTab(clickFollowing, "Following");
		var ignored = new LobbyTab(clickIgnored, "Ignored");
		var guilds = new LobbyTab(clickGuilds, "Guilds");

		var tabs = LobbySession.group > 0 ? [online, friends, following, ignored] : [online, guilds];
		tabsHolder = new TabsHolder(tabs, "playerLists", 0, 186);
		addChild(tabsHolder);
		addChild(innerHolder);
	}

	private function clickOnline():Void {
		changeInner(new Online());
	}

	private function clickFriends():Void {
		changeInner(new Friends());
	}

	private function clickFollowing():Void {
		changeInner(new Following());
	}

	private function clickIgnored():Void {
		changeInner(new Ignored());
	}

	private function clickGuilds():Void {
		changeInner(new Guilds());
	}

	private function changeInner(page:Page):Void {
		if (innerHolder != null) {
			innerHolder.changePage(page);
		}
	}

	override public function remove():Void {
		if (tabsHolder != null) {
			tabsHolder.remove();
			tabsHolder = null;
		}
		if (innerHolder != null) {
			var current = innerHolder.getCurrentPage();
			if (current != null) {
				current.remove();
			}
			if (innerHolder.parent != null) {
				innerHolder.parent.removeChild(innerHolder);
			}
			innerHolder = null;
		}
		super.remove();
	}
}
