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
