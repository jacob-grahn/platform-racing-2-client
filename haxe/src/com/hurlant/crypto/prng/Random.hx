package com.hurlant.crypto.prng;

import haxe.io.Bytes;
import pr2.crypto.ByteArrayCompat;

class Random {
	private var state:Null<IPRNG>;
	private var ready:Bool = false;
	private var pool:Null<ByteArrayCompat>;
	private var psize:Int;
	private var pptr:Int;
	private var seeded:Bool = false;

	public function new(?prng:Class<Dynamic>) {
		var prngClass:Class<Dynamic> = prng == null ? ARC4 : prng;
		state = cast Type.createInstance(prngClass, []);
		psize = state.getPoolSize();
		pool = new ByteArrayCompat();
		pptr = 0;
		while (pptr < psize) {
			var t = Std.int(65536 * Math.random()) & 0xFFFF;
			pool.set(pptr++, t >>> 8);
			pool.set(pptr++, t & 0xFF);
		}
		pptr = 0;
		seed();
	}

	public function seed(x:Int = 0):Void {
		if (x == 0) {
			x = timeSeed();
		}
		var activePool = ensurePool();
		activePool.set(pptr++, activePool.get(pptr - 1) ^ (x & 0xFF));
		activePool.set(pptr++, activePool.get(pptr - 1) ^ ((x >> 8) & 0xFF));
		activePool.set(pptr++, activePool.get(pptr - 1) ^ ((x >> 16) & 0xFF));
		activePool.set(pptr++, activePool.get(pptr - 1) ^ ((x >> 24) & 0xFF));
		pptr %= psize;
		seeded = true;
	}

	public function autoSeed():Void {
		seed(usedMemoryCompat());
		seedString(systemStringCompat());
		seed(Std.int(haxe.Timer.stamp() * 1000));
		seed(timeSeed());
	}

	public function nextBytes(buffer:ByteArrayCompat, length:Int):Void {
		while (length-- > 0) {
			buffer.writeByte(nextByte());
		}
	}

	public function nextByte():Int {
		if (!ready) {
			if (!seeded) {
				autoSeed();
			}
			ensureState().init(ensurePool());
			ensurePool().length = 0;
			pptr = 0;
			ready = true;
		}
		return ensureState().next();
	}

	public function dispose():Void {
		if (pool != null) {
			for (i in 0...pool.length) {
				pool.set(i, Std.int(Math.random() * 256));
			}
			pool.length = 0;
			pool = null;
		}
		if (state != null) {
			state.dispose();
			state = null;
		}
		psize = 0;
		pptr = 0;
	}

	public function toString():String {
		return "random-" + ensureState().toString();
	}

	private function seedString(value:String):Void {
		var bytes = Bytes.ofString(value);
		var accum = 0;
		var shift = 0;
		for (i in 0...bytes.length) {
			accum |= bytes.get(i) << shift;
			shift += 8;
			if (shift == 32) {
				seed(accum);
				accum = 0;
				shift = 0;
			}
		}
		if (shift > 0) {
			seed(accum);
		}
	}

	private function ensureState():IPRNG {
		if (state == null) {
			throw "Random state has been disposed";
		}
		return state;
	}

	private function ensurePool():ByteArrayCompat {
		if (pool == null) {
			throw "Random pool has been disposed";
		}
		return pool;
	}

	private static function timeSeed():Int {
		var low = Date.now().getTime() % 4294967296.0;
		if (low >= 2147483648.0) {
			low -= 4294967296.0;
		}
		return Std.int(low);
	}

	private static function usedMemoryCompat():Int {
		#if cpp
		return Std.int(cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE) & 0x7FFFFFFF);
		#else
		return 0;
		#end
	}

	private static function systemStringCompat():String {
		#if sys
		return Sys.systemName();
		#else
		return "unknown";
		#end
	}
}
