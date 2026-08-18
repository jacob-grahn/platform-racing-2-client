package pr2.page;

import openfl.display.Shape;
import openfl.events.Event;
import pr2.Constants;

/** The 19-frame black overlay authored on the Flash LoginPage timeline. */
class LoginPageFade extends Shape {
	private static final FRAME_ALPHAS:Array<Float> = [
		1,
		0.94921875,
		0.890625,
		0.828125,
		0.78125,
		0.71875,
		0.671875,
		0.609375,
		0.55078125,
		0.5,
		0.44921875,
		0.390625,
		0.328125,
		0.28125,
		0.21875,
		0.171875,
		0.109375,
		0.05078125,
		0
	];

	public var currentFrame(default, null):Int = 0;

	public function new() {
		super();
		graphics.beginFill(0x000000);
		graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		graphics.endFill();
		alpha = FRAME_ALPHAS[0];
		addEventListener(Event.ENTER_FRAME, advance);
	}

	private function advance(_:Event):Void {
		if (!pr2.runtime.FrameClock.shouldRunSimulationFrame()) return;
		currentFrame++;
		alpha = FRAME_ALPHAS[currentFrame];
		if (currentFrame == FRAME_ALPHAS.length - 1) dispose();
	}

	public function dispose():Void {
		removeEventListener(Event.ENTER_FRAME, advance);
		if (parent != null) parent.removeChild(this);
	}
}
