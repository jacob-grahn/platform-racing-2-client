package com.jiggmin.data;

class SecureData {
	private static var store:SecureStore = new SecureStore();

	private function new() {}

	public static function setNumber(key:String, value:Float):Void {
		store.setNumber(key, value);
	}

	public static function getNumber(key:String):Float {
		return store.getNumber(key);
	}

	public static function setBool(key:String, value:Bool):Void {
		store.setBool(key, value);
	}

	public static function getBool(key:String):Bool {
		return store.getBool(key);
	}

	public static function initEncryptor(keyName:String, salt:String):Void {
		store.initEncryptor(keyName, salt);
	}

	public static function getString(keyName:String):Null<String> {
		return store.getString(keyName);
	}

	public static function hasEntry(key:String):Bool {
		return store.hasEntry(key);
	}

	public static function resetForTests():Void {
		store = new SecureStore();
	}

	public static function storeForTests():SecureStore {
		return store;
	}
}
