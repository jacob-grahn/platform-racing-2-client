package pr2.lobby.level;

#if js
import js.Browser;
#end

/**
	Hand-off from the lobby listing to the playable level path that exists today.

	In the original client the gameserver orchestrates the race start after a slot
	is confirmed; the full real-server race flow is tracked separately under
	"Networking And Real Server Flow". Until that lands, selecting a campaign level
	and pressing Play in the `CourseMenu` launches the existing level loader: on
	HTML5 it navigates to the `?screen=campaign` harness (which fetches the page,
	finds the level id, decodes and renders it, and drops the character in), and on
	other targets it records the launch so the behaviour is testable.

	A `handler` override lets tests (or a future in-lobby transition) intercept the
	launch instead of navigating.
**/
class LevelLaunch {
	/** Last launch request as "levelId`version" — inspected by tests. */
	public static var lastLaunch:String = "";

	/** Optional override; when set it receives `(levelId, version)` and the
		default navigation is skipped. **/
	public static var handler:Null<(Int, Int) -> Void> = null;

	private function new() {}

	public static function launch(levelId:Int, version:Int):Void {
		lastLaunch = levelId + "`" + version;
		if (handler != null) {
			handler(levelId, version);
			return;
		}
		#if js
		var page = LevelListingState.currentPageNum;
		Browser.location.search = "?screen=campaign&page=" + page + "&levelId=" + levelId;
		#end
	}
}
