package pr2.crypto;

import com.jiggmin.data.AESPad;
import com.jiggmin.data.Encryptor;

class PR2EncryptorTest {
	private static inline var LOGIN_KEY = "VUovam5GKndSMHFSSy9kSA==";
	private static inline var LOGIN_IV = "JmM5KnkqNXA9MVVOeC9Ucg==";
	private static var assertions = 0;

	public static function main():Void {
		testOpenSslFixture();
		testDecryptRoundTrip();
		testAESPadCompatibility();
		testEncryptorWrapper();
		testEncryptorCleanup();
		trace('PR2EncryptorTest passed $assertions assertions');
	}

	private static function testOpenSslFixture():Void {
		var plain = "{\"user_name\":\"Guest\",\"user_pass\":\"\",\"build\":\"29-oct-2023-v168_2_1\"}";
		var encrypted = PR2Encryptor.encryptBase64(plain, LOGIN_KEY, LOGIN_IV);
		assertEquals(
			"FZApmWl5Eet2tQBYIBRmO1wH6v0OVTgY7xokBF8TPwP6WECsg2PdVGdZAY3XZQCHL+bv09AzytHLhZHrIuyMJOCIuXsDuOuEVpvwDy5A+xo=",
			encrypted,
			"AES-128-CBC zero-padded fixture"
		);
	}

	private static function testDecryptRoundTrip():Void {
		var plain = "{\"level_id\":77,\"access\":1}";
		var encrypted = PR2Encryptor.encryptBase64(plain, LOGIN_KEY, LOGIN_IV);
		assertEquals(plain, PR2Encryptor.decryptBase64(encrypted, LOGIN_KEY, LOGIN_IV), "AES decrypt round trip");
	}

	private static function testAESPadCompatibility():Void {
		var bytes = new ByteArrayCompat();
		bytes.writeUTFBytes("abc");
		var pad = new AESPad(16);
		pad.pad(bytes);
		assertEquals(16, bytes.length, "AESPad pads to block boundary");
		assertEquals(0, bytes.get(15), "AESPad writes NUL UTF bytes");

		var padded = new ByteArrayCompat();
		padded.writeUTFBytes("a\u0000b\u0000\u0000");
		pad.unpad(padded);
		assertEquals("ab", padded.toBytes().toString(), "AESPad unpad removes NUL bytes like Flash decrypt path");
	}

	private static function testEncryptorWrapper():Void {
		var plain = "{\"level_id\":77,\"access\":1}";
		var encryptor = new Encryptor();
		encryptor.setKey(LOGIN_KEY);
		encryptor.setIV(LOGIN_IV);
		var encrypted = encryptor.encrypt(plain);
		assertEquals(PR2Encryptor.encryptBase64(plain, LOGIN_KEY, LOGIN_IV), encrypted, "Encryptor encrypt matches static helper");
		assertEquals(plain, encryptor.decrypt(encrypted), "Encryptor decrypt round trip");
	}

	private static function testEncryptorCleanup():Void {
		var encryptor = new Encryptor();
		encryptor.setKey(LOGIN_KEY);
		encryptor.setIV(LOGIN_IV);
		encryptor.remove();
		var threw = false;
		try {
			encryptor.encrypt("after remove");
		} catch (_:Dynamic) {
			threw = true;
		}
		assertEquals(true, threw, "Encryptor remove clears mode");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
