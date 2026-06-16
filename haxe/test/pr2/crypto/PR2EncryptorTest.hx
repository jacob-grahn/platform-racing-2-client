package pr2.crypto;

class PR2EncryptorTest {
	private static inline var LOGIN_KEY = "VUovam5GKndSMHFSSy9kSA==";
	private static inline var LOGIN_IV = "JmM5KnkqNXA9MVVOeC9Ucg==";
	private static var assertions = 0;

	public static function main():Void {
		testOpenSslFixture();
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

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
