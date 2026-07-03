package com.hurlant.crypto.symmetric;

import pr2.crypto.ByteArrayCompat;

class CBCMode extends IVMode implements IMode {
	public function new(key:ISymmetricKey, ?padding:IPad) {
		super(key, padding);
	}

	public function encrypt(src:ByteArrayCompat):Void {
		ensurePadding().pad(src);
		var vector = getIV4e();
		var i = 0;
		while (i < src.length) {
			for (j in 0...blockSize) {
				src.set(i + j, src.get(i + j) ^ vector.get(j));
			}
			ensureKey().encrypt(src, i);
			for (j in 0...blockSize) {
				vector.set(j, src.get(i + j));
			}
			i += blockSize;
		}
	}

	public function decrypt(src:ByteArrayCompat):Void {
		var vector = getIV4d();
		var tmp = new ByteArrayCompat();
		var i = 0;
		while (i < src.length) {
			for (j in 0...blockSize) {
				tmp.set(j, src.get(i + j));
			}
			ensureKey().decrypt(src, i);
			for (j in 0...blockSize) {
				src.set(i + j, src.get(i + j) ^ vector.get(j));
			}
			for (j in 0...blockSize) {
				vector.set(j, tmp.get(j));
			}
			i += blockSize;
		}
		ensurePadding().unpad(src);
	}

	public function toString():String {
		return ensureKey().toString() + "-cbc";
	}
}
