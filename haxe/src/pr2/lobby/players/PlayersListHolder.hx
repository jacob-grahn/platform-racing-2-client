package pr2.lobby.players;

import openfl.display.DisplayObjectContainer;
import pr2.lobby.players.PlayerListSort.SortState;
import pr2.lobby.players.PlayerListSort.SortableRow;
import pr2.page.Page;
import pr2.ui.view.LoadingView;
import pr2.ui.CustomScrollBar;

/**
	Port of Flash `social.PlayersTabListHolder`: owns the scrolling list of rows,
	the scrollbar, and the loading spinner, plus the sort/relayout that the
	players and guilds lists share. Subclasses supply the list graphic and its
	`listHolder` container, then call `attachHolder` from `initialize()` (Flash did
	this in the constructor; the lifecycle differs here).
**/
class PlayersListHolder extends Page {
	private static inline var LISTING_HEIGHT:Float = 16;

	private var holder:Null<DisplayObjectContainer>;
	private var scrollBar:Null<CustomScrollBar>;
	private var loadingGraphic:Null<LoadingView>;
	private var listings:Array<PlayerListItem> = [];

	private function attachHolder(holder:DisplayObjectContainer):Void {
		this.holder = holder;
		scrollBar = new CustomScrollBar();
		scrollBar.x = 175;
		scrollBar.y = 20;
		scrollBar.init(holder, 330, 325);
		addChild(scrollBar);
		loadingGraphic = new LoadingView();
		loadingGraphic.x = 85;
		loadingGraphic.y = 140;
		addChild(loadingGraphic);
	}

	private function hideLoadingGraphic():Void {
		if (loadingGraphic != null) {
			loadingGraphic.visible = false;
		}
	}

	private function addListing(item:PlayerListItem):Void {
		if (holder == null) {
			return;
		}
		listings.push(item);
		item.y = holder.numChildren * LISTING_HEIGHT;
		holder.addChild(item);
	}

	private function clearListings():Void {
		for (item in listings) {
			item.remove();
		}
		listings = [];
	}

	/** Sort the rows for the given state, then re-stack them vertically. */
	private function applySort(state:SortState, nameMode:String):Void {
		var rows:Array<SortableRow> = cast listings;
		PlayerListSort.apply(rows, state, nameMode);
		for (i in 0...listings.length) {
			listings[i].y = i * LISTING_HEIGHT;
		}
	}

	private function listingSortNamesForTests():Array<String> {
		return [for (item in listings) item.sortName()];
	}

	override public function remove():Void {
		clearListings();
		if (scrollBar != null) {
			scrollBar.remove();
			scrollBar = null;
		}
		if (loadingGraphic != null) {
			loadingGraphic.dispose();
			loadingGraphic = null;
		}
		super.remove();
	}
}
