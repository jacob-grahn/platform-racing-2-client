package com.jiggmin.data;

import com.hurlant.crypto.symmetric.IPad;
import pr2.crypto.ByteArrayCompat;

/**
	Port of PR2's zero-byte AES padding helper.
**/
class AESPad implements IPad {
	private var blockSize:Int;
	private final char0:String = String.fromCharCode(0);

	public function new(i:Int = 0) {
		blockSize = i;
	}

	public function pad(byteArr:ByteArrayCompat):Void {
		while (blockSize > 0 && byteArr.length % blockSize != 0) {
			byteArr.writeUTFBytes(char0);
		}
	}

	public function unpad(byteArr:ByteArrayCompat):Void {
		byteArr.position = 0;
		var s = byteArr.toBytes().toString();
		s = StringTools.replace(s, char0, "");
		byteArr.length = 0;
		byteArr.position = 0;
		byteArr.writeUTFBytes(s);
		byteArr.position = 0;
	}

	public function setBlockSize(i:Int):Void {
		blockSize = i;
	}
}
