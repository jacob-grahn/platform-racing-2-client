package pr2.lobby;

import pr2.lobby.tabs.ListingTab;
import pr2.lobby.tabs.SearchTab;
import pr2.ui.LobbyTab;

/**
	Port of Flash `lobby.LobbyRight`: the right pane (`347 x 356` at `(200, 3)`).

	Tabs are Campaign / All Time Best / Week's Best / Newest / Search, plus a
	Favorites (♥) tab for members. Campaign is selected by default. `lookupUser` /
	`lookupLevel` jump to the Search tab, mirroring the player/level popup hooks.
**/
class LobbyRight extends LobbySide {
	public static var instance:Null<LobbyRight>;

	/** Tab labels for the pane given an access group — exercised by parity tests. */
	public static function tabLabels(group:Int):Array<String> {
		var labels = ["Campaign", "All Time Best", "Week's Best", "Newest", "Search"];
		if (group >= 1) {
			labels.push("♥");
		}
		return labels;
	}

	private var searchTab:LobbyTab;

	public function new() {
		super();
		instance = this;

		var campaignTab = new LobbyTab(clickCampaign, "Campaign");
		var atbTab = new LobbyTab(clickBest, "All Time Best");
		var wbTab = new LobbyTab(clickBestWeek, "Week's Best");
		var newTab = new LobbyTab(clickNew, "Newest");
		searchTab = new LobbyTab(clickSearch, "Search");
		var favsTab = new LobbyTab(clickFavs, "♥");

		var tabsArray = [campaignTab, atbTab, wbTab, newTab, searchTab];
		if (LobbySession.group >= 1) {
			tabsArray.push(favsTab);
		}
		x = 200;
		y = 3;
		configure(tabsArray, "lobbyRight", 0, 347, 356);
	}

	private function clickCampaign():Void {
		changePage(new ListingTab("campaign"));
	}

	private function clickBest():Void {
		changePage(new ListingTab("best"));
	}

	private function clickBestWeek():Void {
		changePage(new ListingTab("best_week"));
	}

	private function clickNew():Void {
		changePage(new ListingTab("newest"));
	}

	private function clickSearch():Void {
		changePage(new SearchTab());
	}

	private function clickFavs():Void {
		changePage(new ListingTab("favorites"));
	}

	public function lookupUser(userName:String = ""):Void {
		searchTab.select();
		changePage(new SearchTab(userName));
	}

	public function lookupLevel(levelId:String = ""):Void {
		searchTab.select();
		changePage(new SearchTab(levelId, "id"));
	}

	override public function remove():Void {
		instance = null;
		super.remove();
	}
}
