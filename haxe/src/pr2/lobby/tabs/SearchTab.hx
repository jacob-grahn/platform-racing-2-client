package pr2.lobby.tabs;

import openfl.display.DisplayObjectContainer;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import openfl.ui.Keyboard;
import pr2.lobby.LobbyArt;
import pr2.lobby.Memory;
import pr2.lobby.level.LevelListingPage;
import pr2.lobby.search.SearchQuery;
import pr2.net.LevelListClient;
import pr2.net.LevelListClient.LevelListResult;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `level_browser.Search`.

	Renders the real `SearchGraphic` (search box, button, and the mode/order/
	direction dropdowns) and runs searches through `LevelListingPage`: the request
	guards and POST parameters come from the pure `SearchQuery`, results POST to
	`search_levels.php` and render in the shared three-column grid, and the query
	is persisted to `Memory`. Seeded lookups (`LobbyRight.lookupUser` /
	`lookupLevel`) run immediately.

	The mode/order/direction combo boxes are shown but not yet interactive — the
	fl `ComboBox` component port is pending — so selection falls back to the seeded
	or remembered mode with default order/direction.
**/
class SearchTab extends LevelListingPage {
	private var art:PR2MovieClip;
	private var searchBox:Null<TextField>;
	private var searchButton:Null<openfl.display.DisplayObject>;
	private var searchBinding:Null<LobbyArt.Binding>;

	private var seededQuery:String;
	private var searchMode:String;
	private var order:String;
	private var dir:String;
	private var firstRun:Bool = true;

	public function new(?query:String, ?searchMode:String) {
		super("search", 1);
		this.seededQuery = query != null ? query : "";
		this.searchMode = searchMode != null ? searchMode : modeFromMemory();
		this.order = "";
		this.dir = "";
	}

	override private function onInitialized():Void {
		art = PR2MovieClip.fromLinkage("SearchGraphic", {maxNestedDepth: 8});
		art.x = 36;
		art.y = 8;
		addChild(art);

		searchBox = firstInputField(art);
		searchButton = LobbyArt.findByName(art, "search_bt");
		searchBinding = LobbyArt.bind(searchButton, doSearch);
		if (searchBox != null) {
			searchBox.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			var remembered = Memory.getString("searchStr", "");
			searchBox.text = seededQuery != "" ? seededQuery : remembered;
		}
	}

	override private function requestCourses():Void {
		var query = searchBox != null ? searchBox.text : seededQuery;
		var decision = SearchQuery.decide(query, searchMode, getPageNum(), firstRun);
		switch (decision) {
			case Skip:
				hideLoading();
				return;
			case ResetToFirstPage:
				firstRun = false;
				setPageNum(1);
				return;
			case Send:
		}
		firstRun = false;
		showLoading();
		var params = SearchQuery.buildPost(query, searchMode, order, dir, getPageNum());
		LevelListClient.search(params, onLoaded, onError);
	}

	private function onLoaded(result:LevelListResult):Void {
		hideLoading();
		if (result.hashValid) {
			renderCourses(result.levels);
		}
	}

	private function onError(_:String):Void {
		hideLoading();
	}

	private function doSearch():Void {
		if (searchBox != null && searchBox.text != "") {
			setPageNum(1);
		}
	}

	private function onKeyDown(event:KeyboardEvent):Void {
		if (event.keyCode == Keyboard.ENTER) {
			doSearch();
		}
	}

	private function modeFromMemory():String {
		var remembered = Memory.getString("searchMode", "");
		return remembered != "" ? remembered : "user";
	}

	override private function onTeardown():Void {
		if (searchBox != null) {
			Memory.set("searchStr", searchBox.text);
			searchBox.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		Memory.set("searchMode", searchMode);
		LobbyArt.unbind(searchBinding);
		if (art != null) {
			art.dispose();
			art = null;
		}
	}

	/** First text field under the SearchGraphic's TextInput clip. */
	private static function firstInputField(container:DisplayObjectContainer):Null<TextField> {
		var box = Std.downcast(LobbyArt.findByName(container, "searchBox"), DisplayObjectContainer);
		var fields = LobbyArt.textFields(box != null ? box : container);
		return fields.length > 0 ? fields[0] : null;
	}
}
