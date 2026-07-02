package pr2.lobby;

import openfl.events.TextEvent;
import openfl.text.TextField;
import pr2.Constants;
import pr2.lobby.dialogs.CreditsPopup;
import pr2.util.DisplayUtil;

class CreditsPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var popup = new CreditsPopup();
		var art1 = DisplayUtil.findByName(popup, "artPg1");
		var art2 = DisplayUtil.findByName(popup, "artPg2");
		var art3 = DisplayUtil.findByName(popup, "artPg3");
		var music1 = DisplayUtil.findByName(popup, "musicPg1");
		var music2 = DisplayUtil.findByName(popup, "musicPg2");

		assertNotNull(art1, "hidden art page 1 is instantiated");
		assertNotNull(art2, "hidden art page 2 is instantiated");
		assertNotNull(music1, "hidden music page 1 is instantiated");
		assertEquals(true, art1.visible, "art page 1 starts visible");
		assertEquals(false, art2.visible, "art page 2 starts hidden");
		assertEquals(false, art3.visible, "art page 3 starts hidden");
		assertEquals(true, music1.visible, "music page 1 starts visible");
		assertEquals(false, music2.visible, "music page 2 starts hidden");

		var version = text(popup, "versionBox");
		var build = text(popup, "buildBox");
		assertEquals("PR2 v" + Constants.VERSION, version.text, "version text matches client version");
		assertEquals("Build: " + Constants.BUILD, build.text, "build text matches client build");

		var artNav = text(popup, "art_nav_bts");
		artNav.dispatchEvent(new TextEvent(TextEvent.LINK, false, false, "artNext"));
		assertEquals(2, popup.artPage, "art next advances the page");
		assertEquals(false, art1.visible, "old art page is hidden");
		assertEquals(true, art2.visible, "next art page is shown");
		artNav.dispatchEvent(new TextEvent(TextEvent.LINK, false, false, "artBack"));
		assertEquals(1, popup.artPage, "art back returns to the first page");

		var musicNav = text(popup, "music_nav_bt");
		musicNav.dispatchEvent(new TextEvent(TextEvent.LINK, false, false, "musicToggle"));
		assertEquals(2, popup.musicPage, "music link toggles the page");
		assertEquals(false, music1.visible, "old music page is hidden");
		assertEquals(true, music2.visible, "next music page is shown");

		popup.remove();
		trace('CreditsPopupTest passed $assertions assertions');
	}

	private static function text(popup:CreditsPopup, name:String):TextField {
		var field = Std.downcast(DisplayUtil.findByName(popup, name), TextField);
		assertNotNull(field, name + " is a dynamic text field");
		return field;
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
