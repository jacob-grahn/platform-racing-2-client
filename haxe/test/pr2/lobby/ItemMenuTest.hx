package pr2.lobby;

import openfl.display.Sprite;
import pr2.gameplay.Items;
import pr2.lobby.dialogs.ItemMenu;

class ItemMenuTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testAllAndBlankParsing();
		testNumericAndNamedParsing();
		trace('ItemMenuTest passed $assertions assertions');
	}

	private static function testAllAndBlankParsing():Void {
		var allMenu = new ItemMenu("all", new Sprite());
		for (itemId in Items.getAllCodes()) {
			assertEquals(true, allMenu.isItemSelected(itemId), 'all selects item $itemId');
			assertEquals(false, allMenu.isItemEnabled(itemId), 'all disables item $itemId');
		}
		allMenu.remove();

		var nullMenu = new ItemMenu(null, new Sprite());
		assertEquals(true, nullMenu.isItemSelected(Items.LASER_GUN), "null selects all items");
		nullMenu.remove();

		var blankMenu = new ItemMenu("", new Sprite());
		for (itemId in Items.getAllCodes()) {
			assertEquals(false, blankMenu.isItemSelected(itemId), 'blank leaves item $itemId unchecked');
			assertEquals(false, blankMenu.isItemEnabled(itemId), 'blank disables item $itemId');
		}
		blankMenu.remove();
	}

	private static function testNumericAndNamedParsing():Void {
		var menu = new ItemMenu("1`Mine`8`Ice Wave`10`Unknown`0", new Sprite());
		assertEquals(true, menu.isItemSelected(Items.LASER_GUN), "single-character numeric item code selects laser");
		assertEquals(true, menu.isItemSelected(Items.MINE), "named item selects mine");
		assertEquals(true, menu.isItemSelected(Items.SWORD), "single-character numeric item code selects sword");
		assertEquals(true, menu.isItemSelected(Items.ICE_WAVE), "multi-word named item selects ice wave");
		assertEquals(false, menu.isItemSelected(Items.TELEPORT), "unmentioned item remains unchecked");
		assertEquals(false, menu.isItemSelected(10), "two-character numeric text is parsed as a name and ignored");
		menu.remove();
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
