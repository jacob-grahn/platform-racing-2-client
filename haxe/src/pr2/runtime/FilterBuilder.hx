package pr2.runtime;

import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;
import openfl.filters.DropShadowFilter;
import openfl.filters.GlowFilter;
import pr2.generated.assets.AssetTypes.FilterDef;

/**
	Maps XFL filter defs to their OpenFL equivalents. Pulled out of PR2MovieClip:
	a pure FilterDef -> BitmapFilter transform with no clip state.
**/
class FilterBuilder {
	public static function build(defs:Array<FilterDef>):Array<BitmapFilter> {
		var result:Array<BitmapFilter> = [];
		for (def in defs) {
			var filter = buildFilter(def);
			if (filter != null) {
				result.push(filter);
			}
		}
		return result;
	}

	/**
		Maps an XFL filter def to its OpenFL equivalent. Missing attributes fall
		back to the OpenFL constructor defaults, which match the Flash authoring
		defaults the XFL omits, so the rendered result matches the original.
	**/
	private static function buildFilter(def:FilterDef):Null<BitmapFilter> {
		return switch (def.type) {
			case "BlurFilter":
				new BlurFilter(
					def.blurX == null ? 4 : def.blurX,
					def.blurY == null ? 4 : def.blurY,
					def.quality == null ? 1 : def.quality
				);
			case "GlowFilter":
				new GlowFilter(
					def.color == null ? 0xFF0000 : def.color,
					def.alpha == null ? 1 : def.alpha,
					def.blurX == null ? 6 : def.blurX,
					def.blurY == null ? 6 : def.blurY,
					def.strength == null ? 2 : def.strength,
					def.quality == null ? 1 : def.quality,
					def.inner == null ? false : def.inner,
					def.knockout == null ? false : def.knockout
				);
			case "DropShadowFilter":
				new DropShadowFilter(
					def.distance == null ? 4 : def.distance,
					def.angle == null ? 45 : def.angle,
					def.color == null ? 0 : def.color,
					def.alpha == null ? 1 : def.alpha,
					def.blurX == null ? 4 : def.blurX,
					def.blurY == null ? 4 : def.blurY,
					def.strength == null ? 1 : def.strength,
					def.quality == null ? 1 : def.quality,
					def.inner == null ? false : def.inner,
					def.knockout == null ? false : def.knockout,
					def.hideObject == null ? false : def.hideObject
				);
			default:
				null;
		}
	}
}
