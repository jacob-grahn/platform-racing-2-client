package pr2.net;

class JsonClientTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		SuperLoader.showMessage = function(_:String):Void {};
		testDecode();
		testDecodeError();
		SuperLoader.resetHooks();
		trace('JsonClientTest passed $assertions assertions');
	}

	private static function testDecode():Void {
		var result:Dynamic = null;
		var error:Null<String> = null;
		JsonClient.decode("fixture", '{"ok":true,"items":[1,2]}', value -> result = value, message -> error = message);

		assertEquals(true, Reflect.field(result, "ok"), "object field");
		assertEquals(2, (cast Reflect.field(result, "items") : Array<Dynamic>).length, "array field");
		assertEquals(null, error, "valid JSON has no error");
	}

	private static function testDecodeError():Void {
		var called = false;
		var error:Null<String> = null;
		JsonClient.decode("fixture", "not-json", _ -> called = true, message -> error = message);

		assertEquals(false, called, "invalid JSON does not call success");
		assertEquals(true, error != null && error.indexOf("invalid response from fixture") == 0, "parse error identifies source");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
