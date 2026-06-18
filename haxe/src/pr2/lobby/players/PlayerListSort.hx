package pr2.lobby.players;

/** A row the players/guilds list can sort: numeric columns plus a tiebreak name. */
interface SortableRow {
	function numericField(key:String):Float;
	function sortName():String;
}

/** The sort mode/order a header click resolves to. */
typedef SortState = {
	var mode:String;
	var order:String;
};

/**
	Pure port of the sort behavior shared by Flash `social.PlayersTabList` and
	`social.Guilds` (via `PlayersTabListHolder.numSort` / `doNumSort`).

	Clicking a numeric header sorts descending by that column with the other
	numeric column as a tiebreak, then a case-insensitive name compare; clicking
	the name header sorts ascending. Re-clicking the active header toggles the
	order. Factored out so the comparator and the header state machine are
	unit-testable without real list art.
**/
class PlayerListSort {
	private function new() {}

	/**
		Resolve the next sort state from a header click, matching `sortPlayersBy` /
		`sortGuildsBy`. `nameMode` is the column that sorts ascending by name (e.g.
		`userName` or `guildName`); every other column sorts descending first and
		toggles on re-click. A null `newMode` re-applies the current mode unchanged.
	**/
	public static function nextSort(current:SortState, newMode:Null<String>, nameMode:String):SortState {
		if (newMode != current.mode || newMode == null) {
			var mode = newMode != null ? newMode : current.mode;
			var order = mode == nameMode ? "asc" : "desc";
			return {mode: mode, order: order};
		}
		// Re-clicking the active header toggles the order.
		return {mode: current.mode, order: current.order == "desc" ? "asc" : "desc"};
	}

	/** The tiebreak numeric column for a primary numeric column, per the originals. */
	public static function tiebreak(mode:String):String {
		return switch (mode) {
			case "rank": "hats";
			case "hats": "rank";
			case "gpToday": "activeMembers";
			case "activeMembers": "gpToday";
			default: mode;
		};
	}

	/**
		Sort `rows` in place for the given state. Name mode is a case-insensitive
		string compare (ascending, or descending when toggled); numeric modes sort
		by the column then its tiebreak then the name, honoring the order.
	**/
	public static function apply(rows:Array<SortableRow>, state:SortState, nameMode:String):Void {
		if (state.mode == nameMode) {
			rows.sort(function(a, b) {
				var an = a.sortName().toLowerCase();
				var bn = b.sortName().toLowerCase();
				var cmp = an < bn ? -1 : (an > bn ? 1 : 0);
				return state.order == "asc" ? cmp : -cmp;
			});
			return;
		}
		var key1 = state.mode;
		var key2 = tiebreak(state.mode);
		rows.sort(function(a, b) {
			return compareNumeric(a, b, key1, key2, state.order);
		});
	}

	/** Faithful port of `PlayersTabListHolder.doNumSort` for two numeric keys. */
	public static function compareNumeric(a:SortableRow, b:SortableRow, key1:String, key2:String, order:String):Int {
		var a1 = a.numericField(key1);
		var b1 = b.numericField(key1);
		var a2 = a.numericField(key2);
		var b2 = b.numericField(key2);
		if (order == "desc") {
			if (a1 != b1) {
				return a1 > b1 ? -1 : 1;
			}
			if (a2 != b2) {
				return a2 > b2 ? -1 : 1;
			}
			return strcmp(a.sortName().toLowerCase(), b.sortName().toLowerCase());
		}
		// ascending
		if (a1 != b1) {
			return a1 > b1 ? 1 : -1;
		}
		if (a2 != b2) {
			return a2 > b2 ? 1 : -1;
		}
		return strcmp(b.sortName().toLowerCase(), a.sortName().toLowerCase());
	}

	private static function strcmp(a:String, b:String):Int {
		return a < b ? -1 : (a > b ? 1 : 0);
	}
}
