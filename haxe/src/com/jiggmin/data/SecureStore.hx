package com.jiggmin.data;

import com.hurlant.util.Base64;
import haxe.DynamicAccess;

typedef SecureStoreEntry = {
	var hidden:Dynamic;
	var key:Dynamic;
}

class SecureStore {
	private var items:Null<DynamicAccess<SecureStoreEntry>> = {};

	public function new() {}

	public function setNumber(key:String, value:Float):Void {
		var hiddenKey = Math.ceil(Math.random() * 999999) - 500000;
		setEntry(key, value + hiddenKey, hiddenKey);
	}

	public function getNumber(key:String):Float {
		var entry = getEntry(key);
		return entry == null ? 0 : (entry.hidden:Float) - (entry.key:Float);
	}

	public function setBool(key:String, value:Bool):Void {
		setNumber(key, value ? 1 : 0);
	}

	public function getBool(key:String):Bool {
		return getNumber(key) == 1;
	}

	public function initEncryptor(keyName:String, salt:String):Void {
		var encryptor = new Encryptor();
		encryptor.setKey(Base64.encode(Data.randomString(16)));
		encryptor.setIV(Base64.encode(Data.randomString(16)));
		setEntry(keyName, encryptor.encrypt(salt), encryptor);
	}

	public function getString(keyName:String):Null<String> {
		var entry = getEntry(keyName);
		if (entry == null) return null;
		return (entry.key:Encryptor).decrypt(entry.hidden);
	}

	public function remove():Void {
		items = null;
	}

	public function entryForTests(key:String):Null<SecureStoreEntry> {
		return getEntry(key);
	}

	public function hasEntry(key:String):Bool {
		return getEntry(key) != null;
	}

	private function setEntry(key:String, hidden:Dynamic, entryKey:Dynamic):Void {
		if (items == null) return;
		var entry = getEntry(key);
		if (entry != null) {
			entry.hidden = hidden;
			entry.key = entryKey;
		} else {
			items.set(key, {hidden: hidden, key: entryKey});
		}
	}

	private function getEntry(key:String):Null<SecureStoreEntry> {
		return items == null ? null : items.get(key);
	}
}
