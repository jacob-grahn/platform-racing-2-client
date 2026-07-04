package com.jiggmin.data;

import pr2.crypto.ByteArrayCompat;

class Random {
	private static inline var MBIG:Int = 0x7fffffff;
	private static inline var MSEED:Int = 0x9a4ec86;

	public var seed(get, never):Int;

	private var _inext:Int = 0;
	private var _inextp:Int = 0x15;
	private var _seed:Int;
	private var _seedArray:Array<Int> = [];

	public function new(seed:Int) {
		_seed = seed;
		for (_ in 0...0x38) {
			_seedArray.push(0);
		}
		var num2 = MSEED - Std.int(Math.abs(seed));
		_seedArray[0x37] = num2;
		var num3 = 1;
		for (i in 1...0x37) {
			var index = (0x15 * i) % 0x37;
			_seedArray[index] = num3;
			num3 = num2 - num3;
			if (num3 < 0) {
				num3 += MBIG;
			}
			num2 = _seedArray[index];
		}
		for (_ in 1...5) {
			for (k in 1...0x38) {
				_seedArray[k] -= _seedArray[1 + ((k + 30) % 0x37)];
				if (_seedArray[k] < 0) {
					_seedArray[k] += MBIG;
				}
			}
		}
	}

	private function get_seed():Int {
		return _seed;
	}

	public function nextInt():Int {
		return internalSample();
	}

	public function nextMax(maxValue:Int):Int {
		if (maxValue < 0) {
			throw 'Argument "maxValue" must be positive.';
		}
		return Std.int(sample() * maxValue);
	}

	public function nextMinMax(minValue:Int, maxValue:Int):Int {
		if (minValue > maxValue) {
			throw 'Argument "minValue" must be less than or equal to "maxValue".';
		}
		var num:Float = maxValue - minValue;
		if (num <= MBIG) {
			return Std.int(sample() * num) + minValue;
		}
		return Std.int(getSampleForLargeRange() * num) + minValue;
	}

	public function nextBytes(buffer:ByteArrayCompat, length:Int):Void {
		if (buffer == null) {
			throw 'Argument "buffer" cannot be null.';
		}
		for (_ in 0...length) {
			buffer.writeByte(internalSample() % 0x100);
		}
	}

	public function nextNumber():Float {
		return sample();
	}

	private function sample():Float {
		return internalSample() * 4.6566128752457969E-10;
	}

	private function getSampleForLargeRange():Float {
		var num = internalSample();
		if ((internalSample() % 2) == 0) {
			num = -num;
		}
		return (num + 2147483646.0) / 4294967293.0;
	}

	private function internalSample():Int {
		var next = _inext;
		var nextp = _inextp;
		if (++next >= 0x38) {
			next = 1;
		}
		if (++nextp >= 0x38) {
			nextp = 1;
		}
		var num = _seedArray[next] - _seedArray[nextp];
		if (num < 0) {
			num += MBIG;
		}
		_seedArray[next] = num;
		_inext = next;
		_inextp = nextp;
		return num;
	}
}
