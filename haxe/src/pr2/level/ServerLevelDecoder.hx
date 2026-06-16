package pr2.level;

import pr2.level.ServerLevel.DecodedBlock;

/**
	Decodes the backtick-delimited `data` blob from a server level into a
	`ServerLevel`. Ported from `GamePage.decodeLevelData` and its helpers
	(`decodeObjectString`, `decodeObjectString2`, `decodeBlockString`).

	Only the block layer is decoded here (Bit 3). Art/draw/text layers live in
	the other backtick sections and are deferred to the rendering work.

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

		return new ServerLevel(bgColor, decodeBlocks(mode, blockString));
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
}
