package pr2.net;

class LoginAuthClientTest {
	private static var assertions = 0;

	public static function main():Void {
		testPayloadContainsFlashFields();
		testEncryptedFields();
		testRememberedTokenField();
		testParsesError();
		trace('LoginAuthClientTest passed $assertions assertions');
	}

	private static function testRememberedTokenField():Void {
		var fields = LoginAuthClient.fields("Alice", "", server(), true, 1234, "saved-token");
		assertEquals("saved-token", fields.get("token"), "saved token form field");
		assertEquals(false, LoginAuthClient.fields("Alice", "", server(), true, 1234).exists("token"), "token omitted for password login");
	}

	private static function testPayloadContainsFlashFields():Void {
		var payload = LoginAuthClient.payloadJson("Guest", "", server(), false, 1234);
		assertContains(payload, "\"user_name\":\"Guest\"", "user name field");
		assertContains(payload, "\"user_pass\":\"\"", "password field");
		assertContains(payload, "\"build\":\"29-oct-2023-v168_2_1\"", "build field");
		assertContains(payload, "\"login_id\":1234", "login id field");
		assertContains(payload, "\"server_id\":2", "server id field");
		assertEquals(false, payload.indexOf("award_kong") >= 0, "removed Kong award field is omitted");
	}

	private static function testEncryptedFields():Void {
		var fields = LoginAuthClient.fields("Guest", "", server(), false, 1234);
		assertEquals("29-oct-2023-v168_2_1", fields.get("build"), "build post field");
		assertEquals(true, fields.exists("i"), "encrypted i field exists");
		assertEquals(true, fields.get("i").length > 40, "encrypted i field has ciphertext");
	}

	private static function testParsesError():Void {
		var result = LoginAuthClient.parse('{"success":false,"error":"bad login"}');
		assertEquals(false, result.success, "success false");
		assertEquals("bad login", result.message, "error message");
	}

	private static function server():ServerInfo {
		return new ServerInfo("example.com", 9160, 2, "Derron", "ok", 10, 0, false);
	}

	private static function assertContains(value:String, needle:String, message:String):Void {
		assertions++;
		if (value.indexOf(needle) < 0) {
			throw '$message: expected $value to contain $needle';
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
