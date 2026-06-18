package pr2.lobby.messages;

/**
	Pure paging arithmetic for the PMs tab, extracted from Flash `chat.Messages`
	so it can be unit-tested without a display list. The original requests
	`start = (currentPage - 1) * itemsPerPage` with `count = itemsPerPage`.
**/
final class MessagesPaging {
	public static inline var ITEMS_PER_PAGE:Int = 10;

	private function new() {}

	/** Zero-based index of the first message on `page` (1-based, clamped to >= 1). */
	public static function startIndex(page:Int, itemsPerPage:Int = ITEMS_PER_PAGE):Int {
		var p = page < 1 ? 1 : page;
		return (p - 1) * itemsPerPage;
	}
}
