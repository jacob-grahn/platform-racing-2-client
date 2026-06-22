package pr2.gameplay;

class CameraFollowTest {
	private static var assertions = 0;

	public static function main():Void {
		var camera = new CameraFollow(-100, -100);
		camera.follow(300, 400);
		assertEquals(-200.0, camera.posX, "x eases halfway to negated player x");
		assertEquals(-202.0, camera.posY, "y eases 40 percent toward player plus 45");
		camera.follow(300, 400);
		assertEquals(-250.0, camera.posX, "x smoothing retains prior camera position");
		assertEquals(-263.2, camera.posY, "y smoothing retains prior camera position");
		trace('CameraFollowTest passed $assertions assertions');
	}

	private static function assertEquals(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000001) throw '$message: expected=$expected actual=$actual';
	}
}
