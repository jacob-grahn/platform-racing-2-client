package com.jiggmin.data;

import com.hurlant.crypto.symmetric.AESKey;
import com.hurlant.crypto.symmetric.CBCMode;
import com.hurlant.util.Base64;
import pr2.crypto.ByteArrayCompat;

/**
	Flash-compatible `com.jiggmin.data.Encryptor` wrapper used by PR2 UI and
	protocol code.
**/
class Encryptor {
	private var mode:Null<CBCMode>;
	private var iv:Null<String>;

	public function new() {}

	public function setKey(s:String):Void {
		var byteArr = stringToByteArray(s);
		var pad = new AESPad();
		var key = new AESKey(byteArr);
		mode = new CBCMode(key, pad);
	}

	public function setIV(s:String):Void {
		var byteArr = stringToByteArray(s);
		ensureMode().IV = byteArr;
		iv = s;
	}

	public function encrypt(s:String):String {
		var byteArr = new ByteArrayCompat();
		byteArr.writeUTFBytes(s);
		ensureMode().encrypt(byteArr);
		return byteArrayToString(byteArr);
	}

	public function decrypt(s:String):String {
		var byteArr = stringToByteArray(s);
		ensureMode().decrypt(byteArr);
		byteArr.position = 0;
		return byteArr.toBytes().toString();
	}

	public function remove():Void {
		if (mode != null) {
			mode.dispose();
			mode = null;
		}
		iv = null;
	}

	private function byteArrayToString(a:ByteArrayCompat):String {
		return Base64.encodeByteArray(a);
	}

	private function stringToByteArray(s:String):ByteArrayCompat {
		return Base64.decodeToByteArray(s);
	}

	private function ensureMode():CBCMode {
		if (mode == null) {
			throw "Encryptor key has not been set";
		}
		return mode;
	}
}
