package pr2.effects;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.ColorTransform;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;

class StarEffect extends Sprite {
	public static inline var LIFETIME_FRAMES:Int = 15;

	public var graphic(default, null):Shape;
	private var framesRemaining:Int = LIFETIME_FRAMES;
	private var frameIndex:Int = 0;

	private static final Y:Array<Float> = [-0.05, -5.15, -9.9, -14.25, -18.3, -22, -25.35, -28.3, -30.95, -33.25, -35.15, -36.75, -37.95,
		-38.85, -39.35, -39.55];
	private static final ALPHA:Array<Float> = [1, .87109375, .75, .640625, .5390625, .44921875, .359375, .2890625, .21875, .16015625, .109375,
		.0703125, .0390625, .01953125, 0, 0];
	private static final OFFSET:Array<Float> = [0, 33, 63, 92, 118, 142, 163, 182, 199, 214, 227, 237, 245, 250, 254, 255];

	public function new(startX:Float, startY:Float) {
		super();
		x = startX;
		y = startY;
		graphic = NativeAssets.svg(StaticSvg.SpeedBurstStar);
		addChild(graphic);
		applyFrame(0);
		addEventListener(Event.ENTER_FRAME, tick);
	}

	public function currentFrameForTests():Int {
		return frameIndex;
	}

	private function tick(_:Event):Void {
		frameIndex = Std.int(Math.min(frameIndex + 1, Y.length - 1));
		applyFrame(frameIndex);
		framesRemaining--;
		if (framesRemaining <= 0) {
			remove();
		}
	}

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, tick);
		if (graphic != null) {
			if (graphic.parent == this) removeChild(graphic);
			graphic = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function applyFrame(index:Int):Void {
		graphic.scaleX = 1.08108520507812;
		graphic.scaleY = 1.07859802246094;
		graphic.y = Y[index];
		var offset = OFFSET[index];
		graphic.transform.colorTransform = new ColorTransform(0, 0, 0, ALPHA[index], offset, 255, offset);
	}
}
