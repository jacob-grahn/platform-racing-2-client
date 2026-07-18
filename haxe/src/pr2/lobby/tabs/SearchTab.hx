package pr2.lobby.tabs;

import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.ui.Keyboard;
import pr2.lobby.Memory;
import pr2.lobby.level.LevelListingPage;
import pr2.lobby.search.SearchQuery;
import pr2.net.LevelListClient;
import pr2.net.LevelListClient.LevelListResult;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameSelect;
import pr2.ui.controls.GameTextInput;
import pr2.ui.StageFocus;
import pr2.ui.view.NativeView;
import pr2.util.AsyncRemovalGuard.AsyncRemovable;

typedef SearchFetchFactory = Map<String, String>->(LevelListResult->Void)->(String->Void)->AsyncRemovable;

/**
	Port of Flash `level_browser.Search`.

	Renders the real `SearchGraphic` (search box, button, and the mode/order/
	direction dropdowns) and runs searches through `LevelListingPage`: the request
	guards and POST parameters come from the pure `SearchQuery`, results POST to
	`search_levels.php` and render in the shared three-column grid. The mode/order/
	direction native dropdowns supply `selectedItem.data`, and the search box
	text plus the three combo `selectedIndex` values are persisted to `Memory`
	(`searchStr` / `searchModeIndex` / `searchOrderIndex` / `searchDirIndex`) and
	restored on re-entry, mirroring the original. Seeded lookups
	(`LobbyRight.lookupUser` / `lookupLevel`) preselect the matching mode and run
	immediately.
**/
class SearchTab extends LevelListingPage {
	public static var searchFactory:SearchFetchFactory = defaultSearch;

	private var art:SearchView;
	private var searchBox:Null<TextField>;
	private var modeCb:Null<GameSelect<Dynamic>>;
	private var orderCb:Null<GameSelect<Dynamic>>;
	private var dirCb:Null<GameSelect<Dynamic>>;

	private var seededQuery:String;
	private var seededMode:String;
	private var firstRun:Bool = true;

	public function new(?query:String, ?searchMode:String) {
		super("search", initialPage());
		this.seededQuery = query != null ? query : "";
		this.seededMode = searchMode != null ? searchMode : "user";
	}

	private static function initialPage():Int {
		var remembered = Memory.getInt("coursePageNumsearch", 0);
		return remembered != 0 ? remembered : 1;
	}

	override private function onInitialized():Void {
		art = new SearchView();
		art.x = 36;
		art.y = 8;
		addToListingHolder(art);

		searchBox = art.searchBox;
		art.searchButton.onPress = doSearch;
		if (searchBox != null) {
			searchBox.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}

		modeCb = art.modeSelect;
		orderCb = art.orderSelect;
		dirCb = art.directionSelect;
		addComboCloseListener(modeCb);
		addComboCloseListener(orderCb);
		addComboCloseListener(dirCb);

		// Restore the remembered query + dropdown selections; the base then calls
		// requestCourses(), which sends only when the box is non-blank.
		var rememberedStr = Memory.has("searchStr") ? Memory.getString("searchStr", "") : null;
		if (rememberedStr != null && searchBox != null) {
			searchBox.text = rememberedStr;
			selectIndex(modeCb, Memory.getInt("searchModeIndex", 0));
			selectIndex(orderCb, Memory.getInt("searchOrderIndex", 0));
			selectIndex(dirCb, Memory.getInt("searchDirIndex", 0));
		}

		// A seeded lookup (player/level popup) overrides the remembered state.
		if (seededQuery != "" && searchBox != null) {
			searchBox.text = seededQuery;
			setSearchMode(seededMode);
		}
	}

	/** Select the mode item whose `data` matches `s` (Flash `setSearchMode`). */
	private function setSearchMode(s:String):Void {
		if (modeCb == null) {
			return;
		}
		var option = 0;
		for (i in 0...modeCb.length) {
			if (comboItemData(modeCb.itemAt(i)) == s) {
				option = i;
				break;
			}
		}
		modeCb.selectedIndex = option;
	}

	override private function requestCourses():Void {
		var query = searchBox != null ? searchBox.text : seededQuery;
		var mode = comboData(modeCb, "user");
		var decision = SearchQuery.decide(query, mode, getPageNum(), firstRun);
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
		var order = comboData(orderCb, "");
		var dir = comboData(dirCb, "");
		var params = SearchQuery.buildPost(query, mode, order, dir, getPageNum());
		watchAsync(searchFactory(params, guardCallback(onLoaded), guardCallback(onError)));
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
			StageFocus.reset();
		}
	}

	private function focusStage(_:Event):Void StageFocus.reset();

	/** `selectedItem.data` for a combo, or the fallback when nothing is selected. */
	private static function comboData(combo:Null<GameSelect<Dynamic>>, fallback:String):String {
		if (combo == null) {
			return fallback;
		}
		var data = comboItemData(combo.selectedItem);
		return data == null ? fallback : data;
	}

	private static function comboItemData(item:Dynamic):Null<String> {
		if (item == null || !Reflect.hasField(item, "data")) {
			return null;
		}
		var value = Reflect.field(item, "data");
		return value == null ? "" : Std.string(value);
	}

	private static function selectIndex(combo:Null<GameSelect<Dynamic>>, index:Int):Void {
		if (combo != null && index >= 0 && index < combo.length) {
			combo.selectedIndex = index;
		}
	}

	override private function onPageChanged(n:Int):Void {
		Memory.set("coursePageNumsearch", n);
	}

	private function addComboCloseListener(combo:Null<GameSelect<Dynamic>>):Void {
		if (combo != null) combo.addEventListener(Event.CLOSE, focusStage);
	}

	private function removeComboCloseListener(combo:Null<GameSelect<Dynamic>>):Void {
		if (combo != null) combo.removeEventListener(Event.CLOSE, focusStage);
	}

	override private function onTeardown():Void {
		if (searchBox != null) {
			Memory.set("searchStr", searchBox.text);
			searchBox.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		if (modeCb != null) {
			Memory.set("searchModeIndex", modeCb.selectedIndex);
			removeComboCloseListener(modeCb);
		}
		if (orderCb != null) {
			Memory.set("searchOrderIndex", orderCb.selectedIndex);
			removeComboCloseListener(orderCb);
		}
		if (dirCb != null) {
			Memory.set("searchDirIndex", dirCb.selectedIndex);
			removeComboCloseListener(dirCb);
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
	}

	private static function defaultSearch(params:Map<String, String>, onResult:LevelListResult->Void, onError:String->Void):AsyncRemovable {
		return LevelListClient.search(params, onResult, onError);
	}

	public static function resetHooksForTests():Void {
		searchFactory = defaultSearch;
	}
}

class SearchView extends NativeView {
	public final modeSelect:GameSelect<Dynamic>;
	public final orderSelect:GameSelect<Dynamic>;
	public final directionSelect:GameSelect<Dynamic>;
	public final searchInput:GameTextInput;
	public final searchBox:TextField;
	public final searchButton:GameButton;

	public function new() {
		super();
		label("Search By:", 35.85, 3, 54.95);
		modeSelect = combo("mode_cb", 98.75, 0, 100 * 1.05279541015625);
		var mode = modeSelect;
		mode.addItem({label: "User Name", data: "user"});
		mode.addItem({label: "Level Title", data: "title"});
		mode.addItem({label: "Level ID", data: "id"});
		mode.selectedIndex = 0;
		label("Sort By:", 4, 34, 41.55);
		orderSelect = combo("order_cb", 52.8, 30, 100 * 0.901611328125);
		var order = orderSelect;
		order.addItem({label: "Date", data: "date"});
		order.addItem({label: "Alphabetical", data: "alphabetical"});
		order.addItem({label: "Rating", data: "rating"});
		order.addItem({label: "Popularity", data: "popularity"});
		order.selectedIndex = 0;
		directionSelect = combo("dir_cb", 152.8, 30, 100 * 0.939773559570312);
		var dir = directionSelect;
		dir.addItem({label: "Descending", data: "desc"});
		dir.addItem({label: "Ascending", data: "asc"});
		dir.selectedIndex = 0;
		searchInput = ownControl(new GameTextInput());
		searchInput.name = "searchInput";
		searchInput.x = 10.85;
		searchInput.y = 61;
		searchInput.setSize(100 * 1.420166015625, 22);
		searchInput.maxChars = 50;
		searchBox = searchInput.textField;
		searchBox.name = "searchBox";
		addChild(searchInput);
		searchButton = ownControl(new GameButton("Search"));
		var search = searchButton;
		search.name = "search_bt";
		search.x = 160.8;
		search.y = 61;
		search.setSize(100 * 0.779525756835938, 22);
		addChild(search);
	}

	private function combo(name:String, x:Float, y:Float, width:Float):GameSelect<Dynamic> {
		var control = ownControl(new GameSelect<Dynamic>());
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 22);
		addChild(control);
		return control;
	}

	private function label(value:String, x:Float, y:Float, width:Float):Void {
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = 18;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0x222222, false, null, null, null, null,
			TextFormatAlign.LEFT);
		field.text = value;
		addChild(field);
	}
}
