package pr2.crypto;

import com.adobe.crypto.MD5 as AdobeMD5;
import com.adobe.utils.IntUtil;
import com.hurlant.crypto.hash.IHash;
import com.hurlant.crypto.hash.MD5 as HurlantMD5;

class MD5CompatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testAdobeMd5Surface();
		if (pr2.DeterministicTestMode.finishSmokeSuite("MD5CompatTest")) return;
		testHurlantMd5Surface();
		testIntUtilEndianAndRotates();
		trace('MD5CompatTest passed $assertions assertions');
	}

	private static function testAdobeMd5Surface():Void {
		assertEquals("900150983cd24fb0d6963f7d28e17f72", AdobeMD5.hash("abc"), "Adobe string MD5");
		var bytes = new ByteArrayCompat();
		bytes.endian = ByteArrayCompat.LITTLE_ENDIAN;
		bytes.writeUTFBytes("abc");
		bytes.position = 2;
		var hash = AdobeMD5.hashBytes(bytes);
		assertEquals("900150983cd24fb0d6963f7d28e17f72", hash, "Adobe ByteArray MD5");
		assertEquals(2, bytes.position, "Adobe hashBytes restores source position");
		assertEquals(ByteArrayCompat.LITTLE_ENDIAN, bytes.endian, "Adobe hashBytes restores source endian");
		assertEquals(3, bytes.length, "Adobe hashBytes restores source length");
		assertEquals("900150983cd24fb0d6963f7d28e17f72", AdobeMD5.digest.toHex(), "Adobe digest stores raw hash bytes");
	}

	private static function testHurlantMd5Surface():Void {
		var md5:IHash = new HurlantMD5();
		assertEquals(64, md5.getInputSize(), "Hurlant input block size");
		assertEquals(16, md5.getHashSize(), "Hurlant hash size");
		assertEquals("md5", md5.toString(), "Hurlant toString");
		var bytes = new ByteArrayCompat();
		bytes.endian = ByteArrayCompat.BIG_ENDIAN;
		bytes.writeUTFBytes("abc");
		bytes.position = 1;
		var out = md5.hash(bytes);
		assertEquals("900150983cd24fb0d6963f7d28e17f72", out.toHex(), "Hurlant hash bytes");
		assertEquals(ByteArrayCompat.LITTLE_ENDIAN, out.endian, "Hurlant output is little-endian");
		assertEquals(1, bytes.position, "Hurlant hash restores source position");
		assertEquals(ByteArrayCompat.BIG_ENDIAN, bytes.endian, "Hurlant hash restores source endian");
		assertEquals(3, bytes.length, "Hurlant hash restores source length");
	}

	private static function testIntUtilEndianAndRotates():Void {
		assertEquals("78563412", IntUtil.toHex(0x12345678), "IntUtil little-endian hex");
		assertEquals("12345678", IntUtil.toHex(0x12345678, true), "IntUtil big-endian hex");
		assertEquals(0x34567812, IntUtil.rol(0x12345678, 8), "IntUtil rol");
		assertEquals(0x78123456, IntUtil.ror(0x12345678, 8), "IntUtil ror");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
