package pr2.lobby.tabs;

import pr2.lobby.search.SearchQuery;
import pr2.runtime.PR2MovieClip;

/**
	Port-in-progress of Flash `level_browser.Search`.

	Renders the real `SearchGraphic` art (search box, mode/order/direction
	dropdowns). The request guards and POST parameter building are ported in
	`SearchQuery`; when constructed via `LobbyRight.lookupUser` / `lookupLevel`
	the seeded query/mode is shown. The combo-box UI, the POST to
	`search_levels.php`, and the result grid are still being ported.
**/
class SearchTab extends ScaffoldTab {
	private var query:String;
	private var searchMode:String;

	public function new(?query:String, ?searchMode:String) {
		this.query = query != null ? query : "";
		this.searchMode = searchMode != null ? searchMode : "user";
		// PaginatedPage base writes `set_right_room`none` on entry.
		super("SearchGraphic", "set_right_room`none", null,
			"Search — query POST to search_levels.php is being ported.");
	}

	override private function onArtReady(art:PR2MovieClip):Void {
		art.x = 36;
		art.y = 8;
		if (query != "") {
			// A seeded lookup (player/level popup) would run immediately; report the
			// resolved request decision so the wired guards are observable.
			var decision = SearchQuery.decide(query, searchMode, 1, true);
			setNote('Search "$query" (mode $searchMode): ${decisionLabel(decision)}. Result grid is being ported.');
		}
	}

	private static function decisionLabel(decision:SearchDecision):String {
		return switch (decision) {
			case Send: "would POST search_levels.php";
			case ResetToFirstPage: "resets to page 1";
			case Skip: "skipped (blank/guarded)";
		}
	}
}
