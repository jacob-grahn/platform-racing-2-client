package pr2.character;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.geom.ColorTransform;
import pr2.effects.StarEffect;

class RainbowStarEmitter extends ParticleEmitter {
	private final colorRandom:Void->Float;

	public function new(intervalMs:Int, durationMs:Int, target:DisplayObject, parentLayer:DisplayObjectContainer, ?random:Void->Float) {
		super(intervalMs, durationMs, target, parentLayer, random);
		colorRandom = random == null ? Math.random : random;
	}

	override private function createParticle(x:Float, y:Float):Null<DisplayObject> {
		var star = new StarEffect(x, y);
		star.rotation = colorRandom() * 360;
		star.transform.colorTransform = new ColorTransform(
			colorRandom(),
			colorRandom(),
			colorRandom(),
			colorRandom(),
			colorRandom(),
			colorRandom(),
			colorRandom(),
			colorRandom()
		);
		return star;
	}
}
