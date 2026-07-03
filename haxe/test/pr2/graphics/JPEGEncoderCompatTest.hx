package pr2.graphics;

import com.jcward.workers.BitString;
import com.jcward.workers.JPEGEncoder;
import openfl.display.BitmapData;
import openfl.utils.ByteArray;

class JPEGEncoderCompatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testQualityClampAndBitString();
		testEncodeProducesJpegMarkers();
		testEncodeNonNativeUsesOptionalOutput();
		testEncodeAsyncGuardAndOutput();
		trace('JPEGEncoderCompatTest passed $assertions assertions');
	}

	private static function testQualityClampAndBitString():Void {
		assertEquals(1, @:privateAccess new JPEGEncoder(0).quality, "quality lower clamp");
		assertEquals(100, @:privateAccess new JPEGEncoder(150).quality, "quality upper clamp");
		assertEquals(73, @:privateAccess new JPEGEncoder(73.9).quality, "quality int scaling");
		assertEquals(true, JPEGEncoder.supportsNativeEncode, "supports native encode");

		var bits = new BitString();
		bits.len = 5;
		bits.val = 0x1F;
		assertEquals(5, bits.len, "BitString len");
		assertEquals(0x1F, bits.val, "BitString val");
	}

	private static function testEncodeProducesJpegMarkers():Void {
		var out = new JPEGEncoder(90).encode(testImage());
		assertJpeg(out, "encode");
		assertEquals(true, containsMarker(out, 0xFFDB), "encode writes DQT marker");
		assertEquals(true, containsMarker(out, 0xFFC0), "encode writes SOF0 marker");
		assertEquals(true, containsMarker(out, 0xFFC4), "encode writes DHT marker");
		assertEquals(true, containsMarker(out, 0xFFDA), "encode writes SOS marker");
	}

	private static function testEncodeNonNativeUsesOptionalOutput():Void {
		var output = new ByteArray();
		output.writeByte(0x12);
		output.writeByte(0x34);
		output.position = 1;
		var returned = new JPEGEncoder(80).encodeNonNative(testImage(), output);
		assertEquals(true, returned == output, "encodeNonNative returns provided output");
		assertJpeg(output, "encodeNonNative");
		assertEquals(output.length, output.position, "encodeNonNative leaves position at end");
	}

	private static function testEncodeAsyncGuardAndOutput():Void {
		var encoder = new JPEGEncoder(75);
		var output = new ByteArray();
		var callbackCalled = false;
		var nestedRejected = false;
		encoder.encodeAsync(testImage(), function(bytes:ByteArray):Void {
			callbackCalled = true;
			assertEquals(true, bytes == output, "encodeAsync callback receives provided output");
			assertJpeg(bytes, "encodeAsync");
			try {
				encoder.encodeAsync(testImage(), function(_:ByteArray):Void {});
			} catch (e:Dynamic) {
				nestedRejected = Std.string(e).indexOf("Create a separate JPEGEncoder for multiple jobs") >= 0;
			}
		}, output);
		assertEquals(true, callbackCalled, "encodeAsync invokes callback");
		assertEquals(true, nestedRejected, "encodeAsync rejects nested outstanding job");

		var secondCalled = false;
		encoder.encodeAsync(testImage(), function(_:ByteArray):Void {
			secondCalled = true;
		});
		assertEquals(true, secondCalled, "encodeAsync accepts later job");
	}

	private static function testImage():BitmapData {
		var image = new BitmapData(8, 8, false, 0x000000);
		for (y in 0...8) {
			for (x in 0...8) {
				image.setPixel(x, y, ((x * 32) << 16) | ((y * 32) << 8) | 0x55);
			}
		}
		return image;
	}

	private static function assertJpeg(bytes:ByteArray, label:String):Void {
		assertEquals(true, bytes.length > 20, '$label has bytes');
		assertEquals(0xFF, byteAt(bytes, 0), '$label SOI high');
		assertEquals(0xD8, byteAt(bytes, 1), '$label SOI low');
		assertEquals(0xFF, byteAt(bytes, bytes.length - 2), '$label EOI high');
		assertEquals(0xD9, byteAt(bytes, bytes.length - 1), '$label EOI low');
		assertEquals(true, containsAscii(bytes, "JFIF"), '$label JFIF header');
	}

	private static function containsMarker(bytes:ByteArray, marker:Int):Bool {
		var high = (marker >> 8) & 0xFF;
		var low = marker & 0xFF;
		for (i in 0...(bytes.length - 1)) {
			if (byteAt(bytes, i) == high && byteAt(bytes, i + 1) == low) {
				return true;
			}
		}
		return false;
	}

	private static function containsAscii(bytes:ByteArray, value:String):Bool {
		for (i in 0...(bytes.length - value.length + 1)) {
			var match = true;
			for (j in 0...value.length) {
				if (byteAt(bytes, i + j) != value.charCodeAt(j)) {
					match = false;
					break;
				}
			}
			if (match) {
				return true;
			}
		}
		return false;
	}

	private static function byteAt(bytes:ByteArray, index:Int):Int {
		var oldPosition = bytes.position;
		bytes.position = index;
		var value = bytes.readUnsignedByte();
		bytes.position = oldPosition;
		return value;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
