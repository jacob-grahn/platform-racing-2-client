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
	public static inline var DISABLED_SONGS:String = "disabledSongs";
	public static inline var MUSIC_VOLUME:String = "musicLevel";
	public static inline var SOUND_VOLUME:String = "soundLevel";
	public static inline var DRAW_ART:String = "drawArt";
	public static inline var ART_LOSSLESS_QUALITY:String = "losslessQuality";
	public static inline var FILTER_SWEARS:String = "filterSwears";
	public static inline var ALTERNATE_CONTROLS:String = "altCtrl";
	public static final DEFAULT_ALT_CONTROLS:Dynamic = {up: 87, right: 68, down: 83, left: 65, item: 73};

	public static var musicLevel(default, null):Int = 100;
	public static var soundLevel(default, null):Int = 100;

	private static final values:Map<String, Dynamic> = new Map();
	private static var loaded:Bool = false;
	private static var persistenceEnabled:Bool = true;

	private function new() {}

	public static function getValue(key:String, defaultValue:Dynamic):Dynamic {
		ensureLoaded();
		return values.exists(key) ? values.get(key) : defaultValue;
	}

	public static function setValue(key:String, value:Dynamic):Void {
		ensureLoaded();
		value = normalizeValue(key, value);
		values.set(key, value);
		applyTypedValue(key, value);
		persist();
	}

	public static function disabledSongs():Array<String> {
		var value:Dynamic = getValue(DISABLED_SONGS, []);
		return value == null ? [] : cast value;
	}

	/** Test hook: drop the in-memory cache so a fresh load can be exercised. */
	public static function reset():Void {
		values.clear();
		loaded = false;
	}

	/** Prevent interpreter tests from creating a local SharedObject on disk. */
	public static function disablePersistenceForTests():Void {
		persistenceEnabled = false;
		values.clear();
		loaded = true;
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
					var value = normalizeValue(field, Reflect.field(parsed, field));
					values.set(field, value);
					applyTypedValue(field, value);
				}
			}
		} catch (_:Dynamic) {
			// No persistent store available (e.g. test interp); stay in memory.
		}
	}

	private static function normalizeValue(key:String, value:Dynamic):Dynamic {
		if (key == MUSIC_VOLUME || key == SOUND_VOLUME) {
			var number = Std.parseInt(Std.string(value));
			return number == null ? 100 : Std.int(Math.max(0, Math.min(100, number)));
		}
		return value;
	}

	private static function applyTypedValue(key:String, value:Dynamic):Void {
		if (key == MUSIC_VOLUME) musicLevel = cast value;
		if (key == SOUND_VOLUME) soundLevel = cast value;
	}

	private static function persist():Void {
		if (!persistenceEnabled) return;
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
