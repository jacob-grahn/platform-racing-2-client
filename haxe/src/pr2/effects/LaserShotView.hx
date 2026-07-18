package pr2.effects;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.runtime.SvgAsset;

/** Native travel beam and 18-frame impact sequence for LaserShotGraphic. */
class LaserShotView extends Sprite {
	public static inline var TRAVEL_BEAM_NAME:String = "laserTravelBeam";
	public var currentFrame(default, null):Int = 2;
	public var currentAssetPath(default, null):String;
	private var playingHit:Bool = false;
	private var art:Sprite;

	public function new() {
		super();
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
		if (art != null && art.parent == this) removeChild(art);
		currentAssetPath = 'assets/svg/effects/laser_${StringTools.lpad(Std.string(currentFrame), "0", 2)}.svg';
		art = new Sprite();
		art.name = playingHit ? "laserImpact" : TRAVEL_BEAM_NAME;
		art.addChild(SvgAsset.create(currentAssetPath));
		addChild(art);
	}

	public function dispose():Void {
		removeEventListener(Event.ENTER_FRAME, advance);
	}
}
