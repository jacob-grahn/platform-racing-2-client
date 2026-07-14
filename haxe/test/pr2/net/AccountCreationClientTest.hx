package pr2.net;

class AccountCreationClientTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testBuildsFlashCompatibleFields();
		if (pr2.DeterministicTestMode.finishSmokeSuite("AccountCreationClientTest")) return;
		testParsesSuccess();
		testParsesErrorMessage();
		testParsesFlashBooleanValues();
		testRejectsMalformedResponses();
		trace('AccountCreationClientTest passed $assertions assertions');
	}

	private static function testBuildsFlashCompatibleFields():Void {
		var fields = AccountCreationClient.fields("new_user", "secret", "user@example.com");
		assertEquals("new_user", fields.get("name"), "name field");
		assertEquals("secret", fields.get("password"), "password field");
		assertEquals("user@example.com", fields.get("email"), "email field");
	}

	private static function testParsesSuccess():Void {
		var result = AccountCreationClient.parse('{"success":true}');
		assertEquals(true, result.success, "success true");
		assertEquals("", result.message, "no message");
	}

	private static function testParsesErrorMessage():Void {
		var result = AccountCreationClient.parse('{"success":false,"error":"Name already exists."}');
		assertEquals(false, result.success, "success false");
		assertEquals("Name already exists.", result.message, "error message");
	}

	private static function testParsesFlashBooleanValues():Void {
		assertEquals(true, AccountCreationClient.parse('{"success":"1"}').success, "numeric string success");
		assertEquals(false, AccountCreationClient.parse('{"success":"false"}').success, "false string success");
	}

	private static function testRejectsMalformedResponses():Void {
		assertThrows(function():Void AccountCreationClient.parse(""), "empty response");
		assertThrows(function():Void AccountCreationClient.parse("not json"), "invalid JSON");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertThrows(callback:Void->Void, message:String):Void {
		assertions++;
		try {
			callback();
		} catch (_:Dynamic) {
			return;
		}
		throw '$message: expected exception';
	}
}
