package pr2.lobby;

import pr2.lobby.dialogs.LevelInfoPopup;
import pr2.lobby.dialogs.Popup;

/**
	Locks the first ported LevelInfoPopup boundary: level links open the authored
	shell, preserve the loading state, and no longer mutate `LobbyPopups.lastRequest`.
**/
class LevelInfoPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testLinkRouteOpensAuthoredShell();
		testApplyReturnDataPopulatesAuthoredFields();
		testSingletonFadeOut();
		closeAll();
		trace('LevelInfoPopupTest passed $assertions assertions');
	}

	private static function testLinkRouteOpensAuthoredShell():Void {
		closeAll();
		LobbyPopups.lastRequest = "sentinel";
		LobbyPopups.showLevel("12345");
		var popup = Std.downcast(Popup.getOpen()[Popup.getOpen().length - 1], LevelInfoPopup);
		assertNotNull(popup, "showLevel opens LevelInfoPopup");
		assertEquals(12345, popup.levelId, "level id parsed");
		assertEquals("sentinel", LobbyPopups.lastRequest, "level route is no longer record-only");
		assertEquals(true, LobbyArt.findByName(popup, "loading").visible, "loading graphic remains visible");
		assertEquals(false, LobbyArt.findByName(popup, "levelInfo").visible, "data panel stays hidden until data port lands");
		popup.remove();
	}

	private static function testApplyReturnDataPopulatesAuthoredFields():Void {
		closeAll();
		var popup = new LevelInfoPopup(77);
		popup.applyReturnData({
			title: "Hat Factory",
			note: "Find the hidden hat.",
			version: 12345,
			play_count: 987654,
			min_rank: 15,
			user_name: "Jiggmin",
			user_group: "2,1",
			rating: 3.75,
			time: 1605484800,
			song: "2",
			gameMode: "hat"
		});
		assertEquals(false, LobbyArt.findByName(popup, "loading").visible, "loading graphic hides after data");
		assertEquals(true, LobbyArt.findByName(popup, "levelInfo").visible, "data panel shows after data");
		assertEquals("Hat Factory", LobbyArt.text(popup, "title").text, "title populates");
		assertEquals("Find the hidden hat.", LobbyArt.text(popup, "note").text, "note populates");
		assertEquals("12,345", LobbyArt.text(popup, "version").text, "version is comma-formatted");
		assertEquals("987,654", LobbyArt.text(popup, "plays").text, "plays is comma-formatted");
		assertEquals("15", LobbyArt.text(popup, "minRank").text, "min rank populates");
		assertEquals("15/Nov/2020", LobbyArt.text(popup, "updated").text, "updated uses Flash short date");
		assertEquals("Hat Attack", popup.gameMode, "game mode is normalized");
		assertEquals("Code - Stefano Maccarelli", popup.song, "song id is named");
		assertEquals(0.75, LobbyArt.findByName(popup, "bar").scaleX, "rating star bar scales");
		popup.remove();
	}

	private static function testSingletonFadeOut():Void {
		closeAll();
		var first = new LevelInfoPopup(1);
		var second = new LevelInfoPopup(2);
		assertEquals(true, first.fadeOutStarted, "opening another level info popup fades the previous instance");
		assertEquals(second, LevelInfoPopup.instance, "new popup becomes singleton instance");
		second.remove();
		first.remove();
	}

	private static function closeAll():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) throw message;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
