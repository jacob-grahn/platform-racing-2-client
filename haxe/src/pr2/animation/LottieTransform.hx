package pr2.animation;

import openfl.geom.Matrix;

typedef LottieTransformSample = {
	var matrix:Matrix;
	var opacity:Float;
}

/** Deterministic sampler for the standard 2D Lottie transform subset. */
class LottieTransform {
	public static function sample(transform:Dynamic, frame:Int):LottieTransformSample {
		var anchor = vectorAt(transform.a, frame);
		var position = vectorAt(transform.p, frame);
		var scale = vectorAt(transform.s, frame);
		var rotation = radians(scalarAt(transform.r, frame));
		var skew = radians(-scalarAt(optionalProperty(transform, "sk", 0.0), frame));
		var skewAxis = scalarAt(optionalProperty(transform, "sa", 0.0), frame);
		if (Math.abs(skewAxis) > 1e-12) throw "Lottie transform profile requires a zero skew axis";

		var scaleX = scale[0] / 100.0;
		var scaleY = scale[1] / 100.0;
		var cosine = Math.cos(rotation);
		var sine = Math.sin(rotation);
		var shear = Math.tan(skew);
		var a = cosine * scaleX;
		var b = sine * scaleX;
		var c = scaleY * (cosine * shear - sine);
		var d = scaleY * (sine * shear + cosine);
		var tx = position[0] - a * anchor[0] - c * anchor[1];
		var ty = position[1] - b * anchor[0] - d * anchor[1];
		return {
			matrix: new Matrix(a, b, c, d, tx, ty),
			opacity: scalarAt(transform.o, frame) / 100.0
		};
	}

	public static function valueAt(property:Dynamic, frame:Int):Dynamic {
		if (Std.int(property.a) == 0) return property.k;
		var keys:Array<Dynamic> = cast property.k;
		var value:Dynamic = null;
		for (key in keys) {
			if (Std.int(key.t) > frame) break;
			value = key.s;
		}
		if (value == null) throw 'Animated Lottie property has no value at frame $frame';
		return value;
	}

	private static function vectorAt(property:Dynamic, frame:Int):Array<Float> {
		var values:Array<Dynamic> = cast valueAt(property, frame);
		return [number(values[0]), number(values[1])];
	}

	private static function scalarAt(property:Dynamic, frame:Int):Float {
		var value:Dynamic = valueAt(property, frame);
		if (Std.isOfType(value, Array)) return number((cast value : Array<Dynamic>)[0]);
		return number(value);
	}

	private static function optionalProperty(owner:Dynamic, name:String, fallback:Float):Dynamic {
		return Reflect.hasField(owner, name) ? Reflect.field(owner, name) : {a: 0, k: fallback};
	}

	private static inline function number(value:Dynamic):Float return value;
	private static inline function radians(degrees:Float):Float return degrees * Math.PI / 180.0;

	private function new() {}
}
