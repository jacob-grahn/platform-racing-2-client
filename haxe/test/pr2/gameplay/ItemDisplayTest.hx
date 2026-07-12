package pr2.gameplay;

class ItemDisplayTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testItemNames();
		testAuthoredDisplayState();
		trace('ItemDisplayTest passed $assertions assertions');
	}

	private static function testItemNames():Void {
		var expected = [
			"None",
			"Laser",
			"Mine",
			"Lightning",
			"Teleport",
			"Super Jump",
			"Jet Pack",
			"Speed Burst",
			"Sword",
			"Ice Wave",
			"Snake"
		];
		for (code in 0...expected.length) {
			assertEquals(expected[code], ItemDisplay.itemNameFromCode(code), 'item code $code name');
		}
		assertEquals("None", ItemDisplay.itemNameFromCode(99), "unknown item name");
	}

	private static function testAuthoredDisplayState():Void {
		var display = new ItemDisplay();
		assertEquals("None", display.itemName, "display starts empty");
		assertEquals("None", display.labelText("holder1"), "dark label starts empty");
		assertEquals("None", display.labelText("holder2"), "light label starts empty");
		assertEquals(false, display.ammoVisible(1), "empty display hides ammo");

		display.setItemCode(1);
		display.setAmmo(3);
		assertEquals("Laser", display.itemName, "laser frame selected");
		assertEquals("Laser", display.labelText("holder1"), "dark label updates");
		assertEquals("Laser", display.labelText("holder2"), "light label updates");
		assertEquals(true, display.ammoVisible(1), "first ammo dot visible");
		assertEquals(true, display.ammoVisible(2), "second ammo dot visible");
		assertEquals(true, display.ammoVisible(3), "third ammo dot visible");

		display.setAmmo(1);
		assertEquals(true, display.ammoVisible(1), "one ammo keeps first dot");
		assertEquals(false, display.ammoVisible(2), "one ammo hides second dot");
		assertEquals(false, display.ammoVisible(3), "one ammo hides third dot");
		assertEquals(3, ItemDisplay.clampAmmo(8), "ammo clamps to authored dots");
		assertEquals(0, ItemDisplay.clampAmmo(-1), "ammo clamps at zero");
		display.remove();
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
