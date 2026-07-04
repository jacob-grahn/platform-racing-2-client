package pr2.lobby.tabs;

import openfl.events.TimerEvent;
import openfl.utils.Timer;
import pr2.lobby.LobbySession;
import pr2.lobby.Memory;
import pr2.lobby.level.LevelListingPage;
import pr2.net.CampaignLevelInfo;
import pr2.net.LevelListClient;
import pr2.net.LevelListClient.LevelListResult;
import pr2.net.LobbySocket;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

typedef LevelListFetchFactory = String->Int->(LevelListResult->Void)->(String->Void)->AsyncRemovable;
typedef FavoriteLevelListFetchFactory = Int->Int->String->(LevelListResult->Void)->(String->Void)->AsyncRemovable;

/**
	Port of Flash `level_browser.LevelListing` and its mode subclasses
	(`Campaign`, `Best`, `BestWeek`, `Newest`, `Favorites`).

	Loads the course list for the current page over GET, validates the list hash,
	and renders the three-column grid via `LevelListingPage`. Page numbers are
	remembered per mode; the campaign tab seeds its page from the Flash formula
	`((server_id + day) % 6) + 1`.
**/
class ListingTab extends LevelListingPage {
	public static var fetchFactory:LevelListFetchFactory = defaultFetch;
	public static var fetchFavoritesFactory:FavoriteLevelListFetchFactory = defaultFetchFavorites;

	private var campaignRenderTimer:Null<Timer>;
	private var pendingCampaignLevels:Null<Array<CampaignLevelInfo>>;

	/** Flash campaign page formula: `((server_id + day) % 6) + 1`. */
	public static function campaignPage(serverId:Int, day:Int):Int {
		return LevelListClient.campaignPage(serverId, day);
	}

	public function new(mode:String) {
		super(mode, ListingTab.initialPageFor(mode), mode == "campaign" ? 6 : 9);
	}

	private static function initialPageFor(mode:String):Int {
		if (mode == "campaign") {
			var serverId = LobbySession.server != null ? LobbySession.server.serverId : 0;
			var page = campaignPage(serverId, currentServerDay());
			LobbySocket.campaignPage = page;
			return page;
		}
		var remembered = Memory.getInt("coursePageNum" + mode, 0);
		return remembered != 0 ? remembered : 1;
	}

	override private function requestCourses():Void {
		cancelCampaignRender();
		showLoading();
		var page = getPageNum();
		if (mode == "campaign") {
			var cached:Dynamic = Memory.get("campaignInfo" + page);
			if (cached != null) {
				scheduleCampaignRender(cast cached);
				return;
			}
		}
		// Favorites use a dedicated POST endpoint (user_id + page), not the generic
		// /files/lists/{mode}/{page} GET; mirrors Flash `Favorites.requestCourses`.
		if (mode == "favorites") {
			watchAsync(fetchFavoritesFactory(LobbySession.userId, page, LobbySession.token, guardCallback(function(result:LevelListResult):Void {
				onLoaded(page, result);
			}), guardCallback(onError)));
		} else {
			watchAsync(fetchFactory(mode, page, guardCallback(function(result:LevelListResult):Void {
				onLoaded(page, result);
			}), guardCallback(onError)));
		}
	}

	private function onLoaded(page:Int, result:LevelListResult):Void {
		hideLoading();
		// Flash only renders a list whose hash matches; a mismatch shows nothing.
		if (result.hashValid) {
			if (mode == "campaign") {
				Memory.set("campaignInfo" + page, result.levels);
			}
			renderCourses(result.levels);
		}
	}

	private function onError(_:String):Void {
		hideLoading();
	}

	override private function onPageChanged(n:Int):Void {
		Memory.set("coursePageNum" + mode, n);
	}

	override private function onTeardown():Void {
		cancelCampaignRender();
	}

	public static function currentServerDayForTests():Int {
		return currentServerDay();
	}

	public static function resetHooksForTests():Void {
		fetchFactory = defaultFetch;
		fetchFavoritesFactory = defaultFetchFavorites;
	}

	private static function currentServerDay():Int {
		return Std.int(LobbySession.lastAuthTime.getDay());
	}

	private static function defaultFetch(mode:String, page:Int, onResult:LevelListResult->Void, onError:String->Void):AsyncRemovable {
		return LevelListClient.fetch(mode, page, onResult, onError);
	}

	private static function defaultFetchFavorites(userId:Int, page:Int, token:String, onResult:LevelListResult->Void, onError:String->Void):AsyncRemovable {
		return LevelListClient.fetchFavorites(userId, page, token, onResult, onError);
	}

	private function scheduleCampaignRender(levels:Array<CampaignLevelInfo>):Void {
		pendingCampaignLevels = levels;
		campaignRenderTimer = new Timer(250, 1);
		campaignRenderTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onCampaignRenderTimer);
		campaignRenderTimer.start();
	}

	private function onCampaignRenderTimer(?_:TimerEvent):Void {
		var levels = pendingCampaignLevels;
		cancelCampaignRender();
		if (levels != null) {
			renderCourses(levels);
		}
	}

	private function cancelCampaignRender():Void {
		if (campaignRenderTimer != null) {
			campaignRenderTimer.stop();
			campaignRenderTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onCampaignRenderTimer);
			campaignRenderTimer = null;
		}
		pendingCampaignLevels = null;
	}
}
