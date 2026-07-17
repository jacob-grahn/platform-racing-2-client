package pr2.gameplay;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.ColorTransform;

/** Explicit native walk/squash timeline for an egg-mode minion. */
class EggView extends Sprite {
	public var currentFrame(default, null):Int = 1;
	public final leftFoot:EggPartView;
	public final rightFoot:EggPartView;
	public final base:Sprite;
	public final dots:Sprite;
	private var playing:Bool = true;

	public function new() {
		super();
		name = "EggGraphic";
		var egg = new Sprite();
		egg.name = "egg";
		base = new Sprite();
		base.name = "base";
		egg.addChild(base);
		dots = new Sprite();
		dots.name = "dots";
		egg.addChild(dots);
		addChild(egg);
		leftFoot = new EggPartView();
		leftFoot.name = "var_165";
		leftFoot.x = -17;
		leftFoot.y = 29;
		addChild(leftFoot);
		rightFoot = new EggPartView();
		rightFoot.name = "var_152";
		rightFoot.x = 17;
		rightFoot.y = 29;
		addChild(rightFoot);
		addEventListener(Event.ENTER_FRAME, advance);
		redraw();
	}

	public function gotoAndPlay(label:String):Void {
		currentFrame = label == "squash" ? 30 : 1;
		playing = true;
		redraw();
	}

	public function stop():Void playing = false;

	public function applyRandomColors(nextRandom:Void->Float):Void {
		var footColor = randomColor(nextRandom);
		var baseColor = randomColor(nextRandom);
		var dotsColor = randomColor(nextRandom);
		leftFoot.colorMC.transform.colorTransform = footColor;
		rightFoot.colorMC.transform.colorTransform = footColor;
		leftFoot.colorMC2.visible = false;
		rightFoot.colorMC2.visible = false;
		base.transform.colorTransform = baseColor;
		dots.transform.colorTransform = dotsColor;
	}

	public function dispose():Void {
		removeEventListener(Event.ENTER_FRAME, advance);
		if (parent != null) parent.removeChild(this);
	}

	private function advance(_:Event):Void {
		if (!playing) return;
		currentFrame++;
		if (currentFrame == 25) currentFrame = 1;
		if (currentFrame >= 46) {
			currentFrame = 46;
			playing = false;
		}
		redraw();
	}

	private function redraw():Void {
		var squash = currentFrame >= 30 ? Math.max(0.25, 1 - (currentFrame - 30) / 22) : 1.0;
		base.graphics.clear();
		base.graphics.beginFill(0xFFFFFF);
		base.graphics.drawEllipse(-27, -34 * squash, 54, 68 * squash);
		base.graphics.endFill();
		dots.graphics.clear();
		dots.graphics.beginFill(0xFFFFFF);
		dots.graphics.drawCircle(-10, -8 * squash, 5);
		dots.graphics.drawCircle(11, 5 * squash, 4);
		dots.graphics.drawCircle(3, -20 * squash, 3);
		dots.graphics.endFill();
		leftFoot.y = rightFoot.y = 29 * squash;
	}

	private static function randomColor(nextRandom:Void->Float):ColorTransform {
		var transform = new ColorTransform();
		transform.color = Math.floor(nextRandom() * 0xFFFFFF);
		return transform;
	}
}

class EggPartView extends Sprite {
	public var currentFrame(default, null):Int = 1;
	public final colorMC:EggPartChannel;
	public final colorMC2:EggPartChannel;
	public function new() {
		super();
		colorMC = new EggPartChannel();
		colorMC.name = "colorMC";
		addChild(colorMC);
		colorMC2 = new EggPartChannel();
		colorMC2.name = "colorMC2";
		addChild(colorMC2);
	}
	public function gotoAndStop(frame:Int):Void currentFrame = frame;
}

class EggPartChannel extends Sprite {
	public var currentFrame(default, null):Int = 1;
	public function new() {
		super();
		graphics.beginFill(0xFFFFFF);
		graphics.drawEllipse(-13, -5, 26, 10);
		graphics.endFill();
	}
	public function gotoAndStop(frame:Int):Void currentFrame = frame;
}
