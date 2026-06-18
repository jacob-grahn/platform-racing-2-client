package pr2.lobby.tabs;

import pr2.lobby.LobbySession;
import pr2.lobby.Memory;
import pr2.lobby.level.LevelListingPage;
import pr2.net.LevelListClient;
import pr2.net.LevelListClient.LevelListResult;

/**
	Port of Flash `level_browser.LevelListing` and its mode subclasses
	(`Campaign`, `Best`, `BestWeek`, `Newest`, `Favorites`).

	Loads the course list for the current page over GET, validates the list hash,
	and renders the three-column grid via `LevelListingPage`. Page numbers are
	remembered per mode; the campaign tab seeds its page from the Flash formula
	`((server_id + day) % 6) + 1`.
**/
class ListingTab extends LevelListingPage {
	/** Flash campaign page formula: `((server_id + day) % 6) + 1`. */
	public static function campaignPage(serverId:Int, weekday:Int):Int {
		return LevelListClient.campaignPage(serverId, weekday);
	}

	public function new(mode:String) {
		super(mode, ListingTab.initialPageFor(mode));
	}

	private static function initialPageFor(mode:String):Int {
		if (mode == "campaign") {
			var serverId = LobbySession.server != null ? LobbySession.server.serverId : 0;
			return campaignPage(serverId, currentWeekday());
		}
		var remembered = Memory.getInt("coursePageNum" + mode, 0);
		return remembered != 0 ? remembered : 1;
	}

	override private function requestCourses():Void {
		showLoading();
		LevelListClient.fetch(mode, getPageNum(), onLoaded, onError);
	}

	private function onLoaded(result:LevelListResult):Void {
		hideLoading();
		// Flash only renders a list whose hash matches; a mismatch shows nothing.
		if (result.hashValid) {
			renderCourses(result.levels);
		}
	}

	private function onError(_:String):Void {
		hideLoading();
	}

	override private function onPageChanged(n:Int):Void {
		Memory.set("coursePageNum" + mode, n);
	}

	private static function currentWeekday():Int {
		return Std.int(Date.now().getDay());
	}
}
