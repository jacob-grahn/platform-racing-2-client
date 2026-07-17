package pr2.lobby.players;

import openfl.display.DisplayObjectContainer;
import openfl.events.MouseEvent;
import openfl.events.TimerEvent;
import openfl.utils.Timer;
import pr2.lobby.LobbyArt;
import pr2.lobby.players.PlayerListSort.SortState;
import pr2.util.DisplayUtil;

/**
	Port of Flash `social.PlayersTabList`: the Online/Friends/Following/Ignored
	list with Name / Rank / Hats sortable headers. New rows set a pending sort
	flag and are sorted on Flash's 500ms interval; clicking a header re-sorts
	immediately via `PlayerListSort`. Live rows are supplied by subclasses
	through `addUserEntry`.
**/
class PlayersTabList extends PlayersListHolder {
	private static inline var NAME_MODE:String = "userName";

	private var graphic:Null<PlayersTabListView>;
	private var nameButton:Null<DisplayObjectContainer>;
	private var rankButton:Null<DisplayObjectContainer>;
	private var hatsButton:Null<DisplayObjectContainer>;
	private var sortState:SortState = {mode: "rank", order: "desc"};
	private var names:Array<String> = [];
	private var sortTimer:Null<Timer>;
	private var updateSort:Bool = false;

	override public function initialize():Void {
		graphic = new PlayersTabListView(false);
		addChild(graphic);
		var listHolder = Std.downcast(DisplayUtil.findByName(graphic, "listHolder"), DisplayObjectContainer);
		if (listHolder != null) {
			attachHolder(listHolder);
		}
		nameButton = Std.downcast(DisplayUtil.findByName(graphic, "name_bt"), DisplayObjectContainer);
		rankButton = Std.downcast(DisplayUtil.findByName(graphic, "rank_bt"), DisplayObjectContainer);
		hatsButton = Std.downcast(DisplayUtil.findByName(graphic, "hats_bt"), DisplayObjectContainer);
		if (nameButton != null) {
			nameButton.addEventListener(MouseEvent.CLICK, clickName);
		}
		if (rankButton != null) {
			rankButton.addEventListener(MouseEvent.CLICK, clickRank);
		}
		if (hatsButton != null) {
			hatsButton.addEventListener(MouseEvent.CLICK, clickHats);
		}
		sortTimer = new Timer(500);
		sortTimer.addEventListener(TimerEvent.TIMER, sortListener);
		sortTimer.start();
	}

	private function addUserEntry(name:String, group:String, rank:Int, hats:Int, status:String = ""):Void {
		if (names.indexOf(name) > -1) {
			return; // refuse duplicates, matching the original
		}
		names.push(name);
		addListing(new PlayerEntry(name, group, rank, hats, status));
		updateSort = true;
	}

	private function sortListener(?_:TimerEvent):Void {
		if (updateSort) {
			updateSort = false;
			applySort(sortState, NAME_MODE);
		}
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
		if (sortTimer != null) {
			sortTimer.stop();
			sortTimer.removeEventListener(TimerEvent.TIMER, sortListener);
			sortTimer = null;
		}
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
