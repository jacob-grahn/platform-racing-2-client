package pr2.lobby;

import com.jiggmin.data.SecureData as JiggminSecureData;

/**
	Port of the Flash `com.jiggmin.data.SecureData` numeric/string store.
**/
class SecureData {
	private static var compatibilityStrings:Map<String, String> = new Map();

	private function new() {}

	public static function getNumber(key:String, fallback:Float = 0):Float {
		return JiggminSecureData.hasEntry(key) ? JiggminSecureData.getNumber(key) : fallback;
	}

	public static function setNumber(key:String, value:Float):Void {
		JiggminSecureData.setNumber(key, value);
	}

	public static function getBool(key:String):Bool {
		return JiggminSecureData.getBool(key);
	}

	public static function setBool(key:String, value:Bool):Void {
		JiggminSecureData.setBool(key, value);
	}

	public static function initEncryptor(keyName:String, salt:String):Void {
		JiggminSecureData.initEncryptor(keyName, salt);
	}

	public static function getString(keyName:String):Null<String> {
		return JiggminSecureData.getString(keyName);
	}

	public static function getStringValue(key:String, fallback:String = ""):String {
		var encryptedValue = getString(key);
		if (encryptedValue != null) return encryptedValue;
		return compatibilityStrings.exists(key) ? compatibilityStrings.get(key) : fallback;
	}

	public static function setStringValue(key:String, value:String):Void {
		compatibilityStrings.set(key, value);
	}

	public static function clear():Void {
		JiggminSecureData.resetForTests();
		compatibilityStrings = new Map();
	}
}
