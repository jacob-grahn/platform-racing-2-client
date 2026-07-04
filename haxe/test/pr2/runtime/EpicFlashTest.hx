package pr2.runtime;

import openfl.display.Sprite;

class EpicFlashTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testLifecycleAndColorTick();
		trace('EpicFlashTest passed $assertions assertions');
	}

	private static function testLifecycleAndColorTick():Void {
		var flash = new EpicFlash(500);
		assertEquals(true, flash.isEmpty(), "new EpicFlash starts empty");
		var one = new Sprite();
		var two = new Sprite();
		flash.addItem(one);
		flash.addItem(two);
		flash.addItem(null);
		assertEquals(false, flash.isEmpty(), "addItem registers display objects");

		flash.colorTick();
		var first = one.transform.colorTransform;
		var second = two.transform.colorTransform;
		assertEquals(first.redOffset, second.redOffset, "tick applies same red offset");
		assertEquals(first.greenOffset, second.greenOffset, "tick applies same green offset");
		assertEquals(first.blueOffset, second.blueOffset, "tick applies same blue offset");

		flash.start();
		var firstTimer = @:privateAccess flash.timer;
		assertEquals(true, @:privateAccess flash.active, "start marks active");
		assertEquals(false, firstTimer == null, "start arms timer");
		flash.setDelay(300);
		assertEquals(300, @:privateAccess flash.intervalDelay, "setDelay stores delay");
		assertEquals(true, @:privateAccess flash.timer != firstTimer, "active setDelay rearms timer");
		flash.stop();
		assertEquals(false, @:privateAccess flash.active, "stop clears active");
		assertEquals(null, @:privateAccess flash.timer, "stop clears timer");
		flash.remove();
		assertEquals(true, flash.isEmpty(), "remove clears item references");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
