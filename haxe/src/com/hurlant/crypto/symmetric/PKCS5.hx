package com.hurlant.crypto.symmetric;

import pr2.crypto.ByteArrayCompat;

class PKCS5 implements IPad {
	private var blockSize:Int;

	public function new(blockSize:Int = 0) {
		this.blockSize = blockSize;
	}

	public function pad(a:ByteArrayCompat):Void {
		var c = blockSize - a.length % blockSize;
		for (_ in 0...c) {
			a.set(a.length, c);
		}
	}

	public function unpad(a:ByteArrayCompat):Void {
		var c = a.length % blockSize;
		if (c != 0) {
			throw "PKCS#5::unpad: ByteArray.length isn't a multiple of the blockSize";
		}
		c = a.get(a.length - 1);
		var i = c;
		while (i > 0) {
			var v = a.get(a.length - 1);
			a.length = a.length - 1;
			if (c != v) {
				throw 'PKCS#5:unpad: Invalid padding value. expected [$c], found [$v]';
			}
			i--;
		}
	}

	public function setBlockSize(bs:Int):Void {
		blockSize = bs;
	}
}
