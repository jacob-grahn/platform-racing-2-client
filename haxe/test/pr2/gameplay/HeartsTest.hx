package pr2.gameplay;

import openfl.display.Sprite;

class HeartsTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testNumLimit();
		if (pr2.DeterministicTestMode.finishSmokeSuite("HeartsTest")) return;
		testGrowAndShrink();
		trace('HeartsTest passed $assertions assertions');
	}

	private static function testNumLimit():Void {
		assertEquals(0, Hearts.numLimit(-3, 0, 15), "clamps below min");
		assertEquals(15, Hearts.numLimit(99, 0, 15), "clamps above max");
		assertEquals(7, Hearts.numLimit(7, 0, 15), "passes through in range");
	}

	private static function testGrowAndShrink():Void {
		var hearts = new Hearts();
		assertEquals(0, hearts.getHeartCount(), "starts empty");
		assertEquals(0, hearts.numChildren, "no heart icons yet");

		hearts.setHearts(3);
		assertEquals(3, hearts.getHeartCount(), "grows to requested count");
		assertEquals(3, hearts.numChildren, "three heart icons attached");
		var firstHeart:Sprite = cast hearts.getChildAt(0);
		assertEquals(3, firstHeart.numChildren, "native heart preserves its three authored vector layers");
		assertEquals(0.2, firstHeart.scaleX, "native heart preserves Flash's authored scale");
		assertEquals(20.0, hearts.getChildAt(1).y, "native hearts preserve their vertical step");

		hearts.setHearts(1);
		assertEquals(1, hearts.getHeartCount(), "shrinks to requested count");
		assertEquals(1, hearts.numChildren, "one heart icon remains");

		hearts.setHearts(50);
		assertEquals(15, hearts.getHeartCount(), "clamps to 15 lives");
		assertEquals(15, hearts.numChildren, "fifteen heart icons attached");

		hearts.remove();
		assertEquals(0, hearts.getHeartCount(), "remove clears the stack");
		assertEquals(0, hearts.numChildren, "remove detaches every icon");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
