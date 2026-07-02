package pr2.util;

/**
	Port of .NET's `System.Random` (the subtractive Knuth generator), which is
	what the original Flash game's server-seeded sequences were reproduced
	against. Keeping the exact algorithm — including the large-range sampling
	branch — is what makes seeded egg/move sequences deterministic across the
	port. Do not "simplify" the constants or the internal sample math.
**/
class FlashRandom {
	private static inline var MBIG:Int = 0x7fffffff;
	private static inline var MSEED:Int = 0x9a4ec86;
	private var inext:Int = 0;
	private var inextp:Int = 0x15;
	private var seedArray:Array<Int> = [];

	public function new(seed:Int) {
		for (_ in 0...0x38) {
			seedArray.push(0);
		}
		var num2 = MSEED - Std.int(Math.abs(seed));
		seedArray[0x37] = num2;
		var num3 = 1;
		for (i in 1...0x37) {
			var index = (0x15 * i) % 0x37;
			seedArray[index] = num3;
			num3 = num2 - num3;
			if (num3 < 0) {
				num3 += MBIG;
			}
			num2 = seedArray[index];
		}
		for (_ in 1...5) {
			for (k in 1...0x38) {
				seedArray[k] -= seedArray[1 + ((k + 30) % 0x37)];
				if (seedArray[k] < 0) {
					seedArray[k] += MBIG;
				}
			}
		}
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
		var next = inext;
		var nextp = inextp;
		if (++next >= 0x38) {
			next = 1;
		}
		if (++nextp >= 0x38) {
			nextp = 1;
		}
		var num = seedArray[next] - seedArray[nextp];
		if (num < 0) {
			num += MBIG;
		}
		seedArray[next] = num;
		inext = next;
		inextp = nextp;
		return num;
	}
}
