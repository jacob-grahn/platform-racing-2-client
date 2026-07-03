package com.hurlant.crypto.symmetric;

import com.hurlant.crypto.prng.Random;
import pr2.crypto.ByteArrayCompat;

class IVMode {
	public var IV(get, set):ByteArrayCompat;

	private var key:Null<ISymmetricKey>;
	private var padding:Null<IPad>;
	private var prng:Null<Random>;
	private var iv:Null<ByteArrayCompat>;
	private var lastIV:Null<ByteArrayCompat>;
	var blockSize:Int;

	public function new(key:ISymmetricKey, ?padding:IPad) {
		this.key = key;
		blockSize = key.getBlockSize();
		if (padding == null) {
			padding = new PKCS5(blockSize);
		} else {
			padding.setBlockSize(blockSize);
		}
		this.padding = padding;
		prng = new Random();
		iv = null;
		lastIV = new ByteArrayCompat();
	}

	public function getBlockSize():Int {
		return ensureKey().getBlockSize();
	}

	public function dispose():Void {
		if (iv != null) {
			for (i in 0...iv.length) {
				iv.set(i, 0);
			}
			iv.length = 0;
			iv = null;
		}
		if (lastIV != null) {
			for (i in 0...lastIV.length) {
				lastIV.set(i, 0);
			}
			lastIV.length = 0;
			lastIV = null;
		}
		if (key != null) {
			key.dispose();
			key = null;
		}
		padding = null;
		if (prng != null) {
			prng.dispose();
			prng = null;
		}
	}

	private function set_IV(value:ByteArrayCompat):ByteArrayCompat {
		iv = value;
		lastIV = value.clone();
		lastIV.position = 0;
		return value;
	}

	private function get_IV():ByteArrayCompat {
		return lastIV;
	}

	function getIV4e():ByteArrayCompat {
		var vec = new ByteArrayCompat();
		if (iv != null) {
			copyBytes(iv, vec, blockSize);
		} else {
			ensurePrng().nextBytes(vec, blockSize);
		}
		lastIV = vec.clone();
		lastIV.position = 0;
		return vec;
	}

	function getIV4d():ByteArrayCompat {
		if (iv == null) {
			throw "an IV must be set before calling decrypt()";
		}
		var vec = new ByteArrayCompat();
		copyBytes(iv, vec, blockSize);
		return vec;
	}

	function ensureKey():ISymmetricKey {
		if (key == null) {
			throw "IVMode key has been disposed";
		}
		return key;
	}

	function ensurePadding():IPad {
		if (padding == null) {
			throw "IVMode padding has been disposed";
		}
		return padding;
	}

	private function ensurePrng():Random {
		if (prng == null) {
			throw "IVMode PRNG has been disposed";
		}
		return prng;
	}

	private static function copyBytes(src:ByteArrayCompat, dst:ByteArrayCompat, length:Int):Void {
		for (i in 0...length) {
			dst.set(i, src.get(i));
		}
		dst.length = length;
		dst.position = 0;
	}
}
