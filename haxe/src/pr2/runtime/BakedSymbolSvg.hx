package pr2.runtime;

import openfl.display.Sprite;
import openfl.utils.AssetType;
import openfl.utils.Assets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

/** Replaces selected static timeline symbols with their direct SVG exports. */
class BakedSymbolSvg {
	private static final KONGREGATE_SYMBOLS:Map<String, String> = [
		"MovieClips/Symbol 27" => "symbol_27",
		"MovieClips/Symbol 30" => "symbol_30",
		"MovieClips/Symbol 32" => "symbol_32",
		"MovieClips/Symbol 34" => "symbol_34",
		"MovieClips/Symbol 36" => "symbol_36",
		"MovieClips/Symbol 38" => "symbol_38",
		"MovieClips/Symbol 40" => "symbol_40",
		"MovieClips/Symbol 41" => "symbol_41",
		"MovieClips/Symbol 44" => "symbol_44",
		"MovieClips/Symbol 47" => "symbol_47",
		"MovieClips/Symbol 49" => "symbol_49",
		"MovieClips/Symbol 52" => "symbol_52",
		"Graphics/Symbol 28" => "graphic_28",
		"Graphics/Symbol 42" => "graphic_42",
		"Graphics/Symbol 43" => "graphic_43",
	];

	public static function isBaked(symbolName:String):Bool {
		return KONGREGATE_SYMBOLS.exists(symbolName);
	}

	public static function create(symbolName:String):Null<Sprite> {
		var frameName = KONGREGATE_SYMBOLS.get(symbolName);
		if (frameName == null) {
			return null;
		}

		var svgPath = 'assets/svg/intro/kongregate/$frameName.svg';
		var vector = new Sprite();
		if (Assets.exists(svgPath, AssetType.TEXT)) {
			vector.addChild(SvgAsset.create(svgPath));
			return vector;
		}

		#if sys
		var sourcePath = 'art/svg/intro/kongregate/$frameName.svg';
		if (FileSystem.exists(sourcePath)) {
			vector.addChild(SvgAsset.createFromText(File.getContent(sourcePath)));
			return vector;
		}
		#end

		return null;
	}
}
