package pr2.lobby;

import pr2.lobby.account.AccountCustomizeData;
import pr2.lobby.tabs.AccountTab;

class AccountTabTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testCustomizePayload();
		testHotkeys();
		trace('AccountTabTest passed $assertions assertions');
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

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
