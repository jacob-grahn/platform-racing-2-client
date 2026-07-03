package com.hurlant.crypto.prng;

import com.hurlant.crypto.symmetric.IStreamCipher;
import pr2.crypto.ByteArrayCompat;

class ARC4 implements IPRNG implements IStreamCipher {
	private static inline var POOL_SIZE:Int = 256;

	private var i:Int = 0;
	private var j:Int = 0;
	private var s:Null<Array<Int>>;

	public function new(?key:ByteArrayCompat) {
		s = [];
		if (key != null) {
			init(key);
		}
	}

	public function getPoolSize():Int {
		return POOL_SIZE;
	}

	public function init(key:ByteArrayCompat):Void {
		var state = ensureState();
		for (n in 0...POOL_SIZE) {
			state[n] = n;
		}
		var jj = 0;
		for (n in 0...POOL_SIZE) {
			jj = (jj + state[n] + key.get(n % key.length)) & 0xFF;
			var t = state[n];
			state[n] = state[jj];
			state[jj] = t;
		}
		i = 0;
		j = 0;
	}

	public function next():Int {
		var state = ensureState();
		i = (i + 1) & 0xFF;
		j = (j + state[i]) & 0xFF;
		var t = state[i];
		state[i] = state[j];
		state[j] = t;
		return state[(t + state[i]) & 0xFF] & 0xFF;
	}

	public function getBlockSize():Int {
		return 1;
	}

	public function encrypt(src:ByteArrayCompat):Void {
		for (index in 0...src.length) {
			src.set(index, src.get(index) ^ next());
		}
	}

	public function decrypt(src:ByteArrayCompat):Void {
		encrypt(src);
	}

	public function dispose():Void {
		if (s != null) {
			for (n in 0...s.length) {
				s[n] = (n * 73 + 41) & 0xFF;
			}
			s = null;
		}
		i = 0;
		j = 0;
	}

	public function toString():String {
		return "rc4";
	}

	private function ensureState():Array<Int> {
		if (s == null) {
			s = [];
		}
		return s;
	}
}
