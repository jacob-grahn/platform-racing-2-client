package pr2.lobby.players;

import openfl.display.DisplayObjectContainer;
import openfl.events.MouseEvent;
import pr2.lobby.LobbyArt;
import pr2.lobby.players.PlayerListSort.SortState;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `social.PlayersTabList`: the Online/Friends/Following/Ignored
	list with Name / Rank / Hats sortable headers. New rows default to a
	descending rank sort; clicking a header re-sorts via `PlayerListSort`. Live
	rows are supplied by subclasses through `addUserEntry`.
**/
class PlayersTabList extends PlayersListHolder {
	private static inline var NAME_MODE:String = "userName";

	private var graphic:Null<PR2MovieClip>;
	private var nameButton:Null<DisplayObjectContainer>;
	private var rankButton:Null<DisplayObjectContainer>;
	private var hatsButton:Null<DisplayObjectContainer>;
	private var sortState:SortState = {mode: "rank", order: "desc"};
	private var names:Array<String> = [];

	override public function initialize():Void {
		graphic = PR2MovieClip.fromLinkage("PlayersTabListGraphic", {maxNestedDepth: 6});
		addChild(graphic);
		var listHolder = Std.downcast(LobbyArt.findByName(graphic, "listHolder"), DisplayObjectContainer);
		if (listHolder != null) {
			attachHolder(listHolder);
		}
		nameButton = Std.downcast(LobbyArt.findByName(graphic, "name_bt"), DisplayObjectContainer);
		rankButton = Std.downcast(LobbyArt.findByName(graphic, "rank_bt"), DisplayObjectContainer);
		hatsButton = Std.downcast(LobbyArt.findByName(graphic, "hats_bt"), DisplayObjectContainer);
		if (nameButton != null) {
			nameButton.addEventListener(MouseEvent.CLICK, clickName);
		}
		if (rankButton != null) {
			rankButton.addEventListener(MouseEvent.CLICK, clickRank);
		}
		if (hatsButton != null) {
			hatsButton.addEventListener(MouseEvent.CLICK, clickHats);
		}
	}

	private function addUserEntry(name:String, group:String, rank:Int, hats:Int, status:String = ""):Void {
		if (names.indexOf(name) > -1) {
			return; // refuse duplicates, matching the original
		}
		names.push(name);
		addListing(new PlayerEntry(name, group, rank, hats, status));
		applySort(sortState, NAME_MODE);
	}

	private function clickName(_:MouseEvent):Void {
		setSort("userName");
	}

	private function clickRank(_:MouseEvent):Void {
		setSort("rank");
	}

	private function clickHats(_:MouseEvent):Void {
		setSort("hats");
	}

	private function setSort(newMode:String):Void {
		sortState = PlayerListSort.nextSort(sortState, newMode, NAME_MODE);
		applySort(sortState, NAME_MODE);
	}

	override public function remove():Void {
		if (nameButton != null) {
			nameButton.removeEventListener(MouseEvent.CLICK, clickName);
		}
		if (rankButton != null) {
			rankButton.removeEventListener(MouseEvent.CLICK, clickRank);
		}
		if (hatsButton != null) {
			hatsButton.removeEventListener(MouseEvent.CLICK, clickHats);
		}
		if (graphic != null) {
			graphic.dispose();
			graphic = null;
		}
		super.remove();
	}
}
