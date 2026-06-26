package pr2.gameplay;

class HeartsTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testNumLimit();
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
