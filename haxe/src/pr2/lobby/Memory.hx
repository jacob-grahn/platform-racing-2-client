package pr2.lobby;

/**
	Port of the Flash `com.jiggmin.data.Memory` global runtime cache.

	In AS3 this was a single shared `Object` (`Memory.memory`) used as a loosely
	typed scratchpad that survived for the lifetime of the session but not across
	reloads: chat room selection, `coursePageNum<mode>`, `campaignInfo<page>`,
	persisted search state, etc. Lobby pages read and write it by string key.
**/
class Memory {
	private static var store:Map<String, Dynamic> = new Map();

	private function new() {}

	public static function get(key:String):Dynamic {
		return store.exists(key) ? store.get(key) : null;
	}

	public static function set(key:String, value:Dynamic):Void {
		store.set(key, value);
	}

	public static function has(key:String):Bool {
		return store.exists(key);
	}

	public static function getInt(key:String, fallback:Int = 0):Int {
		var value = get(key);
		if (value == null) {
			return fallback;
		}
		if (Std.isOfType(value, Int)) {
			return value;
		}
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? fallback : parsed;
	}

	public static function getString(key:String, fallback:String = ""):String {
		var value = get(key);
		return value == null ? fallback : Std.string(value);
	}

	public static function clear():Void {
		store = new Map();
	}
}
