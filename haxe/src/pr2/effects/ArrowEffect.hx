package pr2.effects;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;

/**
	Port of `effects.ArrowEffect`: the small drifting arrow particle emitted by
	`character.ArrowSparkleEmitter`.
**/
class ArrowEffect extends Sprite {
	public static inline var LIFETIME_FRAMES:Int = 15;
	public static inline var FADE_RATE:Float = 0.06;
	public static inline var SCALE:Float = 0.25;

	public var graphic(default, null):Shape;
	private var velY:Float = 0;
	private var framesRemaining:Int = LIFETIME_FRAMES;

	public function new(startX:Float, startY:Float) {
		super();
		x = startX;
		y = startY;
		scaleX = SCALE;
		scaleY = SCALE;
		graphic = NativeAssets.svg(StaticSvg.Arrow2Overlay);
		addChild(graphic);
		addEventListener(Event.ENTER_FRAME, tick);
	}

	private function tick(_:Event):Void {
		velY -= 0.1;
		y -= velY;
		alpha -= FADE_RATE;
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
}
