package pr2.crypto;

import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;

/**
	AES-128-CBC encryptor compatible with PR2's Flash `Encryptor` / server
	`pr2\http\Encryptor` login path.

	The Flash `AESPad` pads with NUL bytes up to a block boundary. The server
	decrypts with OpenSSL zero-padding and strips control characters, so this
	class intentionally uses the same zero-padding behavior for client requests.
**/
class PR2Encryptor {
	public static function encryptBase64(plainText:String, base64Key:String, base64Iv:String):String {
		var key = Base64.decode(base64Key);
		var iv = Base64.decode(base64Iv);
		if (key.length != 16) {
			throw 'AES-128 key must be 16 bytes, got ${key.length}';
		}
		if (iv.length != 16) {
			throw 'AES-CBC IV must be 16 bytes, got ${iv.length}';
		}

		var input = zeroPad(Bytes.ofString(plainText));
		var aes = new Aes128(key);
		var out = Bytes.alloc(input.length);
		var previous = iv;
		var block = Bytes.alloc(16);

		var offset = 0;
		while (offset < input.length) {
			for (i in 0...16) {
				block.set(i, input.get(offset + i) ^ previous.get(i));
			}
			var encrypted = aes.encryptBlock(block);
			out.blit(offset, encrypted, 0, 16);
			previous = encrypted;
			offset += 16;
		}

		return Base64.encode(out);
	}

	private static function zeroPad(input:Bytes):Bytes {
		var remainder = input.length % 16;
		if (remainder == 0) {
			return input;
		}
		var padded = Bytes.alloc(input.length + 16 - remainder);
		padded.blit(0, input, 0, input.length);
		return padded;
	}
}

private class Aes128 {
	private static final SBOX:Array<Int> = [
		0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
		0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
		0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
		0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
		0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
		0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
		0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
		0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
		0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
		0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
		0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
		0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
		0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
		0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
		0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
		0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16,
	];
	private static final RCON:Array<Int> = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36];

	private final roundKeys:Array<Int>;

	public function new(key:Bytes) {
		roundKeys = expandKey(key);
	}

	public function encryptBlock(input:Bytes):Bytes {
		var state = [for (i in 0...16) input.get(i)];
		addRoundKey(state, 0);
		for (round in 1...10) {
			subBytes(state);
			shiftRows(state);
			mixColumns(state);
			addRoundKey(state, round);
		}
		subBytes(state);
		shiftRows(state);
		addRoundKey(state, 10);

		var out = Bytes.alloc(16);
		for (i in 0...16) {
			out.set(i, state[i]);
		}
		return out;
	}

	private function addRoundKey(state:Array<Int>, round:Int):Void {
		var offset = round * 16;
		for (i in 0...16) {
			state[i] ^= roundKeys[offset + i];
		}
	}

	private static function subBytes(state:Array<Int>):Void {
		for (i in 0...16) {
			state[i] = SBOX[state[i]];
		}
	}

	private static function shiftRows(state:Array<Int>):Void {
		var copy = state.copy();
		state[1] = copy[5];
		state[5] = copy[9];
		state[9] = copy[13];
		state[13] = copy[1];
		state[2] = copy[10];
		state[6] = copy[14];
		state[10] = copy[2];
		state[14] = copy[6];
		state[3] = copy[15];
		state[7] = copy[3];
		state[11] = copy[7];
		state[15] = copy[11];
	}

	private static function mixColumns(state:Array<Int>):Void {
		for (c in 0...4) {
			var i = c * 4;
			var a0 = state[i];
			var a1 = state[i + 1];
			var a2 = state[i + 2];
			var a3 = state[i + 3];
			state[i] = mul2(a0) ^ mul3(a1) ^ a2 ^ a3;
			state[i + 1] = a0 ^ mul2(a1) ^ mul3(a2) ^ a3;
			state[i + 2] = a0 ^ a1 ^ mul2(a2) ^ mul3(a3);
			state[i + 3] = mul3(a0) ^ a1 ^ a2 ^ mul2(a3);
		}
	}

	private static function expandKey(key:Bytes):Array<Int> {
		var expanded = [for (i in 0...176) 0];
		for (i in 0...16) {
			expanded[i] = key.get(i);
		}

		var bytesGenerated = 16;
		var rconIndex = 0;
		var temp = [0, 0, 0, 0];
		while (bytesGenerated < 176) {
			for (i in 0...4) {
				temp[i] = expanded[bytesGenerated - 4 + i];
			}
			if (bytesGenerated % 16 == 0) {
				var t = temp[0];
				temp[0] = SBOX[temp[1]] ^ RCON[rconIndex++];
				temp[1] = SBOX[temp[2]];
				temp[2] = SBOX[temp[3]];
				temp[3] = SBOX[t];
			}
			for (i in 0...4) {
				expanded[bytesGenerated] = expanded[bytesGenerated - 16] ^ temp[i];
				bytesGenerated++;
			}
		}
		return expanded;
	}

	private static inline function mul2(value:Int):Int {
		var shifted = value << 1;
		return ((shifted & 0x100) != 0 ? shifted ^ 0x11b : shifted) & 0xff;
	}

	private static inline function mul3(value:Int):Int {
		return mul2(value) ^ value;
	}
}
