package pr2.character;

import haxe.Json;
import openfl.utils.Assets;

class CharacterAtlas {
	public final kind:String;
	public final channel:String;
	public final imagePath:String;
	public final assetImagePath:String;
	public final page:Int;
	public final pages:Int;
	public final size:AtlasSize;
	public final frames:Map<String, CharacterAtlasFrame>;

	public function new(
		kind:String,
		channel:String,
		imagePath:String,
		assetImagePath:String,
		page:Int,
		pages:Int,
		size:AtlasSize,
		frames:Map<String, CharacterAtlasFrame>
	) {
		this.kind = kind;
		this.channel = channel;
		this.imagePath = imagePath;
		this.assetImagePath = assetImagePath;
		this.page = page;
		this.pages = pages;
		this.size = size;
		this.frames = frames;
	}

	public static function load(assetPath:String):CharacterAtlas {
		return parse(Assets.getText(assetPath), assetPath);
	}

	public static function parse(json:String, ?assetPath:String):CharacterAtlas {
		var data:Dynamic = Json.parse(json);
		var imagePath = requiredString(data, "image");
		var frames = parseFrames(requiredObject(data, "frames"));

		return new CharacterAtlas(
			requiredString(data, "kind"),
			requiredString(data, "channel"),
			imagePath,
			resolveSiblingAssetPath(assetPath, imagePath),
			requiredInt(data, "page"),
			requiredInt(data, "pages"),
			parseSize(requiredObject(data, "size"), "size"),
			frames
		);
	}

	public function getFrame(name:String):Null<CharacterAtlasFrame> {
		return frames.get(name);
	}

	public function getFrameNameById(id:Int):Null<String> {
		for (name in frames.keys()) {
			var frame = frames.get(name);
			if (frame != null && frame.id == id) {
				return name;
			}
		}
		return null;
	}

	private static function parseFrames(data:Dynamic):Map<String, CharacterAtlasFrame> {
		var frames:Map<String, CharacterAtlasFrame> = new Map();
		for (name in Reflect.fields(data)) {
			var frameData = Reflect.field(data, name);
			frames.set(name, new CharacterAtlasFrame(
				name,
				requiredInt(frameData, "id", name),
				requiredString(frameData, "png", name),
				requiredInt(frameData, "scale", name),
				parseRect(requiredObject(frameData, "frame", name), '$name.frame'),
				parseSourceTrim(requiredObject(frameData, "sourceTrim", name), '$name.sourceTrim')
			));
		}
		return frames;
	}

	private static function parseRect(data:Dynamic, path:String):AtlasRect {
		return new AtlasRect(
			requiredInt(data, "x", path),
			requiredInt(data, "y", path),
			requiredInt(data, "width", path),
			requiredInt(data, "height", path)
		);
	}

	private static function parseSize(data:Dynamic, path:String):AtlasSize {
		return new AtlasSize(
			requiredInt(data, "width", path),
			requiredInt(data, "height", path)
		);
	}

	private static function parseSourceTrim(data:Dynamic, path:String):AtlasSourceTrim {
		return new AtlasSourceTrim(
			requiredBool(data, "empty", path),
			requiredInt(data, "x", path),
			requiredInt(data, "y", path),
			requiredInt(data, "width", path),
			requiredInt(data, "height", path)
		);
	}

	private static function resolveSiblingAssetPath(?assetPath:String, imagePath:String):String {
		if (assetPath == null) {
			return imagePath;
		}

		var slash = assetPath.lastIndexOf("/");
		if (slash < 0) {
			return imagePath;
		}

		var imageSlash = imagePath.lastIndexOf("/");
		var imageName = imageSlash < 0 ? imagePath : imagePath.substr(imageSlash + 1);
		return assetPath.substr(0, slash + 1) + imageName;
	}

	private static function requiredObject(data:Dynamic, name:String, ?path:String):Dynamic {
		var value:Dynamic = readField(data, name, path);
		if (value == null || Reflect.isObject(value) == false) {
			throw missingMessage(name, path) + " must be an object";
		}
		return value;
	}

	private static function requiredString(data:Dynamic, name:String, ?path:String):String {
		var value:Dynamic = readField(data, name, path);
		if (Std.isOfType(value, String) == false) {
			throw missingMessage(name, path) + " must be a string";
		}
		return cast value;
	}

	private static function requiredBool(data:Dynamic, name:String, ?path:String):Bool {
		var value:Dynamic = readField(data, name, path);
		if (Std.isOfType(value, Bool) == false) {
			throw missingMessage(name, path) + " must be a boolean";
		}
		return cast value;
	}

	private static function requiredInt(data:Dynamic, name:String, ?path:String):Int {
		var value:Dynamic = readField(data, name, path);
		if (Std.isOfType(value, Int) == false && Std.isOfType(value, Float) == false) {
			throw missingMessage(name, path) + " must be a number";
		}
		var number:Float = cast value;
		if (Math.isNaN(number) || number != Math.floor(number)) {
			throw missingMessage(name, path) + " must be an integer";
		}
		return Std.int(number);
	}

	private static function readField(data:Dynamic, name:String, ?path:String):Dynamic {
		if (data == null || Reflect.hasField(data, name) == false) {
			throw missingMessage(name, path) + " is required";
		}
		return Reflect.field(data, name);
	}

	private static function missingMessage(name:String, ?path:String):String {
		return path == null ? name : path + "." + name;
	}
}

class CharacterAtlasFrame {
	public final name:String;
	public final id:Int;
	public final pngPath:String;
	public final scale:Int;
	public final frame:AtlasRect;
	public final sourceTrim:AtlasSourceTrim;

	public function new(name:String, id:Int, pngPath:String, scale:Int, frame:AtlasRect, sourceTrim:AtlasSourceTrim) {
		this.name = name;
		this.id = id;
		this.pngPath = pngPath;
		this.scale = scale;
		this.frame = frame;
		this.sourceTrim = sourceTrim;
	}
}

class AtlasRect {
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
}

class AtlasSize {
	public final width:Int;
	public final height:Int;

	public function new(width:Int, height:Int) {
		this.width = width;
		this.height = height;
	}
}

class AtlasSourceTrim {
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
}
