package com.adobe.crypto;

import haxe.crypto.Md5;
import pr2.crypto.ByteArrayCompat;

class MD5 {
	public static var digest:ByteArrayCompat;

	public static function hash(value:String):String {
		var bytes = new ByteArrayCompat();
		bytes.writeUTFBytes(value);
		return hashBinary(bytes);
	}

	public static function hashBytes(bytes:ByteArrayCompat):String {
		return hashBinary(bytes);
	}

	public static function hashBinary(bytes:ByteArrayCompat):String {
		var savedPosition = bytes.position;
		var savedEndian = bytes.endian;
		var savedLength = bytes.length;
		var raw = Md5.make(bytes.toBytes());
		digest = ByteArrayCompat.fromBytes(raw);
		bytes.position = savedPosition;
		bytes.endian = savedEndian;
		bytes.length = savedLength;
		return raw.toHex();
	}
}
