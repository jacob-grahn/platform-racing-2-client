package pr2.lobby.account;

class Settings {
	public static inline var PRESETS:String = "presets";
	public static inline var DISABLED_SONGS:String = "disabledSongs";
	public static inline var MUSIC_VOLUME:String = "musicLevel";
	public static inline var SOUND_VOLUME:String = "soundLevel";
	public static inline var DRAW_ART:String = "drawArt";
	public static inline var ART_LOSSLESS_QUALITY:String = "losslessQuality";
	public static inline var FILTER_SWEARS:String = "filterSwears";
	public static inline var ALTERNATE_CONTROLS:String = "altCtrl";
	public static inline var LE_TEST_STATS:String = "leTestStats";
	public static inline var LE_TEST_HAT:String = "leTestHat";

	public static final DEFAULT_ALT_CONTROLS:Dynamic = {up: 87, right: 68, down: 83, left: 65, item: 73};
	public static final DEFAULT_LE_TEST_STATS:Dynamic = {speed: 50, acceleration: 50, jumping: 50};

	public static var presets:Dynamic = null;
	public static var musicLevel:Int = 100;
	public static var soundLevel:Int = 100;
	public static var drawArt:Bool = true;
	public static var losslessQuality:Bool = false;
	public static var filterSwears:Bool = true;
	public static var altCtrl:Dynamic = cloneObject(DEFAULT_ALT_CONTROLS);
	public static var leTestStats:Dynamic = cloneObject(DEFAULT_LE_TEST_STATS);
	public static var leTestHat:Int = 2;
	private static var disabledSongsValue:Array<Dynamic> = [];

	private static final SETTINGS:Array<String> = [
		PRESETS,
		DISABLED_SONGS,
		MUSIC_VOLUME,
		SOUND_VOLUME,
		DRAW_ART,
		ART_LOSSLESS_QUALITY,
		FILTER_SWEARS,
		ALTERNATE_CONTROLS,
		LE_TEST_STATS,
		LE_TEST_HAT,
	];

	private static var userName:Null<String>;
	private static var dataArr:Null<Dynamic>;
	private static var persistenceEnabled:Bool = true;
	private static var memoryStoresForTests:Null<Map<String, Dynamic>>;

	private function new() {}

	public static function init(s:String = ""):Void {
		userName = storeName(s);
		dataArr = {};
		try {
			var data = readStore(userName);
			if (data != null) {
				for (setting in Reflect.fields(data)) {
					setStaticAndData(setting, Reflect.field(data, setting));
				}
			}
		} catch (_:Dynamic) {}
		for (setting in SETTINGS) {
			if (Reflect.field(dataArr, setting) == null && staticValue(setting) != null) {
				Reflect.setField(dataArr, setting, cloneSetting(setting, staticValue(setting)));
			}
		}
	}

	public static function clear():Void {
		userName = null;
		dataArr = null;
	}

	public static function isNameSet():Bool {
		return userName != null;
	}

	public static function setValue(setting:String, value:Dynamic):Void {
		ensureSessionData();
		if (setting == ALTERNATE_CONTROLS) {
			handleObjectPatch(setting, value, DEFAULT_ALT_CONTROLS);
			return;
		}
		if (setting == LE_TEST_STATS) {
			handleObjectPatch(setting, value, DEFAULT_LE_TEST_STATS);
			return;
		}
		value = normalizeValue(setting, value);
		if (Reflect.field(dataArr, setting) != value || staticValue(setting) != value) {
			setStaticAndData(setting, value);
			saveField(setting, value);
		}
	}

	public static function getValue(setting:String, value:Dynamic = null):Dynamic {
		ensureSessionData();
		var dataValue = Reflect.field(dataArr, setting);
		var currentStatic = staticValue(setting);
		if (dataValue == null || currentStatic == null) {
			if (dataValue == null && currentStatic != null) {
				Reflect.setField(dataArr, setting, cloneSetting(setting, currentStatic));
			} else if (currentStatic == null && dataValue != null) {
				setStaticValue(setting, cloneSetting(setting, dataValue));
			}
		}
		if (Reflect.field(dataArr, setting) == null) {
			setStaticAndData(setting, value);
		}
		return Reflect.field(dataArr, setting);
	}

	public static function disabledSongs():Array<String> {
		var value:Dynamic = getValue(DISABLED_SONGS, []);
		if (value == null) return [];
		return [for (song in (cast value:Array<Dynamic>)) Std.string(song)];
	}

	public static function reset():Void {
		resetDefaults();
		clear();
	}

	public static function disablePersistenceForTests():Void {
		persistenceEnabled = false;
		memoryStoresForTests = null;
		resetDefaults();
		clear();
	}

	public static function useMemoryStoreForTests():Void {
		persistenceEnabled = true;
		memoryStoresForTests = [];
		resetDefaults();
		clear();
	}

	public static function seedRawStoreForTests(name:String, data:Dynamic):Void {
		if (memoryStoresForTests == null) memoryStoresForTests = [];
		memoryStoresForTests.set(storeName(name), data);
	}

	public static function rawStoreForTests(name:String):Dynamic {
		return memoryStoresForTests == null ? null : memoryStoresForTests.get(storeName(name));
	}

	public static function dataFieldForTests(setting:String):Dynamic {
		return dataArr == null ? null : Reflect.field(dataArr, setting);
	}

	public static function storeNameForTests(name:String):String {
		return storeName(name);
	}

	private static function handleObjectPatch(setting:String, patch:Dynamic, defaults:Dynamic):Void {
		if (!canSaveCookie()) return;
		var current = Reflect.field(dataArr, setting);
		if (current == null) current = cloneObject(defaults);
		var rawStore = readStore(userName);
		var rawObject = Reflect.field(rawStore, setting);
		if (rawObject == null) rawObject = cloneObject(defaults);
		for (field in Reflect.fields(patch)) {
			var value = Reflect.field(patch, field);
			Reflect.setField(rawObject, field, value);
			Reflect.setField(current, field, value);
		}
		setStaticValue(setting, current);
		Reflect.setField(dataArr, setting, current);
		Reflect.setField(rawStore, setting, rawObject);
		writeStore(userName, rawStore);
	}

	private static function canSaveCookie():Bool {
		if (!persistenceEnabled || !isNameSet()) return false;
		try {
			if (memoryStoresForTests != null) {
				if (!memoryStoresForTests.exists(userName)) memoryStoresForTests.set(userName, {});
				return true;
			}
			var cookie = openfl.net.SharedObject.getLocal(userName);
			cookie.flush();
		} catch (_:Dynamic) {
			return false;
		}
		return true;
	}

	private static function saveField(setting:String, value:Dynamic):Void {
		if (!canSaveCookie()) return;
		var rawStore = readStore(userName);
		Reflect.setField(rawStore, setting, cloneSetting(setting, value));
		writeStore(userName, rawStore);
	}

	private static function readStore(name:String):Dynamic {
		if (memoryStoresForTests != null) {
			if (!memoryStoresForTests.exists(name)) memoryStoresForTests.set(name, {});
			return memoryStoresForTests.get(name);
		}
		var cookie = openfl.net.SharedObject.getLocal(name);
		return cookie.data;
	}

	private static function writeStore(name:String, data:Dynamic):Void {
		if (memoryStoresForTests != null) {
			memoryStoresForTests.set(name, data);
			return;
		}
		var cookie = openfl.net.SharedObject.getLocal(name);
		for (field in Reflect.fields(data)) {
			Reflect.setField(cookie.data, field, Reflect.field(data, field));
		}
		cookie.flush();
	}

	private static function ensureSessionData():Void {
		if (dataArr == null) dataArr = {};
	}

	private static function setStaticAndData(setting:String, value:Dynamic):Void {
		value = normalizeValue(setting, value);
		setStaticValue(setting, cloneSetting(setting, value));
		if (dataArr != null) Reflect.setField(dataArr, setting, cloneSetting(setting, value));
	}

	private static function staticValue(setting:String):Dynamic {
		return switch (setting) {
			case PRESETS: presets;
			case DISABLED_SONGS: disabledSongsValue;
			case MUSIC_VOLUME: musicLevel;
			case SOUND_VOLUME: soundLevel;
			case DRAW_ART: drawArt;
			case ART_LOSSLESS_QUALITY: losslessQuality;
			case FILTER_SWEARS: filterSwears;
			case ALTERNATE_CONTROLS: altCtrl;
			case LE_TEST_STATS: leTestStats;
			case LE_TEST_HAT: leTestHat;
			default: null;
		}
	}

	private static function setStaticValue(setting:String, value:Dynamic):Void {
		switch (setting) {
			case PRESETS:
				presets = value;
			case DISABLED_SONGS:
				disabledSongsValue = value == null ? [] : cast value;
			case MUSIC_VOLUME:
				musicLevel = cast value;
			case SOUND_VOLUME:
				soundLevel = cast value;
			case DRAW_ART:
				drawArt = value;
			case ART_LOSSLESS_QUALITY:
				losslessQuality = value;
			case FILTER_SWEARS:
				filterSwears = value;
			case ALTERNATE_CONTROLS:
				altCtrl = value;
			case LE_TEST_STATS:
				leTestStats = value;
			case LE_TEST_HAT:
				leTestHat = cast value;
			default:
		}
	}

	private static function normalizeValue(setting:String, value:Dynamic):Dynamic {
		if (setting == MUSIC_VOLUME || setting == SOUND_VOLUME) {
			var number = Std.parseInt(Std.string(value));
			return number == null ? 100 : Std.int(Math.max(0, Math.min(100, number)));
		}
		if (setting == ALTERNATE_CONTROLS) return mergeDefaults(DEFAULT_ALT_CONTROLS, value);
		if (setting == LE_TEST_STATS) return mergeDefaults(DEFAULT_LE_TEST_STATS, value);
		if (setting == DISABLED_SONGS && value == null) return [];
		return value;
	}

	private static function cloneSetting(setting:String, value:Dynamic):Dynamic {
		if (setting == ALTERNATE_CONTROLS || setting == LE_TEST_STATS) return cloneObject(value);
		if (setting == DISABLED_SONGS && value != null) return (cast value:Array<Dynamic>).copy();
		return value;
	}

	private static function mergeDefaults(defaults:Dynamic, value:Dynamic):Dynamic {
		var result = cloneObject(defaults);
		if (value != null) {
			for (field in Reflect.fields(value)) {
				Reflect.setField(result, field, Reflect.field(value, field));
			}
		}
		return result;
	}

	private static function cloneObject(source:Dynamic):Dynamic {
		var result:Dynamic = {};
		if (source != null) {
			for (field in Reflect.fields(source)) {
				Reflect.setField(result, field, Reflect.field(source, field));
			}
		}
		return result;
	}

	private static function resetDefaults():Void {
		presets = null;
		disabledSongsValue = [];
		musicLevel = 100;
		soundLevel = 100;
		drawArt = true;
		losslessQuality = false;
		filterSwears = true;
		altCtrl = cloneObject(DEFAULT_ALT_CONTROLS);
		leTestStats = cloneObject(DEFAULT_LE_TEST_STATS);
		leTestHat = 2;
		dataArr = null;
		userName = null;
	}

	private static function storeName(name:String):String {
		return "pr2_" + ~/\W+/g.replace(name == null ? "" : name, "");
	}
}
