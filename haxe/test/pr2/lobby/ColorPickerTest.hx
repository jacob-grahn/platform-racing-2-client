package pr2.lobby;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.lobby.account.ColorChoices;
import pr2.lobby.account.ColorPicker;

class ColorPickerTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testColorChoicesPalette();
		testColorPickerEventsAndRecents();
		testPopupOrientationAndDirection();
		trace('ColorPickerTest passed $assertions assertions');
	}

	private static function testColorChoicesPalette():Void {
		resetRecents();
		var grid = ColorChoices.populate(ColorPicker.recentColors);
		assertEquals(22, grid.length, "palette column count");
		assertEquals(12, grid[0].length, "palette row count");
		assertEquals(0x888888, grid[0][0], "recent first color");
		assertEquals(0x555555, grid[0][1], "recent second color");
		assertEquals(0x000000, grid[2][0], "suggested black");
		assertEquals(0xFFFFFF, grid[2][5], "suggested white");
		assertEquals(0xFF0000, grid[2][6], "suggested red");
		assertEquals(0x00FF00, grid[2][7], "suggested green");
		assertEquals(0x0000FF, grid[2][8], "suggested blue");
		assertEquals(0x000000, grid[4][0], "RGB cube first red block");
		assertEquals(0x00FFFF, grid[9][5], "RGB cube blue/green orientation");
		assertEquals(0x990000, grid[4][6], "RGB cube wraps red blocks down rows");
	}

	private static function testColorPickerEventsAndRecents():Void {
		resetRecents();
		var picker = new ColorPicker();
		assertEquals(0x0000FF, picker.getColor(), "default Flash picker color");
		var changes = 0;
		var opens = 0;
		var closes = 0;
		picker.addEventListener(Event.CHANGE, function(_:Event):Void changes++);
		picker.addEventListener(Event.OPEN, function(_:Event):Void opens++);
		picker.addEventListener(Event.CLOSE, function(_:Event):Void closes++);

		picker.setColor(0x0000FF);
		assertEquals(0, changes, "same color does not dispatch change");
		picker.setColor(0x123456);
		assertEquals(1, changes, "changed color dispatches change");

		@:privateAccess picker.openPopup();
		assertEquals(1, opens, "openPopup dispatches open");
		@:privateAccess picker.pick(0xABCDEF);
		assertEquals(2, changes, "pick changed color dispatches once");
		assertEquals(1, closes, "pick closes popup");
		assertEquals(0xABCDEF, ColorPicker.recentColors[0], "new color records at front on close");
		var snapshot = ColorPicker.recentColors.copy();
		@:privateAccess picker.openPopup();
		@:privateAccess picker.pick(0xABCDEF);
		assertArrayEquals(snapshot, ColorPicker.recentColors, "existing recent color is not moved or duplicated");
		picker.remove();
	}

	private static function testPopupOrientationAndDirection():Void {
		resetRecents();
		var parent = new Sprite();
		var picker = new ColorPicker();
		picker.x = 100;
		picker.y = 40;
		parent.addChild(picker);
		picker.direction = ColorPicker.RIGHT;
		var swatchWidth = picker.width;
		@:privateAccess picker.openPopup();
		var popup:Sprite = @:privateAccess picker.popup;
		assertEquals(231.0, popup.getChildAt(252).x, "popup uses 22 palette columns");
		assertEquals(121.0, popup.getChildAt(11).y, "popup uses 12 palette rows");
		assertEquals(264, popup.numChildren, "popup has one cell per color");
		assertEquals(22.0, popup.getChildAt(24).x, "column index maps to x");
		assertEquals(0.0, popup.getChildAt(24).y, "row index maps to y");
		assertEquals(Math.round(picker.x + swatchWidth + 5), popup.x, "right direction places popup to the right");
		@:privateAccess picker.closePopup();

		picker.direction = ColorPicker.LEFT;
		@:privateAccess picker.openPopup();
		popup = @:privateAccess picker.popup;
		assertEquals(Math.round(picker.x - popup.width - 5), popup.x, "left direction places popup to the left");
		picker.remove();
	}

	private static function resetRecents():Void {
		for (i in 0...ColorPicker.recentColors.length) {
			ColorPicker.recentColors[i] = i % 2 == 0 ? 0x888888 : 0x555555;
		}
	}

	private static function assertArrayEquals(expected:Array<Int>, actual:Array<Int>, message:String):Void {
		assertions++;
		if (expected.length != actual.length) {
			throw '$message: expected length ${expected.length}, got ${actual.length}';
		}
		for (i in 0...expected.length) {
			if (expected[i] != actual[i]) {
				throw '$message at $i: expected ${expected[i]}, got ${actual[i]}';
			}
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
