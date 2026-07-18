package pr2.lobby;

import openfl.display.DisplayObjectContainer;
import openfl.events.MouseEvent;
import openfl.events.TextEvent;
import openfl.text.TextField;
import pr2.lobby.dialogs.CreditsPopup;
import pr2.lobby.dialogs.CreditsView;
import pr2.util.TestDisplayUtil as DisplayUtil;

class CreditsPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var popup = new CreditsPopup();
		var view = findView(popup);
		var art1 = DisplayUtil.findByName(popup, "artPg1");
		var art2 = DisplayUtil.findByName(popup, "artPg2");
		var art3 = DisplayUtil.findByName(popup, "artPg3");
		var music1 = DisplayUtil.findByName(popup, "musicPg1");
		var music2 = DisplayUtil.findByName(popup, "musicPg2");

		assertNotNull(art1, "hidden art page 1 is instantiated");
		if (pr2.DeterministicTestMode.finishSmokeSuite("CreditsPopupTest")) return;
		assertNear(-263.1, view.panel.x, "credits ShadowBG keeps its XFL X");
		assertNear(-175.15, view.panel.y, "credits ShadowBG keeps its XFL Y");
		assertNear(1.95262145996094, view.panel.scaleX, "credits ShadowBG keeps its XFL horizontal scale");
		assertNear(1.83905029296875, view.panel.scaleY, "credits ShadowBG keeps its XFL vertical scale");
		assertNotNull(art2, "hidden art page 2 is instantiated");
		assertNotNull(music1, "hidden music page 1 is instantiated");
		assertEquals(true, art1.visible, "art page 1 starts visible");
		assertEquals(false, art2.visible, "art page 2 starts hidden");
		assertEquals(false, art3.visible, "art page 3 starts hidden");
		assertEquals(true, music1.visible, "music page 1 starts visible");
		assertEquals(false, music2.visible, "music page 2 starts hidden");
		assertNear(105.4, art1.x, "art page 1 keeps its XFL X");
		assertNear(-130.85, art1.y, "art page 1 keeps its XFL Y");
		assertNear(-133.5, music1.x, "music page 1 keeps its XFL X");
		assertNear(-130.85, music1.y, "music page 1 keeps its XFL Y");
		assertContains(allText(cast art1), "Happy/Sad Blocks", "art page 1 uses the exact authored credit copy");
		assertContains(allText(cast art3), "Custom Stats Block", "art page 3 uses the exact authored credit copy");
		assertContains(allText(cast music1), "Orbital Trance", "music page 1 uses the exact authored credit copy");

		var artNav = text(popup, "art_nav_bts");
		assertNear(78.0, artNav.x, "art navigation keeps its authored left bound");
		assertNear(2.0, artNav.y, "art navigation keeps its XFL Y");
		assertNear(-150.25, text(popup, "music_nav_bt").x, "music navigation keeps its XFL X");
		assertNear(60.55, text(popup, "versionBox").x, "version field keeps its authored left bound");
		assertNear(145.0, text(popup, "versionBox").y, "version field keeps its XFL Y");
		assertNear(60.55, text(popup, "buildBox").x, "build field keeps its authored left bound");
		assertNear(153.25, text(popup, "buildBox").y, "build field keeps its XFL Y");
		assertNear(-50.0, view.closeButton.x, "Close keeps its XFL X");
		assertNear(143.0, view.closeButton.y, "Close keeps its XFL Y");
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
		view.closeButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(true, popup.fadeOutStarted, "authored Close button fades credits popup");

		popup.remove();
		trace('CreditsPopupTest passed $assertions assertions');
	}

	private static function findView(popup:CreditsPopup):CreditsView {
		for (index in 0...popup.numChildren) {
			var view = Std.downcast(popup.getChildAt(index), CreditsView);
			if (view != null) return view;
		}
		throw "CreditsView missing";
	}

	private static function allText(container:DisplayObjectContainer):String {
		var value = "";
		for (index in 0...container.numChildren) {
			var child = container.getChildAt(index);
			var field = Std.downcast(child, TextField);
			if (field != null) value += field.text;
			var nested = Std.downcast(child, DisplayObjectContainer);
			if (nested != null) value += allText(nested);
		}
		return value;
	}

	private static function assertContains(value:String, needle:String, message:String):Void {
		assertions++;
		if (value.indexOf(needle) < 0) throw '$message: missing $needle in $value';
	}

	private static function assertNear(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000001) throw '$message: expected $expected, got $actual';
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
