package pr2.net;

import pr2.net.LoginSocketProtocol.LoginSocketMessage;

class LoginSocketProtocolTest {
	private static var assertions = 0;

	public static function main():Void {
		testBuildsLoginIdRequestFrame();
		testUsesServerTenSocketToken();
		testSkipsSendNumberTwelve();
		testParsesBufferedLoginId();
		testParsesLoginResponses();
		trace('LoginSocketProtocolTest passed $assertions assertions');
	}

	private static function testBuildsLoginIdRequestFrame():Void {
		var protocol = new LoginSocketProtocol(2);
		assertEquals("138`1`request_login_id`" + LoginSocketProtocol.END_CHAR, protocol.requestLoginIdFrame(), "login id request frame");
	}

	private static function testUsesServerTenSocketToken():Void {
		var protocol = new LoginSocketProtocol(10);
		assertEquals("1a6`1`request_login_id`" + LoginSocketProtocol.END_CHAR, protocol.requestLoginIdFrame(), "server 10 login id request frame");
	}

	private static function testSkipsSendNumberTwelve():Void {
		var protocol = new LoginSocketProtocol(2);
		var frame = "";
		for (_ in 0...12) {
			frame = protocol.commandFrame("noop`");
		}
		assertContains(frame, "`13`noop`" + LoginSocketProtocol.END_CHAR, "send sequence skips 12");
	}

	private static function testParsesBufferedLoginId():Void {
		var protocol = new LoginSocketProtocol(2);
		assertEquals(0, protocol.append("abc`1`setLoginID`").length, "partial frame waits for delimiter");
		var messages = protocol.append("90210" + LoginSocketProtocol.END_CHAR + "abc`2`other`" + LoginSocketProtocol.END_CHAR);
		assertEquals(2, messages.length, "complete buffered messages");
		assertLoginId("90210", messages[0], "login id message");
		assertOther("other", messages[1], "other message");
	}

	private static function testParsesLoginResponses():Void {
		assertLoginSuccessful(7, "Player", LoginSocketProtocol.parseFrame("abc`1`loginSuccessful`7`Player"), "login success state");
		assertLoginFailure("bad login", LoginSocketProtocol.parseFrame("abc`1`loginFailure`bad`login"), "login failure message");
		assertEquals(null, LoginSocketProtocol.parseFrame("too-short"), "short frame ignored");
	}

	private static function assertLoginId(expected:String, actual:LoginSocketMessage, message:String):Void {
		assertions++;
		switch (actual) {
			case LoginId(loginId) if (loginId == expected):
			case _:
				throw '$message: expected LoginId($expected), got $actual';
		}
	}

	private static function assertLoginSuccessful(expectedGroup:Int, expectedName:String, actual:Null<LoginSocketMessage>, message:String):Void {
		assertions++;
		switch (actual) {
			case LoginSuccessful(group, userName) if (group == expectedGroup && userName == expectedName):
			case _:
				throw '$message: expected LoginSuccessful($expectedGroup, $expectedName), got $actual';
		}
	}

	private static function assertLoginFailure(expected:String, actual:Null<LoginSocketMessage>, message:String):Void {
		assertions++;
		switch (actual) {
			case LoginFailure(error) if (error == expected):
			case _:
				throw '$message: expected LoginFailure($expected), got $actual';
		}
	}

	private static function assertOther(expected:String, actual:LoginSocketMessage, message:String):Void {
		assertions++;
		switch (actual) {
			case Other(command) if (command == expected):
			case _:
				throw '$message: expected Other($expected), got $actual';
		}
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
