package pr2.util;

/**
	Helpers for reading loosely-typed fields off a `Dynamic` (JSON-ish server
	payloads, XFL attribute bags) with a fallback when the field is absent or
	null. Consolidates the identical per-field reflection helpers that had been
	copied into PR2MovieClip (static text attrs) and the lobby popups (server
	`ret` objects).
**/
class Dyn {
	public static function string(data:Dynamic, name:String, ?fallback:String):String {
		if (data == null) {
			return fallback;
		}
		var value:Dynamic = Reflect.field(data, name);
		return value == null ? fallback : Std.string(value);
	}

	public static function int(data:Dynamic, name:String, fallback:Int = 0):Int {
		if (data == null) {
			return fallback;
		}
		var value:Dynamic = Reflect.field(data, name);
		if (value == null) {
			return fallback;
		}
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
			return Std.int(value);
		}
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? fallback : parsed;
	}

	public static function float(data:Dynamic, name:String, fallback:Float = 0):Float {
		if (data == null) {
			return fallback;
		}
		var value:Dynamic = Reflect.field(data, name);
		if (value == null) {
			return fallback;
		}
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
			return value;
		}
		var parsed = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	public static function floatOrNull(data:Dynamic, name:String):Null<Float> {
		if (data == null) {
			return null;
		}
		var value:Dynamic = Reflect.field(data, name);
		if (value == null) {
			return null;
		}
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
			return value;
		}
		var parsed = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? null : parsed;
	}

	public static function bool(data:Dynamic, name:String, fallback:Bool = false):Bool {
		if (data == null) {
			return fallback;
		}
		var value:Dynamic = Reflect.field(data, name);
		if (value == null) {
			return fallback;
		}
		if (Std.isOfType(value, Bool)) {
			return value;
		}
		var text = Std.string(value).toLowerCase();
		return text == "true" || text == "1";
	}
}
