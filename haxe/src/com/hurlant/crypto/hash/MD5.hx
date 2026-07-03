package com.hurlant.crypto.hash;

import haxe.crypto.Md5 as HaxeMd5;
import pr2.crypto.ByteArrayCompat;

class MD5 implements IHash {
	public static inline var HASH_SIZE:Int = 16;

	public function new() {}

	public function getInputSize():Int {
		return 64;
	}

	public function getHashSize():Int {
		return HASH_SIZE;
	}

	public function hash(src:ByteArrayCompat):ByteArrayCompat {
		var savedPosition = src.position;
		var savedEndian = src.endian;
		var savedLength = src.length;
		var out = ByteArrayCompat.fromBytes(HaxeMd5.make(src.toBytes()), ByteArrayCompat.LITTLE_ENDIAN);
		src.position = savedPosition;
		src.endian = savedEndian;
		src.length = savedLength;
		return out;
	}

	public function toString():String {
		return "md5";
	}
}
