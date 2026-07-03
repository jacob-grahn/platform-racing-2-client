package pr2.crypto;

import com.hurlant.util.Base64;
import com.hurlant.util.Hex;
import com.hurlant.util.Memory;

class HurlantUtilCompatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testBase64Surface();
		testHexSurface();
		testMemorySurface();
		trace('HurlantUtilCompatTest passed $assertions assertions');
	}

	private static function testBase64Surface():Void {
		assertEquals("1.0.0", Base64.version, "Base64 version");
		assertEquals("aGVsbG8gd29ybGQ=", Base64.encode("hello world"), "Base64 encode string");
		assertEquals("hello world", Base64.decode("aGVsbG8gd29ybGQ="), "Base64 decode string");

		var bytes = new ByteArrayCompat();
		bytes.writeUTFBytes("hello");
		bytes.position = 3;
		assertEquals("aGVsbG8=", Base64.encodeByteArray(bytes), "Base64 encode ByteArray");
		assertEquals(bytes.length, bytes.position, "Base64 encodeByteArray reads to end");

		var decoded = Base64.decodeToByteArray("AP8Q");
		assertEquals("00ff10", decoded.toHex(), "Base64 decodeToByteArray bytes");
		assertEquals(0, decoded.position, "Base64 decodeToByteArray rewinds output");

		var threw = false;
		try {
			new Base64();
		} catch (e:Dynamic) {
			threw = Std.string(e).indexOf("Base64 class is static container only") >= 0;
		}
		assertEquals(true, threw, "Base64 constructor throws");
	}

	private static function testHexSurface():Void {
		assertEquals("23030ef0", Hex.toArray("23:03 0e\nf0").toHex(), "Hex strips colons and whitespace");
		assertEquals("0f", Hex.toArray("f").toHex(), "Hex pads odd length");
		var bytes = ByteArrayCompat.fromHex("23030ef0");
		assertEquals("23030ef0", Hex.fromArray(bytes), "Hex fromArray compact");
		assertEquals("23:03:0e:f0", Hex.fromArray(bytes, true), "Hex fromArray colons");
		assertEquals("hello", Hex.toString("68656c6c6f"), "Hex toString UTF-8");
		assertEquals("68c3a9", Hex.fromString("hé"), "Hex fromString UTF-8");
		assertEquals("68:c3:a9", Hex.fromString("hé", true), "Hex fromString colons");
	}

	private static function testMemorySurface():Void {
		Memory.gc();
		assertEquals(true, Memory.used >= 0, "Memory used is exposed");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
