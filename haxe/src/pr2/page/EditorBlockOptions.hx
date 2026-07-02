package pr2.page;

import pr2.gameplay.Items;
import pr2.level.BlockType;

/**
	Flash-compatible option string handling for editor block option popups.

	The visual popups are wired separately; this class owns the shared
	`Block.applyOptions` semantics those popups commit on close.
**/
class EditorBlockOptions {
	public static inline var TELEPORT_DEFAULT_COLOR:Int = 0xFF7F50;

	public static function hasOptions(type:BlockType):Bool {
		return switch (type) {
			case Item | InfiniteItem | Teleport | Happy | Sad | CustomStats: true;
			default: false;
		};
	}

	public static function applyItemOptions(selected:Array<Int>, levelAllowed:Array<Int>):String {
		var next = sortedValidItems(selected);
		var allowed = sortedValidItems(levelAllowed);
		if (sameItems(next, allowed)) {
			return "";
		}
		return next.length == 0 ? "none" : next.join("-");
	}

	public static function selectedItems(options:String, levelAllowed:Array<Int>):Array<Int> {
		if (options == "") {
			return sortedValidItems(levelAllowed);
		}
		if (options == "none") {
			return [];
		}
		return sortedValidItems(parseIntList(options));
	}

	public static function applyTeleportColor(color:Int):String {
		return color == TELEPORT_DEFAULT_COLOR ? "" : Std.string(color);
	}

	public static function teleportColor(options:String):Int {
		var parsed = Std.parseInt(options);
		return parsed == null ? TELEPORT_DEFAULT_COLOR : parsed;
	}

	public static function applyStatChange(type:BlockType, amount:Int):String {
		var sad = type == Sad;
		var clamped = sad ? clamp(amount, -100, -5) : clamp(amount, 5, 100);
		return clamped == (sad ? -5 : 5) ? "" : Std.string(clamped);
	}

	public static function statChange(type:BlockType, options:String):Int {
		var sad = type == Sad;
		var parsed = Std.parseInt(options);
		var fallback = sad ? -5 : 5;
		if (parsed == null) {
			return fallback;
		}
		return sad ? clamp(parsed, -100, -5) : clamp(parsed, 5, 100);
	}

	public static function applyCustomStats(reset:Bool, speed:Int, acceleration:Int, jump:Int):String {
		if (reset) {
			return "reset";
		}
		var values = [clamp(speed, 0, 100), clamp(acceleration, 0, 100), clamp(jump, 0, 100)];
		return values[0] == 50 && values[1] == 50 && values[2] == 50 ? "" : values.join("-");
	}

	public static function customStats(options:String):Array<Int> {
		if (options == "" || options == "reset") {
			return [50, 50, 50];
		}
		var values = parseIntList(options);
		return [
			clamp(valueAt(values, 0, 50), 0, 100),
			clamp(valueAt(values, 1, 50), 0, 100),
			clamp(valueAt(values, 2, 50), 0, 100)
		];
	}

	private static function sortedValidItems(values:Array<Int>):Array<Int> {
		var valid = Items.getAllCodes();
		var out:Array<Int> = [];
		if (values != null) {
			for (value in values) {
				if (valid.indexOf(value) >= 0 && out.indexOf(value) < 0) {
					out.push(value);
				}
			}
		}
		out.sort(function(a, b) return a - b);
		return out;
	}

	private static function sameItems(a:Array<Int>, b:Array<Int>):Bool {
		if (a.length != b.length) {
			return false;
		}
		for (i in 0...a.length) {
			if (a[i] != b[i]) {
				return false;
			}
		}
		return true;
	}

	private static function parseIntList(value:String):Array<Int> {
		var out:Array<Int> = [];
		if (value == null || value == "") {
			return out;
		}
		for (part in value.split("-")) {
			var parsed = Std.parseInt(part);
			if (parsed != null) {
				out.push(parsed);
			}
		}
		return out;
	}

	private static inline function valueAt(values:Array<Int>, index:Int, fallback:Int):Int {
		return index < values.length ? values[index] : fallback;
	}

	private static inline function clamp(value:Int, min:Int, max:Int):Int {
		return Std.int(Math.max(min, Math.min(max, value)));
	}
}
