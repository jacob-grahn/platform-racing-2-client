package pr2.page;

import openfl.display.Sprite;
import openfl.events.Event;

class LoginPageFadeTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var holder = new Sprite();
		var fade = new LoginPageFade();
		holder.addChild(fade);

		assertNear(1, fade.alpha, "Flash login fade starts opaque");
		for (_ in 0...9) fade.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertNear(0.5, fade.alpha, "Flash login fade reaches its authored midpoint on frame 10");
		for (_ in 9...18) fade.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertNear(0, fade.alpha, "Flash login fade ends transparent on frame 19");
		assertEquals(null, fade.parent, "completed fade removes its overlay");
		assertEquals(false, fade.hasEventListener(Event.ENTER_FRAME), "completed fade removes its frame listener");

		trace('LoginPageFadeTest passed $assertions assertions');
	}

	private static function assertNear(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.00001) throw '$message: expected $expected, got $actual';
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
