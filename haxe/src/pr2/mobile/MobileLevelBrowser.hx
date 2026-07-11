package pr2.mobile;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.TouchEvent;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
import pr2.lobby.LobbySession;
import pr2.lobby.Memory;
import pr2.lobby.level.LevelListingState;
import pr2.lobby.tabs.ListingTab;
import pr2.lobby.tabs.SearchTab;
import pr2.net.CampaignLevelInfo;
import pr2.net.LevelListClient.LevelListResult;
import pr2.net.LobbySocket;
import pr2.runtime.FontResolver;
import pr2.util.AsyncRemovalGuard;

/** Responsive one-column level browser shared by every mobile Play section. */
class MobileLevelBrowser extends Sprite {
	private var mode:String = "campaign";
	private var searchMode:String = "title";
	private var page:Int = 1;
	private var viewWidth:Float = 550;
	private var viewHeight:Float = 250;
	private var viewport:Sprite;
	private var content:Sprite;
	private var clipShape:Shape;
	private var cards:Array<MobileLevelCard> = [];
	private var status:TextField;
	private var pageLabel:TextField;
	private var searchField:TextField;
	private var searchButton:MobileButton;
	private var prevButton:MobileButton;
	private var nextButton:MobileButton;
	private var guard:AsyncRemovalGuard = new AsyncRemovalGuard();
	private var touchId:Int = -1;
	private var lastTouchY:Float = 0;
	private var scrollStartY:Float = 0;

	public function new() {
		super();
		viewport = new Sprite();
		content = new Sprite();
		viewport.addChild(content);
		addChild(viewport);
		clipShape = new Shape();
		addChild(clipShape);
		viewport.mask = clipShape;

		status = textField(16, 0xD5E2F5, true);
		status.text = "Loading courses…";
		content.addChild(status);
		pageLabel = textField(15, 0xD5E2F5, true);
		addChild(pageLabel);

		searchField = textField(18, 0x182238, false);
		searchField.type = TextFieldType.INPUT;
		searchField.background = true;
		searchField.backgroundColor = 0xEEF4FF;
		searchField.border = true;
		searchField.borderColor = 0x8EA2C2;
		searchField.height = 46;
		searchField.addEventListener(KeyboardEvent.KEY_DOWN, onSearchKey);
		addChild(searchField);

		searchButton = new MobileButton("Search", 100, 46, doSearch);
		addChild(searchButton);
		prevButton = new MobileButton("‹ Prev", 92, 46, previousPage);
		nextButton = new MobileButton("Next ›", 92, 46, nextPage);
		addChild(prevButton);
		addChild(nextButton);

		viewport.addEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
		viewport.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
		viewport.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
		viewport.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
		showMode("campaign");
	}

	public function setLayout(width:Float, height:Float):Void {
		viewWidth = Math.max(320, width);
		viewHeight = Math.max(130, height);
		var toolbarH = mode == "search" ? 54 : 0;
		viewport.y = toolbarH;
		clipShape.graphics.clear();
		clipShape.graphics.beginFill(0x000000);
		clipShape.graphics.drawRect(0, toolbarH, viewWidth, Math.max(1, viewHeight - toolbarH - 52));
		clipShape.graphics.endFill();
		status.width = viewWidth - 28;
		status.x = 14;
		searchField.visible = searchButton.visible = mode == "search";
		searchField.x = 8;
		searchField.y = 3;
		searchField.width = viewWidth - 122;
		searchButton.x = viewWidth - 108;
		searchButton.y = 3;
		prevButton.x = 8;
		prevButton.y = viewHeight - 48;
		nextButton.x = viewWidth - 100;
		nextButton.y = viewHeight - 48;
		pageLabel.x = 108;
		pageLabel.y = viewHeight - 40;
		pageLabel.width = viewWidth - 216;
		pageLabel.height = 34;
		pageLabel.text = 'Page $page';
		rebuildCards();
	}

	public function showMode(value:String):Void {
		mode = value;
		page = Memory.getInt("mobileCoursePage_" + mode, 1);
		if (page < 1) page = 1;
		LevelListingState.currentPageNum = page;
		if (searchField != null) {
			searchField.visible = searchButton.visible = mode == "search";
			if (mode == "search") searchField.text = Memory.getString("mobileSearch", "");
		}
		request();
	}

	public function showSearch(query:String, mode:String):Void {
		searchMode = mode == null || mode == "" ? "title" : mode;
		searchField.text = query == null ? "" : query;
		Memory.set("mobileSearch", searchField.text);
		showMode("search");
	}

	private function request():Void {
		guard.remove();
		guard = new AsyncRemovalGuard();
		clearCards();
		status.visible = true;
		status.text = mode == "search" && StringTools.trim(searchField.text) == "" ? "Type a level, author, or ID above." : "Loading courses…";
		content.y = 0;
		pageLabel.text = 'Page $page';
		LevelListingState.currentPageNum = page;
		LobbySocket.write("set_right_room`none");
		if (mode == "search") {
			if (StringTools.trim(searchField.text) == "") return;
			var params = ["search_str" => searchField.text, "mode" => searchMode, "order" => "rating", "dir" => "desc", "page" => Std.string(page)];
			guard.watch(SearchTab.searchFactory(params, guard.wrap(onResult), guard.wrap(onError)));
		} else if (mode == "favorites") {
			guard.watch(ListingTab.fetchFavoritesFactory(LobbySession.userId, page, LobbySession.token, guard.wrap(onResult), guard.wrap(onError)));
		} else {
			guard.watch(ListingTab.fetchFactory(mode, page, guard.wrap(onResult), guard.wrap(onError)));
		}
	}

	private function onResult(result:LevelListResult):Void {
		if (!result.hashValid) {
			onError("invalid list");
			return;
		}
		status.visible = result.levels.length == 0;
		status.text = "No courses found.";
		for (info in result.levels) cards.push(new MobileLevelCard(info, viewWidth - 16));
		rebuildCards();
		LobbySocket.write("set_right_room`" + (mode == "favorites" ? "search" : mode));
	}

	private function onError(_:String):Void {
		status.visible = true;
		status.text = "Couldn’t load courses. Tap the section to try again.";
	}

	private function rebuildCards():Void {
		var y = 8.0;
		for (card in cards) {
			if (card.parent != content) content.addChild(card);
			card.x = 8;
			card.y = y;
			y += MobileLevelCard.CARD_HEIGHT + 8;
		}
		clampScroll();
	}

	private function clearCards():Void {
		for (card in cards) card.remove();
		cards = [];
	}

	private function doSearch():Void {
		Memory.set("mobileSearch", searchField.text);
		page = 1;
		request();
	}

	private function previousPage():Void {
		if (page > 1) {
			page--;
			rememberPage();
			request();
		}
	}

	private function nextPage():Void {
		page++;
		rememberPage();
		request();
	}

	private function rememberPage():Void Memory.set("mobileCoursePage_" + mode, page);

	private function onSearchKey(event:KeyboardEvent):Void {
		if (event.keyCode == Keyboard.ENTER) doSearch();
	}

	private function onWheel(event:MouseEvent):Void {
		content.y += event.delta * 24;
		clampScroll();
	}

	private function onTouchBegin(event:TouchEvent):Void {
		if (touchId != -1) return;
		touchId = event.touchPointID;
		lastTouchY = event.stageY;
		scrollStartY = content.y;
	}

	private function onTouchMove(event:TouchEvent):Void {
		if (event.touchPointID != touchId) return;
		content.y += event.stageY - lastTouchY;
		lastTouchY = event.stageY;
		clampScroll();
	}

	private function onTouchEnd(event:TouchEvent):Void {
		if (event.touchPointID == touchId) touchId = -1;
	}

	private function clampScroll():Void {
		var toolbarH = mode == "search" ? 54 : 0;
		var visibleH = Math.max(1, viewHeight - toolbarH - 52);
		var totalH = cards.length == 0 ? 0 : cards.length * (MobileLevelCard.CARD_HEIGHT + 8);
		var minY = Math.min(0, visibleH - totalH - 8);
		if (content.y > 0) content.y = 0;
		if (content.y < minY) content.y = minY;
	}

	private static function textField(size:Int, color:Int, bold:Bool):TextField {
		var field = new TextField();
		field.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, size, color, bold, false, false, null, null, "center");
		field.height = 36;
		field.selectable = false;
		return field;
	}

	public function remove():Void {
		guard.remove();
		clearCards();
		viewport.removeEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
		viewport.removeEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
		viewport.removeEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
		viewport.removeEventListener(TouchEvent.TOUCH_END, onTouchEnd);
		searchField.removeEventListener(KeyboardEvent.KEY_DOWN, onSearchKey);
		searchButton.remove();
		prevButton.remove();
		nextButton.remove();
		LobbySocket.write("set_right_room`none");
		if (parent != null) parent.removeChild(this);
	}
}
