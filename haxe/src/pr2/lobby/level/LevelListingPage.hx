package pr2.lobby.level;

import openfl.display.Sprite;
import openfl.display.DisplayObject;
import openfl.events.TimerEvent;
import openfl.utils.Timer;
import pr2.lobby.SecureData;
import pr2.net.CampaignLevelInfo;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.page.Page;
import pr2.runtime.PR2MovieClip;
import pr2.ui.PageNavigation;
import pr2.ui.PageNavigation.Paginated;
import pr2.util.AsyncRemovalGuard;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

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
	private var pageCount:Int = 9;
	private var holder:Sprite;
	private var loading:Null<PR2MovieClip>;
	private var pageNavigation:PageNavigation;
	private var levelItems:Array<LevelItem> = [];
	private var asyncGuard:AsyncRemovalGuard = new AsyncRemovalGuard();
	private var showCoursesTimer:Null<Timer>;
	private var pendingShowCoursesLevels:Null<Array<CampaignLevelInfo>>;

	public function new(mode:String, initialPage:Int = 1, pageCount:Int = 9) {
		super();
		this.mode = mode;
		this.pageNum = initialPage;
		this.pageCount = pageCount;
	}

	override public function initialize():Void {
		LevelListingState.currentPageNum = pageNum;

		holder = new Sprite();
		addChild(holder);

		loading = PR2MovieClip.fromLinkage("LoadingGraphic", {maxNestedDepth: 4});
		loading.x = 164;
		loading.y = 150;
		addChild(loading);

		pageNavigation = new PageNavigation(this, "vertical", pageNum, pageCount, 283);
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

	private function watchAsync<T:AsyncRemovable>(resource:T):T {
		return asyncGuard.watch(resource);
	}

	private function guardCallback<T>(callback:T->Void):T->Void {
		return asyncGuard.wrap(callback);
	}

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

	private function addToListingHolder(child:DisplayObject):Void {
		holder.addChild(child);
	}

	/** Lay the levels out in the three-column grid (Flash `showCourses`). */
	private function renderCourses(levels:Array<CampaignLevelInfo>):Void {
		if (SecureData.getNumber("userRank") < 0) {
			scheduleShowCourses(levels);
			return;
		}
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
		asyncGuard.remove();
		cancelShowCoursesTimer();
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

	private function scheduleShowCourses(levels:Array<CampaignLevelInfo>):Void {
		cancelShowCoursesTimer();
		pendingShowCoursesLevels = levels;
		showCoursesTimer = new Timer(250, 1);
		showCoursesTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onShowCoursesTimer);
		showCoursesTimer.start();
	}

	private function onShowCoursesTimer(?_:TimerEvent):Void {
		var levels = pendingShowCoursesLevels;
		cancelShowCoursesTimer();
		if (levels != null) {
			renderCourses(levels);
		}
	}

	private function cancelShowCoursesTimer():Void {
		if (showCoursesTimer != null) {
			showCoursesTimer.stop();
			showCoursesTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onShowCoursesTimer);
			showCoursesTimer = null;
		}
		pendingShowCoursesLevels = null;
	}

	public function levelItemCountForTests():Int {
		return levelItems.length;
	}

	public function pageNavigationForTests():PageNavigation {
		return pageNavigation;
	}

	public function levelItemForTests(index:Int):Null<LevelItem> {
		return index >= 0 && index < levelItems.length ? levelItems[index] : null;
	}

	public function loadingVisibleForTests():Bool {
		return loading != null && loading.visible;
	}

	public function loadingGraphicForTests():Null<PR2MovieClip> {
		return loading;
	}
}
