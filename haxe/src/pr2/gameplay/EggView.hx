package pr2.gameplay;

import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.events.Event;
import openfl.geom.ColorTransform;
import pr2.runtime.SvgAsset;

/** Explicit native walk/squash timeline for an egg-mode minion. */
class EggView extends Sprite {
	public var currentFrame(default, null):Int = 1;
	public var currentAssetPath(default, null):String;
	public final leftFoot:EggPartView;
	public final rightFoot:EggPartView;
	public final base:Sprite;
	public final dots:Sprite;
	private var playing:Bool = true;
	private var exactArt:Null<Shape>;
	private var footTint:Int = 0xFFFFFF;
	private var baseTint:Int = 0xFFFFFF;
	private var dotsTint:Int = 0xFFFFFF;

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
		leftFoot.visible = false;
		addChild(leftFoot);
		rightFoot = new EggPartView();
		rightFoot.name = "var_152";
		rightFoot.x = 17;
		rightFoot.y = 29;
		rightFoot.visible = false;
		addChild(rightFoot);
		addEventListener(Event.ENTER_FRAME, advance);
		redraw();
	}

	public function playSquash():Void {
		currentFrame = 30;
		playing = true;
		redraw();
	}

	public function stop():Void playing = false;

	public function applyRandomColors(nextRandom:Void->Float):Void {
		var footColor = randomColor(nextRandom);
		var baseColor = randomColor(nextRandom);
		var dotsColor = randomColor(nextRandom);
		footTint = footColor;
		baseTint = baseColor;
		dotsTint = dotsColor;
		leftFoot.colorMC.transform.colorTransform = colorTransformFor(footColor);
		rightFoot.colorMC.transform.colorTransform = colorTransformFor(footColor);
		leftFoot.colorMC2.visible = false;
		rightFoot.colorMC2.visible = false;
		base.transform.colorTransform = colorTransformFor(baseColor);
		dots.transform.colorTransform = colorTransformFor(dotsColor);
		redraw();
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
		if (exactArt != null && exactArt.parent == this) removeChild(exactArt);
		currentAssetPath = 'assets/svg/effects/egg_${StringTools.lpad(Std.string(currentFrame), "0", 2)}.svg';
		var tints:Map<String, Int> = ["colorMC" => footTint, "base" => baseTint, "dots" => dotsTint];
		exactArt = SvgAsset.createTinted(currentAssetPath, tints, ["colorMC2"]);
		exactArt.name = currentAssetPath;
		addChildAt(exactArt, 0);
	}

	private static function randomColor(nextRandom:Void->Float):Int {
		return Math.floor(nextRandom() * 0xFFFFFF);
	}

	private static function colorTransformFor(color:Int):ColorTransform {
		var transform = new ColorTransform();
		transform.color = color;
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
	}
	public function gotoAndStop(frame:Int):Void currentFrame = frame;
}
