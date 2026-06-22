package pr2.net;

class ForgotPasswordClientTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testBuildsFlashCompatibleFields();
		testParsesSuccessMessage();
		testParsesServerError();
		testRejectsFailedResponseWithoutError();
		trace('ForgotPasswordClientTest passed $assertions assertions');
	}

	private static function testBuildsFlashCompatibleFields():Void {
		var fields = ForgotPasswordClient.fields("player", "player@example.com");
		assertEquals("player", fields.get("name"), "name field");
		assertEquals("player@example.com", fields.get("email"), "email field");
	}

	private static function testParsesSuccessMessage():Void {
		var result = ForgotPasswordClient.parse('{"success":true,"message":"Email sent."}');
		assertEquals(true, result.success, "success");
		assertEquals("Email sent.", result.message, "success message");
	}

	private static function testParsesServerError():Void {
		var result = ForgotPasswordClient.parse('{"error":"No matching account."}');
		assertEquals(false, result.success, "error response");
		assertEquals("Error: No matching account.", result.message, "error echo");
	}

	private static function testRejectsFailedResponseWithoutError():Void {
		var result = ForgotPasswordClient.parse('{"success":false}');
		assertEquals(false, result.success, "failed response");
		assertEquals("Error: An unknown error occurred. I suspect evil aliens.", result.message, "Flash fallback error");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
