package pr2.effects;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;

/** Native travel beam and 18-frame impact sequence for LaserShotGraphic. */
class LaserShotView extends Sprite {
	public static inline var TRAVEL_BEAM_NAME:String = "laserTravelBeam";
	public var currentFrame(default, null):Int = 2;
	private var playingHit:Bool = false;
	private final impact:Shape;

	public function new() {
		super();
		var beam = new Shape();
		beam.name = TRAVEL_BEAM_NAME;
		beam.graphics.lineStyle(5, 0xFFFF00, 0.45);
		beam.graphics.moveTo(-40, 0);
		beam.graphics.lineTo(0, 0);
		beam.graphics.lineStyle(2, 0xFFFFFF, 1);
		beam.graphics.moveTo(-40, 0);
		beam.graphics.lineTo(0, 0);
		addChild(beam);
		impact = new Shape();
		impact.visible = false;
		addChild(impact);
		addEventListener(Event.ENTER_FRAME, advance);
	}

	public function playHit():Void {
		if (playingHit) return;
		playingHit = true;
		currentFrame = 3;
		getChildByName(TRAVEL_BEAM_NAME).visible = false;
		redrawImpact();
	}

	private function advance(_:Event):Void {
		if (!playingHit || currentFrame >= 18) return;
		currentFrame++;
		redrawImpact();
	}

	private function redrawImpact():Void {
		impact.visible = true;
		impact.graphics.clear();
		var progress = (currentFrame - 3) / 15;
		var fade = 1 - progress;
		var radius = 4 + progress * 24;
		impact.graphics.beginFill(0xFFFF00, fade * 0.8);
		impact.graphics.drawCircle(0, 0, radius);
		impact.graphics.endFill();
		impact.graphics.beginFill(0xFFFFFF, fade);
		impact.graphics.drawCircle(0, 0, radius * 0.45);
		impact.graphics.endFill();
	}

	public function dispose():Void {
		removeEventListener(Event.ENTER_FRAME, advance);
	}
}
