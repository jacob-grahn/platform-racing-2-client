package com.hurlant.util;

import pr2.crypto.ByteArrayCompat;

class Hex {
	public static function toArray(hex:String):ByteArrayCompat {
		var clean = ~/[ \t\r\n:]/g.replace(hex, "");
		if (clean.length % 2 == 1) {
			clean = "0" + clean;
		}
		var out = new ByteArrayCompat();
		var i = 0;
		while (i < clean.length) {
			out.set(Std.int(i / 2), Std.parseInt("0x" + clean.substr(i, 2)));
			i += 2;
		}
		out.position = 0;
		return out;
	}

	public static function fromArray(array:ByteArrayCompat, colons:Bool = false):String {
		var parts:Array<String> = [];
		for (i in 0...array.length) {
			var hex = StringTools.hex(array.get(i), 2).toLowerCase();
			parts.push(hex.substr(hex.length - 2));
		}
		return colons ? parts.join(":") : parts.join("");
	}

	public static function toString(hex:String):String {
		return toArray(hex).toBytes().toString();
	}

	public static function fromString(str:String, colons:Bool = false):String {
		var bytes = new ByteArrayCompat();
		bytes.writeUTFBytes(str);
		return fromArray(bytes, colons);
	}
}
