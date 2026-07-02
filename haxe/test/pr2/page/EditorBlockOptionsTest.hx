package pr2.page;

import pr2.level.BlockType;

class EditorBlockOptionsTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		assertEquals(true, EditorBlockOptions.hasOptions(BlockType.Item), "item blocks expose options");
		assertEquals(true, EditorBlockOptions.hasOptions(BlockType.InfiniteItem), "infinite item blocks expose options");
		assertEquals(true, EditorBlockOptions.hasOptions(BlockType.Teleport), "teleport blocks expose options");
		assertEquals(true, EditorBlockOptions.hasOptions(BlockType.Happy), "happy blocks expose options");
		assertEquals(true, EditorBlockOptions.hasOptions(BlockType.Sad), "sad blocks expose options");
		assertEquals(true, EditorBlockOptions.hasOptions(BlockType.CustomStats), "custom stat blocks expose options");
		assertEquals(false, EditorBlockOptions.hasOptions(BlockType.Brick), "plain blocks do not expose options");

		assertEquals("", EditorBlockOptions.applyItemOptions([4, 1], [1, 4]), "level item defaults save as empty options");
		assertEquals("none", EditorBlockOptions.applyItemOptions([], [1, 4]), "no selected items saves as none");
		assertEquals("1-4-9", EditorBlockOptions.applyItemOptions([9, 4, 4, 1], [1, 2]), "items save sorted and unique");
		assertArrayEquals([1, 4], EditorBlockOptions.selectedItems("", [4, 1]), "empty item options load level defaults");
		assertArrayEquals([], EditorBlockOptions.selectedItems("none", [4, 1]), "none item options load no items");
		assertArrayEquals([1, 9], EditorBlockOptions.selectedItems("9-1", []), "explicit item options load sorted choices");

		assertEquals("", EditorBlockOptions.applyTeleportColor(EditorBlockOptions.TELEPORT_DEFAULT_COLOR), "default teleport color saves empty");
		assertEquals("255", EditorBlockOptions.applyTeleportColor(255), "custom teleport color saves decimal string");
		assertEquals(EditorBlockOptions.TELEPORT_DEFAULT_COLOR, EditorBlockOptions.teleportColor(""), "empty teleport options load default color");
		assertEquals(255, EditorBlockOptions.teleportColor("255"), "custom teleport options load color");

		assertEquals("", EditorBlockOptions.applyStatChange(BlockType.Happy, 2), "happy default-or-less saves empty");
		assertEquals("100", EditorBlockOptions.applyStatChange(BlockType.Happy, 120), "happy stat change clamps high");
		assertEquals("", EditorBlockOptions.applyStatChange(BlockType.Sad, -2), "sad default-or-less saves empty");
		assertEquals("-100", EditorBlockOptions.applyStatChange(BlockType.Sad, -120), "sad stat change clamps low");
		assertEquals(5, EditorBlockOptions.statChange(BlockType.Happy, ""), "happy empty options load default amount");
		assertEquals(-5, EditorBlockOptions.statChange(BlockType.Sad, ""), "sad empty options load default amount");

		assertEquals("", EditorBlockOptions.applyCustomStats(false, 50, 50, 50), "default custom stats save empty");
		assertEquals("reset", EditorBlockOptions.applyCustomStats(true, 10, 20, 30), "custom stat reset saves reset marker");
		assertEquals("0-50-100", EditorBlockOptions.applyCustomStats(false, -5, 50, 140), "custom stats clamp to valid range");
		assertArrayEquals([50, 50, 50], EditorBlockOptions.customStats(""), "empty custom stats load defaults");
		assertArrayEquals([50, 50, 50], EditorBlockOptions.customStats("reset"), "reset custom stats keep slider defaults");
		assertArrayEquals([100, 75, 100], EditorBlockOptions.customStats("105-75-140"), "custom stats load clamped values");

		trace('EditorBlockOptionsTest passed $assertions assertions');
	}

	private static function assertArrayEquals(expected:Array<Int>, actual:Array<Int>, message:String):Void {
		assertions++;
		if (expected.length != actual.length) {
			throw '$message: expected $expected, got $actual';
		}
		for (i in 0...expected.length) {
			if (expected[i] != actual[i]) {
				throw '$message: expected $expected, got $actual';
			}
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
