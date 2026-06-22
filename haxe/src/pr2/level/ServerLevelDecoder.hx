package pr2.level;

import pr2.level.ServerLevel.DecodedBlock;
import pr2.level.ServerLevel.DecodedArtLayer;
import pr2.level.ServerLevel.DecodedArtObject;
import pr2.level.ServerLevel.DecodedDrawAction;
import pr2.level.ServerLevel.DecodedTextObject;
import StringTools;

/**
	Decodes the backtick-delimited `data` blob from a server level into a
	`ServerLevel`. Ported from `GamePage.decodeLevelData` and its helpers
	(`decodeObjectString`, `decodeObjectString2`, `decodeBlockString`).

	Read modes:
	- `m1`: absolute hex coords, base offset in the first token.
	- `m2`: relative coords, segMult 1.
	- `m3`: relative coords, segMult = SEG_SIZE (the common campaign-era format).
	- `m4`: relative coords with a per-block options field, segMult = SEG_SIZE.
**/
class ServerLevelDecoder {
	public static inline var SEG_SIZE:Int = 30;

	public static function decode(rawData:String):ServerLevel {
		if (rawData == null || rawData == "") {
			throw "empty level data";
		}

		var sections = rawData.split("`");
		var mode = sections[0];
		// Flash splices off the mode token, leaving bg color at [0], blocks at
		// [1]; without the splice those are sections[1] and sections[2].
		var bgColor = parseHexColor(section(sections, 1));
		var blockString = section(sections, 2);

		return new ServerLevel(
			bgColor,
			decodeBlocks(mode, blockString),
			decodeArtLayers(mode, sections),
			parseArtBackgroundCode(section(sections, 9))
		);
	}

	public static function decodeBlocks(mode:String, blockString:String):Array<DecodedBlock> {
		return switch (mode) {
			case "m1": decodeObjectStringHex(blockString);
			case "m2": decodeRelative(blockString, 1, false);
			case "m3": decodeRelative(blockString, SEG_SIZE, false);
			case "m4": decodeRelative(blockString, SEG_SIZE, true);
			default: throw 'unsupported level read mode "$mode"';
		};
	}

	public static function decodeArtLayers(mode:String, sections:Array<String>):Array<DecodedArtLayer> {
		return [
			decodeArtLayer(mode, section(sections, 3), section(sections, 6), 1),
			decodeArtLayer(mode, section(sections, 4), section(sections, 7), 0.5),
			decodeArtLayer(mode, section(sections, 5), section(sections, 8), 0.25),
			decodeArtLayer(mode, section(sections, 10), section(sections, 12), 1),
			decodeArtLayer(mode, section(sections, 11), section(sections, 13), 2)
		];
	}

	private static function decodeArtLayer(mode:String, objectString:String, drawString:String, scale:Float):DecodedArtLayer {
		var objects:Array<DecodedArtObject> = [];
		var texts:Array<DecodedTextObject> = [];
		for (entry in decodeArtObjects(mode, objectString)) {
			var text = Std.downcast(entry, DecodedTextObject);
			if (text != null) {
				texts.push(text);
			} else {
				var object = Std.downcast(entry, DecodedArtObject);
				if (object != null) {
					objects.push(object);
				}
			}
		}
		return new DecodedArtLayer(decodeDrawActions(drawString), objects, texts, scale);
	}

	public static function decodeDrawActions(drawString:String):Array<DecodedDrawAction> {
		var actions:Array<DecodedDrawAction> = [];
		if (drawString == null || drawString == "" || drawString == ",") {
			return actions;
		}

		for (entry in drawString.split(",")) {
			if (entry == "") {
				continue;
			}
			var kind = entry.substr(0, 1);
			var data = entry.substr(1);
			switch (kind) {
				case "c":
					actions.push(new DecodedDrawAction(kind, [parseHex(data)]));
				case "t":
					actions.push(new DecodedDrawAction(kind, [parseFloatValue(data)]));
				case "d":
					actions.push(new DecodedDrawAction(kind, data.split(";").map(parseFloatValue)));
				case "m":
					actions.push(new DecodedDrawAction(kind, [], data));
				default:
			}
		}
		return actions;
	}

	public static function decodeArtObjects(mode:String, objectString:String):Array<Dynamic> {
		return switch (mode) {
			case "m1": decodeObjectStringHexArt(objectString);
			case "m2" | "m3" | "m4": decodeRelativeArt(objectString);
			default: [];
		}
	}

	/**
		Port of `decodeObjectString2` (m2/m3) and `decodeBlockString` (m4), which
		share a relative-coordinate walk. `withOptions` mirrors the m4 path where
		`thisBlock[3]` is a raw per-block option string; the m2/m3 path instead
		treats trailing fields as width/height percentages, which blocks never use.
	**/
	private static function decodeRelative(blockString:String, segMult:Int, withOptions:Bool):Array<DecodedBlock> {
		var blocks:Array<DecodedBlock> = [];
		if (blockString == null || blockString == "") {
			return blocks;
		}

		var entries = blockString.split(",");
		var code = 0;
		var currentX = 0;
		var currentY = 0;

		for (entry in entries) {
			var parts = entry.split(";");
			currentX += intPart(parts, 0);
			currentY += intPart(parts, 1);

			// A text object (`t`) advances the cursor but is not a block.
			if (part(parts, 2) == "t") {
				continue;
			}

			if (withOptions) {
				if (part(parts, 2) != null) {
					code = intPart(parts, 2);
				}
				var opts = part(parts, 3);
				blocks.push(new DecodedBlock(ObjectCodes.resolveBlockCode(code), currentX * segMult, currentY * segMult, opts == null ? "" : opts));
			} else {
				// In decodeObjectString2 a new object code only appears when there
				// is no width/height pair, i.e. exactly three fields.
				if (part(parts, 4) == null && part(parts, 3) == null && part(parts, 2) != null) {
					code = intPart(parts, 2);
				}
				blocks.push(new DecodedBlock(ObjectCodes.resolveBlockCode(code), currentX * segMult, currentY * segMult));
			}
		}

		return blocks;
	}

	/** Port of `decodeObjectString` (m1): hex coords with a leading base offset. **/
	private static function decodeObjectStringHex(blockString:String):Array<DecodedBlock> {
		var blocks:Array<DecodedBlock> = [];
		if (blockString == null || blockString == "") {
			return blocks;
		}

		var entries = blockString.split(",");
		var base = entries.shift().split(";");
		var baseX = parseHex(part(base, 0));
		var baseY = parseHex(part(base, 1));

		for (entry in entries) {
			var parts = entry.split(";");
			var code = parseHex(part(parts, 0));
			var x = parseHex(part(parts, 1)) + baseX;
			var y = parseHex(part(parts, 2)) + baseY;
			blocks.push(new DecodedBlock(ObjectCodes.resolveBlockCode(code), x, y));
		}

		return blocks;
	}

	private static function decodeObjectStringHexArt(objectString:String):Array<Dynamic> {
		var objects:Array<Dynamic> = [];
		if (objectString == null || objectString == "") {
			return objects;
		}

		var entries = objectString.split(",");
		var base = entries.shift().split(";");
		var baseX = parseHex(part(base, 0));
		var baseY = parseHex(part(base, 1));

		for (entry in entries) {
			var parts = entry.split(";");
			var scaleX = part(parts, 3) == null ? 1 : parseHex(part(parts, 3)) / 100;
			var scaleY = part(parts, 4) == null ? 1 : parseHex(part(parts, 4)) / 100;
			objects.push(new DecodedArtObject(parseHex(part(parts, 0)), parseHex(part(parts, 1)) + baseX, parseHex(part(parts, 2)) + baseY, scaleX, scaleY));
		}

		return objects;
	}

	private static function decodeRelativeArt(objectString:String):Array<Dynamic> {
		var objects:Array<Dynamic> = [];
		if (objectString == null || objectString == "") {
			return objects;
		}

		var objectCode = 0;
		var currentX = 0;
		var currentY = 0;

		for (entry in objectString.split(",")) {
			var parts = entry.split(";");
			currentX += intPart(parts, 0);
			currentY += intPart(parts, 1);

			if (part(parts, 2) == "t") {
				objects.push(new DecodedTextObject(
					part(parts, 3) == null ? "" : part(parts, 3),
					currentX,
					currentY,
					intPart(parts, 4),
					intPart(parts, 5) / 100,
					intPart(parts, 6) / 100
				));
			} else {
				var scaleX = 1.0;
				var scaleY = 1.0;
				if (part(parts, 4) != null) {
					objectCode = intPart(parts, 2);
					scaleX = intPart(parts, 3) / 100;
					scaleY = intPart(parts, 4) / 100;
				} else if (part(parts, 3) != null) {
					scaleX = intPart(parts, 2) / 100;
					scaleY = intPart(parts, 3) / 100;
				} else if (part(parts, 2) != null) {
					objectCode = intPart(parts, 2);
				}
				objects.push(new DecodedArtObject(objectCode, currentX, currentY, scaleX, scaleY));
			}
		}

		return objects;
	}

	private static function section(sections:Array<String>, index:Int):String {
		return index < sections.length ? sections[index] : "";
	}

	private static function part(parts:Array<String>, index:Int):Null<String> {
		return index < parts.length ? parts[index] : null;
	}

	/** `Number(s)` semantics: empty/missing -> 0, otherwise numeric value. **/
	private static function intPart(parts:Array<String>, index:Int):Int {
		var value = part(parts, index);
		if (value == null || value == "") {
			return 0;
		}
		var parsed = Std.parseFloat(value);
		return Math.isNaN(parsed) ? 0 : Std.int(parsed);
	}

	private static function parseHex(hex:Null<String>):Int {
		if (hex == null || hex == "") {
			return 0;
		}
		var parsed = Std.parseInt("0x" + hex);
		return parsed == null ? 0 : parsed;
	}

	private static function parseHexColor(hex:String):Int {
		return parseHex(hex);
	}

	private static function parseArtBackgroundCode(value:String):Null<Int> {
		if (value == null || value == "" || value == "-1" || value == "Square") {
			return null;
		}
		if (StringTools.startsWith(value, "BG")) {
			return 200 + intPart([value.substr(2)], 0);
		}
		var parsed = Std.parseInt(value);
		return parsed == null || parsed < 0 ? null : parsed;
	}

	private static function parseFloatValue(value:String):Float {
		if (value == null || value == "") {
			return 0;
		}
		var parsed = Std.parseFloat(value);
		return Math.isNaN(parsed) ? 0 : parsed;
	}
}
