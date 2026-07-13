package pr2.runtime;

import haxe.Json;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.PixelSnapping;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.Assets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class BakedSymbolAtlas {
	private static final KONGREGATE_ATLAS = "assets/intro/atlases/kongregate@4x.json";
	private static final LOCAL_KONGREGATE_ATLAS = "assets/intro/atlases/kongregate@4x.json";
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

	private static var kongregateAtlas:Null<GenericAtlas>;

	// True when `create` would replace this symbol with a baked Bitmap. Lets the
	// static-subtree analysis treat a baked symbol as a single static quad without
	// loading the atlas image or allocating a display object.
	public static function isBaked(symbolName:String):Bool {
		return KONGREGATE_SYMBOLS.exists(symbolName);
	}

	public static function create(symbolName:String):Null<Sprite> {
		var frameName = KONGREGATE_SYMBOLS.get(symbolName);
		if (frameName == null) {
			return null;
		}

		var atlas = loadKongregateAtlas();
		if (atlas == null) {
			return null;
		}
		var frame = atlas.frames.get(frameName);
		if (frame == null) {
			return null;
		}
		return new BakedSymbolSprite(atlas, frame);
	}

	private static function loadKongregateAtlas():Null<GenericAtlas> {
		if (kongregateAtlas == null) {
			var json = readAtlasText();
			if (json == null) {
				return null;
			}
			kongregateAtlas = GenericAtlas.parse(json, KONGREGATE_ATLAS);
		}
		return kongregateAtlas;
	}

	private static function readAtlasText():Null<String> {
		if (Assets.exists(KONGREGATE_ATLAS)) {
			return Assets.getText(KONGREGATE_ATLAS);
		}
		#if sys
		if (FileSystem.exists(LOCAL_KONGREGATE_ATLAS)) {
			return File.getContent(LOCAL_KONGREGATE_ATLAS);
		}
		#end
		return null;
	}
}

private class BakedSymbolSprite extends Sprite {
	private static final bitmapDataByFrame:Map<String, BitmapData> = new Map();

	public function new(atlas:GenericAtlas, frame:GenericAtlasFrame) {
		super();
		if (frame.sourceTrim.empty) {
			return;
		}

		var bitmapData = bitmapDataForFrame(atlas, frame);
		if (bitmapData != null) {
			var bitmap = new Bitmap(bitmapData, PixelSnapping.AUTO, true);
			bitmap.x = frame.sourceTrim.x / frame.scale;
			bitmap.y = frame.sourceTrim.y / frame.scale;
			bitmap.scaleX = 1 / frame.scale;
			bitmap.scaleY = 1 / frame.scale;
			addChild(bitmap);
			return;
		}

		graphics.beginFill(0, 0);
		graphics.drawRect(
			frame.sourceTrim.x / frame.scale,
			frame.sourceTrim.y / frame.scale,
			frame.sourceTrim.width / frame.scale,
			frame.sourceTrim.height / frame.scale
		);
		graphics.endFill();
	}

	private static function bitmapDataForFrame(atlas:GenericAtlas, frame:GenericAtlasFrame):Null<BitmapData> {
		var key = atlas.assetImagePath + ":" + frame.name + ":" + frame.rect.x + "," + frame.rect.y + "," + frame.rect.width + "," + frame.rect.height;
		var cached = bitmapDataByFrame.get(key);
		if (cached != null) {
			return cached;
		}
		if (!Assets.exists(atlas.assetImagePath)) {
			return null;
		}

		var source = Assets.getBitmapData(atlas.assetImagePath);
		var cropped = new BitmapData(frame.rect.width, frame.rect.height, true, 0);
		cropped.copyPixels(
			source,
			new Rectangle(frame.rect.x, frame.rect.y, frame.rect.width, frame.rect.height),
			new Point()
		);
		bitmapDataByFrame.set(key, cropped);
		return cropped;
	}
}

private class GenericAtlas {
	public final imagePath:String;
	public final assetImagePath:String;
	public final frames:Map<String, GenericAtlasFrame>;

	public function new(imagePath:String, assetImagePath:String, frames:Map<String, GenericAtlasFrame>) {
		this.imagePath = imagePath;
		this.assetImagePath = assetImagePath;
		this.frames = frames;
	}

	public static function parse(json:String, assetPath:String):GenericAtlas {
		var data:Dynamic = Json.parse(json);
		var imagePath:String = Reflect.field(data, "image");
		var frames:Map<String, GenericAtlasFrame> = new Map();
		var frameData:Dynamic = Reflect.field(data, "frames");
		for (name in Reflect.fields(frameData)) {
			var item = Reflect.field(frameData, name);
			frames.set(name, GenericAtlasFrame.parse(name, item));
		}
		return new GenericAtlas(imagePath, resolveSiblingAssetPath(assetPath, imagePath), frames);
	}

	private static function resolveSiblingAssetPath(assetPath:String, imagePath:String):String {
		var slash = assetPath.lastIndexOf("/");
		var imageSlash = imagePath.lastIndexOf("/");
		var imageName = imageSlash < 0 ? imagePath : imagePath.substr(imageSlash + 1);
		return assetPath.substr(0, slash + 1) + imageName;
	}
}

private class GenericAtlasFrame {
	public final name:String;
	public final scale:Int;
	public final rect:GenericRect;
	public final sourceTrim:GenericSourceTrim;

	public function new(name:String, scale:Int, rect:GenericRect, sourceTrim:GenericSourceTrim) {
		this.name = name;
		this.scale = scale;
		this.rect = rect;
		this.sourceTrim = sourceTrim;
	}

	public static function parse(name:String, data:Dynamic):GenericAtlasFrame {
		return new GenericAtlasFrame(
			name,
			Std.int(Reflect.field(data, "scale")),
			GenericRect.parse(Reflect.field(data, "frame")),
			GenericSourceTrim.parse(Reflect.field(data, "sourceTrim"))
		);
	}
}

private class GenericRect {
	public final x:Int;
	public final y:Int;
	public final width:Int;
	public final height:Int;

	public function new(x:Int, y:Int, width:Int, height:Int) {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}

	public static function parse(data:Dynamic):GenericRect {
		return new GenericRect(
			Std.int(Reflect.field(data, "x")),
			Std.int(Reflect.field(data, "y")),
			Std.int(Reflect.field(data, "width")),
			Std.int(Reflect.field(data, "height"))
		);
	}
}

private class GenericSourceTrim {
	public final empty:Bool;
	public final x:Int;
	public final y:Int;
	public final width:Int;
	public final height:Int;

	public function new(empty:Bool, x:Int, y:Int, width:Int, height:Int) {
		this.empty = empty;
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}

	public static function parse(data:Dynamic):GenericSourceTrim {
		return new GenericSourceTrim(
			Reflect.field(data, "empty"),
			Std.int(Reflect.field(data, "x")),
			Std.int(Reflect.field(data, "y")),
			Std.int(Reflect.field(data, "width")),
			Std.int(Reflect.field(data, "height"))
		);
	}
}
