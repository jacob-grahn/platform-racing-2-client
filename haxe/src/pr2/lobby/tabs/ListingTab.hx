package pr2.lobby.tabs;

import openfl.display.Sprite;
import pr2.lobby.LobbySession;
import pr2.lobby.Memory;
import pr2.lobby.level.LevelGridLayout;
import pr2.lobby.level.LevelItem;
import pr2.lobby.level.LevelListingState;
import pr2.net.CampaignLevelInfo;
import pr2.net.CommandHandler;
import pr2.net.LevelListClient;
import pr2.net.LevelListClient.LevelListResult;
import pr2.net.LobbySocket;
import pr2.page.Page;
import pr2.runtime.PR2MovieClip;
import pr2.ui.PageNavigation;
import pr2.ui.PageNavigation.Paginated;

/**
	Port of Flash `level_browser.LevelListing` (and the `Campaign`/`Best`/
	`BestWeek`/`Newest`/`Favorites` subclasses that differ only by `mode`).

	Loads the course list for the current page, validates the list hash, and lays
	the levels out in a three-column `LevelItem` grid alongside a vertical
	`PageNavigation`. Page numbers are remembered per mode; the campaign tab seeds
	its page from the Flash formula `((server_id + day) % 6) + 1`. `set_right_room`
	is written once the page renders, and the server-driven `addPageHighlight` /
	`removePageHighlight` / `testLevelAccess` commands are honored.
**/
class ListingTab extends Page implements Paginated {
	/** Flash campaign page formula: `((server_id + day) % 6) + 1`. */
	public static function campaignPage(serverId:Int, weekday:Int):Int {
		return LevelListClient.campaignPage(serverId, weekday);
	}

	private var mode:String;
	private var pageNum:Int = 1;
	private var holder:Sprite;
	private var loading:Null<PR2MovieClip>;
	private var pageNavigation:PageNavigation;
	private var levelItems:Array<LevelItem> = [];

	public function new(mode:String) {
		super();
		this.mode = mode;
		this.pageNum = resolveInitialPage();
	}

	override public function initialize():Void {
		holder = new Sprite();
		addChild(holder);

		loading = PR2MovieClip.fromLinkage("LoadingGraphic", {maxNestedDepth: 4});
		loading.x = 164;
		loading.y = 150;
		addChild(loading);

		pageNavigation = new PageNavigation(this, "vertical", pageNum, 9, 283);
		pageNavigation.x = 328;
		pageNavigation.y = 26;
		addChild(pageNavigation);

		LobbySocket.write("set_right_room`none");

		var cm = CommandHandler.commandHandler;
		cm.defineCommand("addPageHighlight", onAddPageHighlight);
		cm.defineCommand("removePageHighlight", onRemovePageHighlight);
		cm.defineCommand("testLevelAccess", onTestLevelAccess);

		requestCourses();
	}

	private function resolveInitialPage():Int {
		if (mode == "campaign") {
			var serverId = LobbySession.server != null ? LobbySession.server.serverId : 0;
			return campaignPage(serverId, currentWeekday());
		}
		var remembered = Memory.getInt("coursePageNum" + mode, 0);
		return remembered != 0 ? remembered : 1;
	}

	private function requestCourses():Void {
		LevelListingState.currentPageNum = pageNum;
		if (loading != null) {
			loading.visible = true;
		}
		LevelListClient.fetch(mode, pageNum, onLoaded, onError);
	}

	private function onLoaded(result:LevelListResult):Void {
		if (loading != null) {
			loading.visible = false;
		}
		// Flash only renders a list whose hash matches; a mismatch shows nothing.
		if (result.hashValid) {
			showCourses(result.levels);
		}
	}

	private function onError(_:String):Void {
		if (loading != null) {
			loading.visible = false;
		}
	}

	private function showCourses(levels:Array<CampaignLevelInfo>):Void {
		var spriteHeight = holder.height;
		if (spriteHeight != 0) {
			spriteHeight += 20;
		}
		var positions = LevelGridLayout.positions(levels.length, spriteHeight);
		for (pos in positions) {
			var item = new LevelItem(levels[pos.index]);
			item.x = pos.x;
			item.y = pos.y;
			levelItems.push(item);
			holder.addChild(item);
		}
		LobbySocket.write("set_right_room`" + (mode == "favorites" ? "search" : mode));
	}

	private function removeLevels():Void {
		for (item in levelItems) {
			item.remove();
		}
		levelItems = [];
	}

	// Paginated
	public function setPageNum(n:Int):Void {
		pageNum = n;
		Memory.set("coursePageNum" + mode, n);
		LevelListingState.currentPageNum = n;
		removeLevels();
		requestCourses();
	}

	private function onAddPageHighlight(args:Array<String>):Void {
		if (mode == "search" || mode == "favorites") {
			return;
		}
		var i = Std.parseInt(args[0]);
		if (i != null) {
			pageNavigation.addPageHighlight(i);
		}
	}

	private function onRemovePageHighlight(args:Array<String>):Void {
		if (mode == "search" || mode == "favorites") {
			return;
		}
		var i = Std.parseInt(args[0]);
		if (i != null) {
			pageNavigation.removePageHighlight(i);
		}
	}

	private function onTestLevelAccess(_:Array<String>):Void {
		for (item in levelItems) {
			item.testAccess();
		}
	}

	private static function currentWeekday():Int {
		return Std.int(Date.now().getDay());
	}

	override public function remove():Void {
		var cm = CommandHandler.commandHandler;
		cm.defineCommand("addPageHighlight", null);
		cm.defineCommand("removePageHighlight", null);
		cm.defineCommand("testLevelAccess", null);
		if (pageNavigation != null) {
			pageNavigation.remove();
		}
		removeLevels();
		super.remove();
	}
}
