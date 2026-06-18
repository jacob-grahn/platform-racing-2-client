package pr2.lobby.tabs;

import pr2.runtime.PR2MovieClip;

/**
	Port-in-progress of the Flash `level_browser` listing pages (`Best`,
	`BestWeek`, `Newest`, `Favorites`, `Campaign`).

	Each shares the same shell — a `LoadingGraphic`, a vertical `PageNavigation`,
	and a three-column grid of `LevelItem`s loaded from the list endpoint — and
	differs only by `mode`. The shell renders and emits `set_right_room` exactly
	as the AS3 `LevelListing`/`PaginatedPage` did; the level grid, page navigation
	art, list-hash validation, and access checks are still being ported.
**/
class ListingTab extends ScaffoldTab {
	/** Flash campaign page formula: `((server_id + day) % 6) + 1`. */
	public static function campaignPage(serverId:Int, weekday:Int):Int {
		return ((serverId + weekday) % 6) + 1;
	}

	private var mode:String;

	public function new(mode:String) {
		this.mode = mode;
		// LevelListing/PaginatedPage write `set_right_room`none` on entry; the
		// per-mode room is set only once courses have loaded.
		super("LoadingGraphic", "set_right_room`none", null,
			'Levels ($mode) — level grid and page navigation are being ported.');
	}

	override private function onArtReady(art:PR2MovieClip):Void {
		// Center the loading spinner the way LevelListing positioned it.
		art.x = 164;
		art.y = 150;
	}
}
