package pr2.lobby.account;

/**
	Small persistence shim for the bits of Flash `com.jiggmin.data.Settings` the
	Account tab needs (loadout presets). Values are kept in memory and, when a
	`SharedObject` is available (HTML5 / desktop), mirrored to local storage so
	loadouts survive a reload — matching the original `SharedObject`-backed store.
	Tests run against the in-memory map without touching local storage.
**/
class Settings {
	public static inline var PRESETS:String = "presets";

	private static final values:Map<String, Dynamic> = new Map();
	private static var loaded:Bool = false;

	private function new() {}

	public static function getValue(key:String, defaultValue:Dynamic):Dynamic {
		ensureLoaded();
		return values.exists(key) ? values.get(key) : defaultValue;
	}

	public static function setValue(key:String, value:Dynamic):Void {
		ensureLoaded();
		values.set(key, value);
		persist();
	}

	/** Test hook: drop the in-memory cache so a fresh load can be exercised. */
	public static function reset():Void {
		values.clear();
		loaded = false;
	}

	private static function ensureLoaded():Void {
		if (loaded) {
			return;
		}
		loaded = true;
		try {
			var so = openfl.net.SharedObject.getLocal("pr2settings");
			var data:Dynamic = so.data;
			if (data != null && Reflect.field(data, "json") != null) {
				var parsed:Dynamic = haxe.Json.parse(Reflect.field(data, "json"));
				for (field in Reflect.fields(parsed)) {
					values.set(field, Reflect.field(parsed, field));
				}
			}
		} catch (_:Dynamic) {
			// No persistent store available (e.g. test interp); stay in memory.
		}
	}

	private static function persist():Void {
		try {
			var obj:Dynamic = {};
			for (key in values.keys()) {
				Reflect.setField(obj, key, values.get(key));
			}
			var so = openfl.net.SharedObject.getLocal("pr2settings");
			Reflect.setField(so.data, "json", haxe.Json.stringify(obj));
			so.flush();
		} catch (_:Dynamic) {
			// Best-effort; in-memory copy still serves this session.
		}
	}
}
