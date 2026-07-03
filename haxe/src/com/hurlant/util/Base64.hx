package com.hurlant.util;

import pr2.crypto.ByteArrayCompat;

class Base64 {
	public static inline var version:String = "1.0.0";
	private static inline var BASE64_CHARS:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

	public static function encode(data:String):String {
		var bytes = new ByteArrayCompat();
		bytes.writeUTFBytes(data);
		return encodeByteArray(bytes);
	}

	public static function encodeByteArray(data:ByteArrayCompat):String {
		var output = "";
		data.position = 0;
		while (data.position < data.length) {
			var dataBuffer:Array<Int> = [];
			var i = 0;
			while (i < 3 && data.position < data.length) {
				dataBuffer[i] = data.readUnsignedByte();
				i++;
			}
			var b0 = dataBuffer[0];
			var b1 = dataBuffer.length > 1 ? dataBuffer[1] : 0;
			var b2 = dataBuffer.length > 2 ? dataBuffer[2] : 0;
			var outputBuffer = [
				(b0 & 0xFC) >> 2,
				((b0 & 0x03) << 4) | (b1 >> 4),
				((b1 & 0x0F) << 2) | (b2 >> 6),
				b2 & 0x3F,
			];
			for (j in dataBuffer.length...3) {
				outputBuffer[j + 1] = 64;
			}
			for (index in outputBuffer) {
				output += BASE64_CHARS.charAt(index);
			}
		}
		return output;
	}

	public static function decode(data:String):String {
		return decodeToByteArray(data).toBytes().toString();
	}

	public static function decodeToByteArray(data:String):ByteArrayCompat {
		var output = new ByteArrayCompat();
		var i = 0;
		while (i < data.length) {
			var dataBuffer = [0, 0, 0, 0];
			for (j in 0...4) {
				if (i + j < data.length) {
					dataBuffer[j] = BASE64_CHARS.indexOf(data.charAt(i + j));
				}
			}
			var outputBuffer = [
				(dataBuffer[0] << 2) + ((dataBuffer[1] & 0x30) >> 4),
				((dataBuffer[1] & 0x0F) << 4) + ((dataBuffer[2] & 0x3C) >> 2),
				((dataBuffer[2] & 0x03) << 6) + dataBuffer[3],
			];
			for (k in 0...outputBuffer.length) {
				if (dataBuffer[k + 1] == 64) {
					break;
				}
				output.writeByte(outputBuffer[k]);
			}
			i += 4;
		}
		output.position = 0;
		return output;
	}

	public function new() {
		throw "Base64 class is static container only";
	}
}
