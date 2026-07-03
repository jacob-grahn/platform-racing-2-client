package com.adobe.utils;

class IntUtil {
	private static inline var HEX:String = "0123456789abcdef";

	public static function rol(x:Int, n:Int):Int {
		return (x << n) | (x >>> (32 - n));
	}

	public static function ror(x:Int, n:Int):Int {
		var nn = 32 - n;
		return (x << nn) | (x >>> (32 - nn));
	}

	public static function toHex(n:Int, bigEndian:Bool = false):String {
		var out = "";
		if (bigEndian) {
			for (i in 0...4) {
				out += byteHex(n >>> ((3 - i) * 8));
			}
		} else {
			for (i in 0...4) {
				out += byteHex(n >>> (i * 8));
			}
		}
		return out;
	}

	private static function byteHex(value:Int):String {
		return HEX.charAt((value >>> 4) & 0xF) + HEX.charAt(value & 0xF);
	}
}
