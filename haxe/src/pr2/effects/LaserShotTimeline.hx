package pr2.effects;

import pr2.runtime.PR2MovieClip;

/** Frame scripts from `LaserShotGraphic.as`. */
class LaserShotTimeline {
	private function new() {}

	public static function apply(display:PR2MovieClip):Void {
		display.setFrameScript(1, function():Void {
			display.stop();
		});
		display.setFrameScript(17, function():Void {
			display.stop();
		});
		display.gotoAndStop(2);
	}

	public static function playHit(display:PR2MovieClip):Void {
		display.gotoAndPlay("hit");
	}
}
