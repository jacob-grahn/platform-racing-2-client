package pr2.harness;

import pr2.character.CharacterAppearance.CharacterPartIds;
import pr2.character.CharacterRenderMode;
import StringTools;

class GameplayHarnessOptions {
	private static inline var MAX_HAT_ID:Int = 16;
	private static inline var MAX_CHARACTER_PART_ID:Int = 50;

	public final partIds:CharacterPartIds;
	public final primaryColor:Int;
	public final secondaryColor:Int;
	public final renderMode:CharacterRenderMode;

	public function new(?partIds:CharacterPartIds, ?primaryColor:Int, ?secondaryColor:Int, ?renderMode:CharacterRenderMode) {
		this.partIds = partIds == null ? {hat: 2, head: 1, body: 1, feet: 1} : partIds;
		this.primaryColor = primaryColor == null ? 0x2F86FF : primaryColor;
		this.secondaryColor = secondaryColor == null ? 0xFFCC33 : secondaryColor;
		this.renderMode = renderMode == null ? CharacterRenderMode.Layered : renderMode;
	}

	public static function defaults():GameplayHarnessOptions {
		return new GameplayHarnessOptions();
	}

	public static function parseQuery(query:Null<String>):GameplayHarnessOptions {
		var values = parseQueryValues(query);
		var defaults = GameplayHarnessOptions.defaults();
		return new GameplayHarnessOptions(
			{
				hat: parseBoundedInt(values.get("hat"), defaults.partIds.hat, MAX_HAT_ID),
				head: parseBoundedInt(values.get("head"), defaults.partIds.head, MAX_CHARACTER_PART_ID),
				body: parseBoundedInt(values.get("body"), defaults.partIds.body, MAX_CHARACTER_PART_ID),
				feet: parseBoundedInt(values.get("feet"), defaults.partIds.feet, MAX_CHARACTER_PART_ID)
			},
			parseColor(values.get("primary"), defaults.primaryColor),
			parseColor(values.get("secondary"), defaults.secondaryColor),
			CharacterRenderMode.parse(values.get("render"))
		);
	}

	public function serialize():String {
		return 'hat=${partIds.hat};head=${partIds.head};body=${partIds.body};feet=${partIds.feet};primary=${hexColor(primaryColor)};secondary=${hexColor(secondaryColor)};render=${renderMode.toLabel()}';
	}

	public static function hexColor(color:Int):String {
		return StringTools.hex(color & 0xFFFFFF, 6).toLowerCase();
	}

	private static function parseQueryValues(query:Null<String>):Map<String, String> {
		var values:Map<String, String> = new Map();
		if (query == null) {
			return values;
		}

		var trimmed = StringTools.trim(query);
		if (trimmed == "") {
			return values;
		}
		if (StringTools.startsWith(trimmed, "?")) {
			trimmed = trimmed.substr(1);
		}

		for (part in trimmed.split("&")) {
			if (part == "") {
				continue;
			}
			var equals = part.indexOf("=");
			var rawKey = equals < 0 ? part : part.substr(0, equals);
			var rawValue = equals < 0 ? "" : part.substr(equals + 1);
			var key = StringTools.urlDecode(rawKey).toLowerCase();
			var value = StringTools.urlDecode(rawValue);
			values.set(key, value);
		}
		return values;
	}

	private static function parseBoundedInt(value:Null<String>, fallback:Int, max:Int):Int {
		if (value == null) {
			return fallback;
		}
		var parsed = Std.parseInt(StringTools.trim(value));
		return parsed == null || parsed <= 0 || parsed > max ? fallback : parsed;
	}

	private static function parseColor(value:Null<String>, fallback:Int):Int {
		if (value == null) {
			return fallback;
		}

		var normalized = StringTools.trim(value).toLowerCase();
		if (StringTools.startsWith(normalized, "#")) {
			normalized = normalized.substr(1);
		}
		if (StringTools.startsWith(normalized, "0x")) {
			normalized = normalized.substr(2);
		}
		if (normalized.length != 6) {
			return fallback;
		}

		for (i in 0...normalized.length) {
			var code = normalized.charCodeAt(i);
			var isDigit = code >= "0".code && code <= "9".code;
			var isHexLetter = code >= "a".code && code <= "f".code;
			if (!isDigit && !isHexLetter) {
				return fallback;
			}
		}

		var parsed = Std.parseInt("0x" + normalized);
		return parsed == null ? fallback : parsed;
	}
}
