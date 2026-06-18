package pr2.lobby.level;

import openfl.display.Sprite;
import pr2.net.CampaignLevelInfo;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.page.Page;
import pr2.runtime.PR2MovieClip;
import pr2.ui.PageNavigation;
import pr2.ui.PageNavigation.Paginated;

/**
	Shared base for the lobby right-pane listing pages, ported from Flash
	`level_browser.LevelListing`. Owns the level-item holder, the loading spinner,
	the vertical `PageNavigation`, the three-column grid placement, page-number
	memory, and the server-driven `addPageHighlight` / `removePageHighlight` /
	`testLevelAccess` commands.

	Subclasses supply `mode` and implement `requestCourses` (a GET for the standard
	listings, a POST for search), then call `renderCourses` once results arrive.
**/
class LevelListingPage extends Page implements Paginated {
	private var mode:String;
	private var pageNum:Int = 1;
	private var holder:Sprite;
	private var loading:Null<PR2MovieClip>;
	private var pageNavigation:PageNavigation;
	private var levelItems:Array<LevelItem> = [];

	public function new(mode:String, initialPage:Int = 1) {
		super();
		this.mode = mode;
		this.pageNum = initialPage;
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

		onInitialized();
		requestCourses();
	}

	/** Hook for subclasses to add their own controls (e.g. the search box). */
	private function onInitialized():Void {}

	/** Subclasses kick off their list load here (GET or POST). */
	private function requestCourses():Void {}

	private function showLoading():Void {
		if (loading != null) {
			loading.visible = true;
		}
	}

	private function hideLoading():Void {
		if (loading != null) {
			loading.visible = false;
		}
	}

	/** Lay the levels out in the three-column grid (Flash `showCourses`). */
	private function renderCourses(levels:Array<CampaignLevelInfo>):Void {
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
		hideLoading();
	}

	private function removeLevels():Void {
		for (item in levelItems) {
			item.remove();
		}
		levelItems = [];
	}

	public function getPageNum():Int {
		return pageNum;
	}

	// Paginated
	public function setPageNum(n:Int):Void {
		pageNum = n;
		onPageChanged(n);
		LevelListingState.currentPageNum = n;
		removeLevels();
		requestCourses();
	}

	/** Subclasses persist the page number how they wish (Memory for listings). */
	private function onPageChanged(n:Int):Void {}

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

	override public function remove():Void {
		var cm = CommandHandler.commandHandler;
		cm.defineCommand("addPageHighlight", null);
		cm.defineCommand("removePageHighlight", null);
		cm.defineCommand("testLevelAccess", null);
		if (pageNavigation != null) {
			pageNavigation.remove();
		}
		removeLevels();
		onTeardown();
		super.remove();
	}

	private function onTeardown():Void {}
}
