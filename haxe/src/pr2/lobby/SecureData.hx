package pr2.lobby;

/**
	Port of the Flash `com.jiggmin.data.SecureData` numeric/string store.

	The original obfuscated values to discourage trivial memory editing; for the
	port the important behavior is just a typed key/value store shared across
	lobby pages (`userRank` is the main user, set by Account and read by level
	listings for access checks). Obfuscation can be layered in later without
	changing callers.
**/
class SecureData {
	private static var numbers:Map<String, Float> = new Map();
	private static var strings:Map<String, String> = new Map();

	private function new() {}

	public static function getNumber(key:String, fallback:Float = 0):Float {
		return numbers.exists(key) ? numbers.get(key) : fallback;
	}

	public static function setNumber(key:String, value:Float):Void {
		numbers.set(key, value);
	}

	public static function getStringValue(key:String, fallback:String = ""):String {
		return strings.exists(key) ? strings.get(key) : fallback;
	}

	public static function setStringValue(key:String, value:String):Void {
		strings.set(key, value);
	}

	public static function clear():Void {
		numbers = new Map();
		strings = new Map();
	}
}
