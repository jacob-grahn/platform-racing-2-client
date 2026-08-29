package pr2.runtime;

import openfl.display.Stage;

/** Converts Flash's device-pixel hairlines to local OpenFL stroke widths. */
@:access(openfl.display.Stage)
final class HairlineScale {
	public static function current(stage:Null<Stage>):Float {
		#if (js && html5)
		if (stage != null) {
			var matrix = stage.__displayMatrix;
			var scaleX = Math.sqrt(matrix.a * matrix.a + matrix.b * matrix.b);
			var scaleY = Math.sqrt(matrix.c * matrix.c + matrix.d * matrix.d);
			return thicknessForScale(Math.sqrt(scaleX * scaleY));
		}
		#end
		// Native/Flash renderers implement zero-width hairlines themselves.
		return 0;
	}

	public static function thicknessForScale(scale:Float):Float {
		return scale > 0 ? 1 / scale : 1;
	}
}
