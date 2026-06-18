package pr2.lobby.tabs;

/**
	Port-in-progress of Flash `social.PlayersTab`.

	Renders the real `PlayersTabListGraphic` art and requests the online list
	(`get_online_list`) on enter. The nested Online/Friends/Following/Ignored (and
	guest Guilds) sub-tabs, list item rendering, and follow/friend/ignore actions
	are still being ported.
**/
class PlayersTab extends ScaffoldTab {
	public function new() {
		super("PlayersTabListGraphic", "get_online_list`", null,
			"Players — nested Online/Friends/Following/Ignored sub-tabs are being ported.");
	}
}
