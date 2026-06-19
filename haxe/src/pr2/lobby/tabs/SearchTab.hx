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
import pr2.runtime.FlComboBox;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `level_browser.Search`.

	Renders the real `SearchGraphic` (search box, button, and the mode/order/
	direction dropdowns) and runs searches through `LevelListingPage`: the request
	guards and POST parameters come from the pure `SearchQuery`, results POST to
	`search_levels.php` and render in the shared three-column grid. The mode/order/
	direction `FlComboBox` dropdowns supply `selectedItem.data`, and the search box
	text plus the three combo `selectedIndex` values are persisted to `Memory`
	(`searchStr` / `searchModeIndex` / `searchOrderIndex` / `searchDirIndex`) and
	restored on re-entry, mirroring the original. Seeded lookups
	(`LobbyRight.lookupUser` / `lookupLevel`) preselect the matching mode and run
	immediately.
**/
class SearchTab extends LevelListingPage {
	private var art:PR2MovieClip;
	private var searchBox:Null<TextField>;
	private var searchButton:Null<openfl.display.DisplayObject>;
	private var searchBinding:Null<LobbyArt.Binding>;

	private var modeCb:Null<FlComboBox>;
	private var orderCb:Null<FlComboBox>;
	private var dirCb:Null<FlComboBox>;

	private var seededQuery:String;
	private var seededMode:String;
	private var firstRun:Bool = true;

	public function new(?query:String, ?searchMode:String) {
		super("search", 1);
		this.seededQuery = query != null ? query : "";
		this.seededMode = searchMode != null ? searchMode : "user";
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
		}

		modeCb = Std.downcast(LobbyArt.findByName(art, "mode_cb"), FlComboBox);
		orderCb = Std.downcast(LobbyArt.findByName(art, "order_cb"), FlComboBox);
		dirCb = Std.downcast(LobbyArt.findByName(art, "dir_cb"), FlComboBox);

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
			if (comboItemData(modeCb.dataProvider.getItemAt(i)) == s) {
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

	/** `selectedItem.data` for a combo, or the fallback when nothing is selected. */
	private static function comboData(combo:Null<FlComboBox>, fallback:String):String {
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

	private static function selectIndex(combo:Null<FlComboBox>, index:Int):Void {
		if (combo != null && index >= 0 && index < combo.length) {
			combo.selectedIndex = index;
		}
	}

	override private function onTeardown():Void {
		if (searchBox != null) {
			Memory.set("searchStr", searchBox.text);
			searchBox.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		if (modeCb != null) {
			Memory.set("searchModeIndex", modeCb.selectedIndex);
		}
		if (orderCb != null) {
			Memory.set("searchOrderIndex", orderCb.selectedIndex);
		}
		if (dirCb != null) {
			Memory.set("searchDirIndex", dirCb.selectedIndex);
		}
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
