package pr2.lobby.tabs;

import pr2.lobby.LobbySession;
import pr2.lobby.Memory;
import pr2.net.LevelListClient;
import pr2.net.LobbySocket;
import pr2.runtime.PR2MovieClip;

/**
	Port-in-progress of the Flash `level_browser` listing pages (`Best`,
	`BestWeek`, `Newest`, `Favorites`, `Campaign`).

	Each shares the same shell — a `LoadingGraphic`, a vertical `PageNavigation`,
	and a three-column grid of `LevelItem`s loaded from the list endpoint — and
	differs only by `mode`. This tab now performs the real list fetch (correct
	page, hash validation, and per-mode `set_right_room` on success) and reports
	the loaded level count; the interactive `LevelItem` grid and page-navigation
	art are still being ported.
**/
class ListingTab extends ScaffoldTab {
	/** Flash campaign page formula: `((server_id + day) % 6) + 1`. */
	public static function campaignPage(serverId:Int, weekday:Int):Int {
		return LevelListClient.campaignPage(serverId, weekday);
	}

	private var mode:String;
	private var page:Int = 1;

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
		page = resolvePage();
		LevelListClient.fetch(mode, page, onLoaded, onError);
	}

	private function resolvePage():Int {
		if (mode == "campaign") {
			var serverId = LobbySession.server != null ? LobbySession.server.serverId : 0;
			return LevelListClient.campaignPage(serverId, currentWeekday());
		}
		// LevelListing restores the remembered page per mode (`coursePageNum<mode>`).
		var remembered = Memory.getInt("coursePageNum" + mode, 0);
		return remembered != 0 ? remembered : 1;
	}

	private function onLoaded(result:pr2.net.LevelListResult):Void {
		Memory.set("coursePageNum" + mode, page);
		// LevelListing.showCourses writes `set_right_room`search` for favorites.
		LobbySocket.write("set_right_room`" + (mode == "favorites" ? "search" : mode));
		var validity = result.hashValid ? "verified" : "unverified hash";
		setNote('Levels ($mode), page $page: ${result.levels.length} loaded ($validity). Grid rendering is being ported.');
	}

	private function onError(message:String):Void {
		setNote('Levels ($mode): could not load list ($message).');
	}

	private static function currentWeekday():Int {
		return Std.int(Date.now().getDay());
	}
}
