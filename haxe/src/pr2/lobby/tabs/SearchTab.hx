package pr2.lobby.tabs;

/**
	Port-in-progress of Flash `level_browser.Search`.

	Renders the real `SearchGraphic` art (search box, mode/order/direction
	dropdowns). The POST to `search_levels.php`, enter-key search, blank/id/page
	guards, persisted search state, and the `LobbyRight.lookupUser` /
	`lookupLevel` hooks are still being ported.
**/
class SearchTab extends ScaffoldTab {
	public function new(?query:String, ?searchMode:String) {
		// PaginatedPage base writes `set_right_room`none` on entry.
		super("SearchGraphic", "set_right_room`none", null,
			"Search — query POST to search_levels.php is being ported.");
	}
}
