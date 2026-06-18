package pr2.lobby.level;

/**
	Shared state the active level listing exposes to its `LevelItem`s, mirroring
	Flash's `LevelListing.levelListing.getPageNum()` global reach. The listing page
	keeps `currentPageNum` updated so a slot fill can report the page it was joined
	from (`fill_slot`...`pageNum`).
**/
class LevelListingState {
	public static var currentPageNum:Int = 1;

	private function new() {}
}
