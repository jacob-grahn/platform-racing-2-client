package pr2.net;

import pr2.lobby.LobbySession;

class SuperLoaderTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testPrepareFields();
		testAppendQueryFields();
		testDecodeJsonMessagesAndErrors();
		testDecodeUrlVariables();
		testFormatIoError();
		SuperLoader.resetHooks();
		LobbySession.token = "";
		trace('SuperLoaderTest passed $assertions assertions');
	}

	private static function testPrepareFields():Void {
		SuperLoader.nextRand = function():Int return 12345;
		LobbySession.token = "session-token";
		var fields = SuperLoader.prepareFields(["mode" => "save"]);
		assertEquals("save", fields.get("mode"), "original field preserved");
		assertEquals("12345", fields.get("rand"), "rand appended");
		assertEquals("session-token", fields.get("token"), "session token appended");

		var explicit = SuperLoader.prepareFields(["token" => "saved-login-token", "rand" => "77"]);
		assertEquals("saved-login-token", explicit.get("token"), "explicit token is not overwritten");
		assertEquals("77", explicit.get("rand"), "explicit rand is not overwritten");
	}

	private static function testAppendQueryFields():Void {
		SuperLoader.nextRand = function():Int return 222;
		LobbySession.token = "tok";
		var url = SuperLoader.appendQueryFields("https://example.com/api?mode=x");
		assertEquals(true, url.indexOf("mode=x&") != -1, "existing query gets ampersand");
		assertEquals(true, url.indexOf("rand=222") != -1, "query rand appended");
		assertEquals(true, url.indexOf("token=tok") != -1, "query token appended");
	}

	private static function testDecodeJsonMessagesAndErrors():Void {
		var messages:Array<String> = [];
		SuperLoader.showMessage = function(message:String):Void messages.push(message);
		var ok = SuperLoader.decodeJson("json", '{"success":true,"message":"Saved"}');
		assertEquals(true, ok.success, "success JSON accepted");
		assertEquals("Saved", messages[0], "server message auto-shown");

		var failed = SuperLoader.decodeJson("json", '{"success":false,"error":"Nope"}');
		assertEquals(false, failed.success, "success false rejected");
		assertEquals("Nope", failed.message, "error text returned");
		assertEquals("Error: Nope", messages[1], "server error auto-shown");

		var invalid = SuperLoader.decodeJson("json", "not json");
		assertEquals(false, invalid.success, "invalid JSON rejected");
		assertEquals(true, invalid.message.indexOf("invalid response from json") == 0, "invalid JSON reports source");
	}

	private static function testDecodeUrlVariables():Void {
		var result = SuperLoader.decodeUrlVariables("vars", "success=1&message=OK&level_id=42", false);
		assertEquals(true, result.success, "URLVariables success accepted");
		assertEquals("42", Std.string(Reflect.field(result.data, "level_id")), "URLVariables parsed field");
		assertEquals("OK", result.message, "URLVariables message returned");
	}

	private static function testFormatIoError():Void {
		assertEquals("Error #2048: policy problem (HTTP 403)", SuperLoader.formatIoError("url", 403, "Error #2048: policy problem"),
			"Flash-style error number is preserved");
		assertEquals("Error: timeout", SuperLoader.formatIoError("url", 0, "timeout"), "plain IO error gets Error prefix");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
