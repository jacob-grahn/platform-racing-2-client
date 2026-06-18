package pr2.lobby.search;

import pr2.lobby.chat.ChatText;

/** What `Search.requestCourses` decides to do for the current inputs. */
enum SearchDecision {
	/** Blank query, or an id search past page 1 after the first run: send nothing. */
	Skip;
	/** An id search initialized on a page > 1: snap back to page 1 first. */
	ResetToFirstPage;
	/** Inputs are valid: POST the search. */
	Send;
}

/**
	Pure port of the request guards and parameter building in Flash
	`level_browser.Search.requestCourses`, separated from the (still-being-ported)
	combo-box UI so the behavior is unit-testable.

	A blank query sends nothing. Searching by level id only makes sense on page 1,
	so an id search past page 1 either snaps back to page 1 (on the first run) or
	is ignored. Otherwise the search posts `search_str`, `mode`, `order`, `dir`,
	and `page` to `search_levels.php`.
**/
class SearchQuery {
	private function new() {}

	public static function decide(searchStr:String, modeData:String, pageNum:Int, firstRun:Bool):SearchDecision {
		if (ChatText.trimWhitespace(searchStr, false) == "") {
			return Skip;
		}
		if (modeData == "id" && pageNum > 1) {
			return firstRun ? ResetToFirstPage : Skip;
		}
		return Send;
	}

	public static function buildPost(searchStr:String, mode:String, order:String, dir:String, page:Int):Map<String, String> {
		var vars = new Map<String, String>();
		vars.set("search_str", searchStr);
		if (mode != null) {
			vars.set("mode", mode);
		}
		if (order != null) {
			vars.set("order", order);
		}
		if (dir != null) {
			vars.set("dir", dir);
		}
		vars.set("page", Std.string(page));
		return vars;
	}
}
