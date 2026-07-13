package pr2.effects;

import openfl.display.Shape;
import pr2.runtime.PR2MovieClip;

/** Frame scripts from `LaserShotGraphic.as`. */
class LaserShotTimeline {
	public static inline var TRAVEL_BEAM_NAME:String = "laserTravelBeam";

	private function new() {}

	public static function apply(display:PR2MovieClip):Void {
		display.setFrameScript(1, function():Void {
			display.stop();
		});
		display.setFrameScript(17, function():Void {
			display.stop();
		});
		display.gotoAndStop(2);
		var beam = new Shape();
		beam.name = TRAVEL_BEAM_NAME;
		// Same dimensions and colours as Graphics/Symbol 1006. Keeping this core
		// outside the gradient-stroke path guarantees the live projectile remains
		// visible on HTML5 while the authored timeline still supplies its hit art.
		beam.graphics.lineStyle(5, 0xFFFF00, 0.45);
		beam.graphics.moveTo(-40, 0);
		beam.graphics.lineTo(0, 0);
		beam.graphics.lineStyle(2, 0xFFFFFF, 1);
		beam.graphics.moveTo(-40, 0);
		beam.graphics.lineTo(0, 0);
		display.addChild(beam);
	}

	public static function playHit(display:PR2MovieClip):Void {
		display.gotoAndPlay("hit");
	}
}
