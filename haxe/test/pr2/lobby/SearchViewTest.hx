package pr2.lobby;

import pr2.lobby.tabs.SearchTab.SearchView;

class SearchViewTest {
	private static var assertions = 0;

	public static function main():Void {
		var view = new SearchView();
		assertClose(98.75, view.modeSelect.x, "search mode keeps XFL X");
		if (pr2.DeterministicTestMode.finishSmokeSuite("SearchViewTest")) return;
		assertClose(100 * 1.05279541015625, view.modeSelect.controlWidth, "search mode keeps XFL width");
		assertClose(52.8, view.orderSelect.x, "search order keeps XFL X");
		assertClose(30, view.orderSelect.y, "search order keeps XFL Y");
		assertClose(100 * 0.901611328125, view.orderSelect.controlWidth, "search order keeps XFL width");
		assertClose(152.8, view.directionSelect.x, "search direction keeps XFL X");
		assertClose(30, view.directionSelect.y, "search direction keeps XFL Y");
		assertClose(100 * 0.939773559570312, view.directionSelect.controlWidth, "search direction keeps XFL width");
		assertClose(10.85, view.searchInput.x, "search input keeps XFL X");
		assertClose(61, view.searchInput.y, "search input keeps XFL Y");
		assertClose(100 * 1.420166015625, view.searchInput.controlWidth, "search input keeps XFL width");
		assertEquals(50, view.searchInput.maxChars, "search input keeps XFL maximum");
		assertClose(160.8, view.searchButton.x, "search button keeps XFL X");
		assertClose(61, view.searchButton.y, "search button keeps XFL Y");
		assertClose(100 * 0.779525756835938, view.searchButton.controlWidth, "search button keeps XFL width");
		assertEquals("User Name", Reflect.field(view.modeSelect.itemAt(0), "label"), "search mode preserves XFL order");
		assertEquals("Popularity", Reflect.field(view.orderSelect.itemAt(3), "label"), "search order preserves XFL order");
		assertEquals("Ascending", Reflect.field(view.directionSelect.itemAt(1), "label"), "search direction preserves XFL order");
		view.dispose();
		trace('SearchViewTest passed $assertions assertions');
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000001) throw '$message: expected $expected, got $actual';
	}
}
