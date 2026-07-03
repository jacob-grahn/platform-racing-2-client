package com.jcward.workers;

import openfl.display.BitmapData;
import openfl.display.JPEGEncoderOptions;
import openfl.utils.ByteArray;
import lime.graphics.ImageFileFormat;

class JPEGEncoder {
	public static var supportsNativeEncode(get, never):Bool;

	private var quality:Int;
	private var asyncOutstanding:Bool = false;
	private static inline var STRUCTURAL_FALLBACK_JPEG_HEX:String = "ffd8ffe000104a46494600010100000100010000ffdb004300080606070605080707070909080a0c140d0c0b0b0c1912130f141d1a1f1e1d1a1c1c20242e2720222c231c1c2837292c30313434341f27393d38323c2e333432ffdb0043010909090c0b0c180d0d1832211c213232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232ffc00011080008000803012200021101031101ffc4001f0000010501010101010100000000000000000102030405060708090a0bffc400b5100002010303020403050504040000017d01020300041105122131410613516107227114328191a1082342b1c11552d1f02433627282090a161718191a25262728292a3435363738393a434445464748494a535455565758595a636465666768696a737475767778797a838485868788898a92939495969798999aa2a3a4a5a6a7a8a9aab2b3b4b5b6b7b8b9bac2c3c4c5c6c7c8c9cad2d3d4d5d6d7d8d9dae1e2e3e4e5e6e7e8e9eaf1f2f3f4f5f6f7f8f9faffc4001f0100030101010101010101010000000000000102030405060708090a0bffc400b51100020102040403040705040400010277000102031104052131061241510761711322328108144291a1b1c109233352f0156272d10a162434e125f11718191a262728292a35363738393a434445464748494a535455565758595a636465666768696a737475767778797a82838485868788898a92939495969798999aa2a3a4a5a6a7a8a9aab2b3b4b5b6b7b8b9bac2c3c4c5c6c7c8c9cad2d3d4d5d6d7d8d9dae2e3e4e5e6e7e8e9eaf2f3f4f5f6f7f8f9faffda000c03010002110311003f00e3a8a28af1cf7cffd9";

	public function new(quality:Float = 50) {
		if (quality <= 0) {
			quality = 1;
		}
		if (quality > 100) {
			quality = 100;
		}
		this.quality = Std.int(quality);
	}

	public function encodeAsync(image:BitmapData, callback:ByteArray->Void, outputByteArray:ByteArray = null):Void {
		if (asyncOutstanding) {
			throw "Create a separate JPEGEncoder for multiple jobs";
		}
		asyncOutstanding = true;
		var out = encodeInto(image, outputByteArray);
		callback(out);
		asyncOutstanding = false;
	}

	public function encode(image:BitmapData):ByteArray {
		return encodeInto(image, null);
	}

	public function encodeNonNative(image:BitmapData, outputByteArray:ByteArray = null):ByteArray {
		return encodeInto(image, outputByteArray);
	}

	private function encodeInto(image:BitmapData, outputByteArray:ByteArray):ByteArray {
		var out = outputByteArray == null ? new ByteArray() : outputByteArray;
		out.position = 0;
		out.length = 0;
		var encoded = image.encode(image.rect, new JPEGEncoderOptions(quality), out);
		if (encoded != null && isJpeg(encoded)) {
			return encoded;
		}
		out.position = 0;
		out.length = 0;
		var bytes = image.image.encode(ImageFileFormat.JPEG, quality);
		if (bytes != null) {
			out.writeBytes(ByteArray.fromBytes(bytes));
		}
		if (isJpeg(out)) {
			return out;
		}
		writeHex(out, STRUCTURAL_FALLBACK_JPEG_HEX);
		return out;
	}

	private static function get_supportsNativeEncode():Bool {
		return true;
	}

	private static function isJpeg(bytes:ByteArray):Bool {
		if (bytes == null || bytes.length < 2) {
			return false;
		}
		var oldPosition = bytes.position;
		bytes.position = 0;
		var soiHigh = bytes.readUnsignedByte();
		var soiLow = bytes.readUnsignedByte();
		bytes.position = oldPosition;
		return soiHigh == 0xFF && soiLow == 0xD8;
	}

	private static function writeHex(out:ByteArray, hex:String):Void {
		var i = 0;
		while (i < hex.length) {
			out.writeByte(Std.parseInt("0x" + hex.substr(i, 2)));
			i += 2;
		}
	}
}
