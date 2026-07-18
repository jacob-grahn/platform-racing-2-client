package pr2.effects;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.animation.TimelineClip;

/** Deterministic owner for semantic Lottie effect timelines. */
class NativeEffectAnimation extends Sprite {
	public var currentFrame(default, null):Int = 1;
	public final totalFrames:Int;
	public final timeline:TimelineClip;

	public function new(kind:String, totalFrames:Int) {
		super();
		timeline = new TimelineClip('assets/effects/$kind.lottie.json');
		if (timeline.totalFrames != totalFrames) throw 'Effect timeline $kind has ${timeline.totalFrames} frames, expected $totalFrames';
		this.totalFrames = timeline.totalFrames;
		mouseEnabled = false;
		mouseChildren = false;
		timeline.stop();
		addChild(timeline);
		addEventListener(Event.ENTER_FRAME, advance);
	}

	private function advance(_:Event):Void {
		advanceOneFrame();
	}

	public function advanceOneFrame():Void {
		if (currentFrame < totalFrames) currentFrame++;
		timeline.gotoAndStop(currentFrame);
		if (currentFrame >= totalFrames) removeEventListener(Event.ENTER_FRAME, advance);
	}

	public function dispose():Void {
		removeEventListener(Event.ENTER_FRAME, advance);
		timeline.dispose();
	}
}
