package pr2.lobby;

import openfl.events.MouseEvent;
import pr2.lobby.account.AccountCharacter;

import pr2.lobby.account.AccountCustomizeData;
import pr2.lobby.account.PlayerDisplay;
import pr2.lobby.dialogs.HoverDelayPopup;
import pr2.lobby.tabs.AccountTab;

class AccountTabTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testCharacterGraphicScale();
		testCustomizePayload();
		testHotkeys();
		testHoverDelayPopupCleanup();
		testRandomizeStyleButtonUsesDelayedHover();
		trace('AccountTabTest passed $assertions assertions');
	}

	private static function testCharacterGraphicScale():Void {
		var character = new AccountCharacter();
		assertEquals(1, character.scaleX, "Flash Character wrapper remains at scale 1");
		assertEquals(1, character.display.scaleX, "CharacterGraphic container remains at scale 1");
		var stand = character.display.getStateClip("standAnim");
		assertEquals(0.149993896484375, stand.scaleX, "standAnim preserves its authored internal scaleX");
		assertEquals(0.149993896484375, stand.scaleY, "standAnim preserves its authored internal scaleY");
		character.remove();
	}

	private static function testCustomizePayload():Void {
		var args = ["1", "2", "3", "4", "5", "6", "7", "8", "0,5,9", "1,6", "2,7", "3,8", "40", "50", "60", "21", "2", "4", "11", "12", "13", "14", "5,9", "6", "*", "", "1"];
		var data = AccountCustomizeData.parse(args);
		assertEquals(5, data.hat, "hat");
		assertEquals(3, data.hats.length, "owned hats");
		assertEquals(21, data.rank, "rank");
		assertEquals(14, data.feetColor2, "secondary feet color");
		assertEquals("*", data.epicBodies[0], "epic bodies");
		assertEquals(true, data.happyHour, "happy hour");
		assertEquals(null, AccountCustomizeData.parse(["short"]), "short payload rejected");
	}

	private static function testHotkeys():Void {
		assertEquals(1, AccountTab.keyToSlot(49), "number one");
		assertEquals(10, AccountTab.keyToSlot(48), "number zero");
		assertEquals(5, AccountTab.keyToSlot(101), "numpad five");
		assertEquals(-1, AccountTab.keyToSlot(65), "non-number");
	}

	private static function testHoverDelayPopupCleanup():Void {
		var wrapper = new HoverDelayPopup("Title", "Body", 500);
		@:privateAccess wrapper.showPopup();
		assertNotNull(wrapper.hover, "direct show creates delayed hover popup");
		wrapper.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertEquals(null, wrapper.hover, "mouse down hides shown hover popup");
		@:privateAccess wrapper.showPopup();
		wrapper.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals(null, wrapper.hover, "mouse out hides shown hover popup");
		@:privateAccess wrapper.showPopup();
		wrapper.remove();
		assertEquals(null, wrapper.hover, "remove cleans shown hover popup");
	}

	private static function testRandomizeStyleButtonUsesDelayedHover():Void {
		var character = new AccountCharacter();
		var display = new PlayerDisplay(character, ["1", "2"], ["1", "2"], ["1", "2"], ["1", "2"], 1, 1, 1, 1, 0, 0, 0, 0,
			["1"], ["1"], ["1"], ["1"], 0, 0, 0, 0);
		var button = @:privateAccess display.randomButton;
		assertNotNull(button, "player display mounts randomize button");
		assertEquals("Randomize Style", button.title, "randomize button hover title");
		assertEquals("Create a random style for your character. Remember to save your current style if you like it first!", button.content,
			"randomize button hover copy");
		display.remove();
		character.remove();
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) throw '$message: value was null';
	}
}
