package pr2.lobby;

import openfl.display.DisplayObject;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.lobby.account.Preset.Outfit;
import pr2.lobby.dialogs.OutfitPopup;
import pr2.util.DisplayUtil;

class OutfitPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testMessagePreviewStatsAndOk();
		testStatsHiddenLayoutAndCancel();
		testSingletonReplacement();
		trace('OutfitPopupTest passed $assertions assertions');
	}

	private static function testMessagePreviewStatsAndOk():Void {
		var confirmed = 0;
		var popup = new OutfitPopup(function():Void confirmed++, {
			hat: 3,
			head: 20,
			body: 17,
			feet: 16,
			hatColor: 0x990000,
			headColor: 0x112233,
			bodyColor: 0x445566,
			feetColor: 0x778899,
			hatColor2: -1,
			headColor2: -1,
			bodyColor2: -1,
			feetColor2: -1,
			speed: 42,
			acceleration: 51,
			jumping: 60
		}, "Use <b>this</b> outfit?");

		assertEquals(popup, OutfitPopup.instance, "new outfit popup becomes the singleton");
		assertContains(text(popup, "textBox").htmlText, "this", "message is applied as HTML text");
		assertEquals(3, popup.preview.hat1, "preview hat id");
		assertEquals(20, popup.preview.head, "preview head id");
		assertEquals(0x990000, popup.preview.hat1Color, "preview hat color");
		assertEquals(0x112233, popup.preview.headColor, "preview head color");
		assertEquals(0x445566, popup.preview.bodyColor, "preview body color");
		assertEquals(0x778899, popup.preview.feetColor, "preview feet color");
		assertEquals("Speed:42", text(popup, "speedBox").text, "speed stat is appended");
		assertEquals("Acceleration:51", text(popup, "accelBox").text, "acceleration stat is appended");
		assertEquals("Jumping:60", text(popup, "jumpnBox").text, "jumping stat is appended");

		click(popup, "ok_bt");
		assertEquals(1, confirmed, "OK runs the confirm callback once");
		assertEquals(true, popup.fadeOutStarted, "OK starts fade-out");
		popup.remove();
		assertEquals(null, OutfitPopup.instance, "remove clears singleton");
	}

	private static function testStatsHiddenLayoutAndCancel():Void {
		var confirmed = false;
		var popup = new OutfitPopup(function():Void confirmed = true, {
			hats: [3, 1, 1, 1],
			head: 20,
			body: 17,
			feet: 16,
			hatColor: 0x990000,
			headColor: 0x990000,
			bodyColor: 0x990000,
			feetColor: 0x990000,
			hatColor2: -1,
			headColor2: -1,
			bodyColor2: -1,
			feetColor2: -1
		}, "Kong outfit?");

		assertEquals(3, popup.preview.hat1, "Flash-style hats array drives the preview hat");
		assertEquals(40.3, popup.preview.y, "preview shifts down when stats are hidden");
		assertEquals(false, target(popup, "speedBox").visible, "speed label hidden without stats");
		assertEquals(false, target(popup, "accelBox").visible, "acceleration label hidden without stats");
		assertEquals(false, target(popup, "jumpnBox").visible, "jumping label hidden without stats");
		assertEquals(false, target(popup, "statsBg").visible, "stats background hidden without stats");

		click(popup, "cancel_bt");
		assertEquals(false, confirmed, "Cancel does not run confirm callback");
		assertEquals(true, popup.fadeOutStarted, "Cancel starts fade-out");
		popup.remove();
	}

	private static function testSingletonReplacement():Void {
		var first = new OutfitPopup(function():Void {}, baseOutfit(), "First");
		var second = new OutfitPopup(function():Void {}, baseOutfit(), "Second");
		assertEquals(true, first.fadeOutStarted, "new outfit popup fades out the previous singleton");
		assertEquals(second, OutfitPopup.instance, "replacement becomes singleton");
		first.remove();
		second.remove();
	}

	private static function baseOutfit():Outfit {
		return {
			hat: 1,
			head: 1,
			body: 1,
			feet: 1,
			hatColor: 0,
			headColor: 0,
			bodyColor: 0,
			feetColor: 0,
			hatColor2: -1,
			headColor2: -1,
			bodyColor2: -1,
			feetColor2: -1
		};
	}

	private static function click(popup:OutfitPopup, name:String):Void {
		target(popup, name).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	}

	private static function text(popup:OutfitPopup, name:String):TextField {
		var field = LobbyArt.text(popup, name);
		if (field == null) throw name + " text missing";
		return field;
	}

	private static function target(popup:OutfitPopup, name:String):DisplayObject {
		var found = DisplayUtil.findByName(popup, name);
		if (found == null) throw name + " missing";
		return found;
	}

	private static function assertContains(value:String, needle:String, message:String):Void {
		assertions++;
		if (value.indexOf(needle) == -1) throw '$message: expected "$value" to contain "$needle"';
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
