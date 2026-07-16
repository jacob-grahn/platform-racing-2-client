package pr2.effects;

import openfl.events.Event;

/** Characterizes the native replacement for the authored mine placement clip. */
class MineAppearTest {
	private static var assertions = 0;

	public static function main():Void {
		assertAuthoredMineAsset();
		var completions = 0;
		var effect = new MineAppear(125, 75, 30, 0, 0, function():Void completions++, false);
		assertEquals(125.0, effect.x, "native effect keeps world x");
		assertEquals(75.0, effect.y, "native effect keeps world y");
		assertEquals(30.0, effect.rotation, "native effect keeps authored rotation");
		assertNear(0, effect.animation.bitmap.alpha, "frame one begins transparent like MineAppearAnimation");
		assertNear(4.29489135742188, effect.animation.bitmap.scaleX, "frame one keeps authored expansion scale");

		advance(effect, 16);
		assertEquals(16, effect.animation.playback.currentFrame, "native sequence reaches authored frame 17 after 16 ticks");
		assertNear(1.82369995117188, effect.animation.bitmap.scaleX, "midpoint frame keeps authored mine scale");
		assertNear(-26.6, effect.animation.bitmap.x, "midpoint frame keeps authored mine x");
		assertNear(1, effect.animation.bitmap.alpha, "midpoint mine is fully visible");

		advance(effect, 16);
		assertEquals(32, effect.animation.playback.currentFrame, "native sequence reaches final authored frame");
		assertNear(1, effect.animation.bitmap.scaleX, "final frame restores authored mine scale");
		assertNear(-14.55, effect.animation.bitmap.x, "final frame keeps authored mine registration");
		assertNear(1, effect.animation.bitmap.transform.colorTransform.redMultiplier, "final frame removes white transition tint");

		advance(effect, 1);
		assertEquals(1, completions, "completion fires once after exactly 33 frames");
		assertEquals(null, effect.animation, "completion tears down the native animation");
		effect.remove(true);
		assertEquals(1, completions, "explicit removal cannot replay completion");

		trace('MineAppearTest passed $assertions assertions');
	}

	private static function advance(effect:MineAppear, frames:Int):Void {
		for (_ in 0...frames) effect.dispatchEvent(new Event(Event.ENTER_FRAME));
	}
	private static function assertAuthoredMineAsset():Void {
		#if sys
		var bytes = sys.io.File.getBytes("assets/bitmaps/mine.jpg");
		assertEquals(0xFF, bytes.get(0), "native mine uses the original XFL JPEG payload");
		assertEquals(0xD8, bytes.get(1), "native mine asset remains a JPEG");
		assertEquals(true, bytes.length > 100, "native mine payload is non-empty visual source");
		#end
	}
	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
	private static function assertNear(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > .0001) throw '$message: expected $expected, got $actual';
	}
}
