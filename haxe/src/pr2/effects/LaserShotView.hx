package pr2.effects;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.animation.TimelineClip;

/** Native travel beam and 18-frame impact sequence for LaserShotGraphic. */
class LaserShotView extends Sprite {
	public static inline var TRAVEL_BEAM_NAME:String = "laserTravelBeam";
	public var currentFrame(default, null):Int = 2;
	public final timeline:TimelineClip;
	private var playingHit:Bool = false;

	public function new() {
		super();
		timeline = new TimelineClip("assets/effects/laser.lottie.json");
		timeline.stop();
		addChild(timeline);
		renderFrame();
		addEventListener(Event.ENTER_FRAME, advance);
	}

	public function playHit():Void {
		if (playingHit) return;
		playingHit = true;
		currentFrame = 3;
		renderFrame();
	}

	private function advance(_:Event):Void {
		if (!playingHit || currentFrame >= 18) return;
		currentFrame++;
		renderFrame();
	}

	private function renderFrame():Void {
		timeline.name = playingHit ? "laserImpact" : TRAVEL_BEAM_NAME;
		timeline.gotoAndStop(currentFrame);
	}

	public function dispose():Void {
		removeEventListener(Event.ENTER_FRAME, advance);
		timeline.dispose();
	}
}
