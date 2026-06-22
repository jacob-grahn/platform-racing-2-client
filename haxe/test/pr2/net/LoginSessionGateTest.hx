package pr2.net;

import pr2.net.LoginSessionGate.LoginSessionResult;

class LoginSessionGateTest {
	private static var assertions = 0;

	public static function main():Void {
		testWaitsForBothResponsesInEitherOrder();
		trace('LoginSessionGateTest passed $assertions assertions');
	}

	private static function testWaitsForBothResponsesInEitherOrder():Void {
		for (socketFirst in [false, true]) {
			var ready:Null<LoginSessionResult> = null;
			var gate = new LoginSessionGate(function(result) ready = result);
			var auth = LoginAuthClient.parse('{"success":true,"userId":42,"email":1,"token":"abc","guild":9,"guildOwner":true,"guildName":"Racers","emblem":"star","favoriteLevels":[3,"7"]}');
			if (socketFirst) gate.acceptSocket(2, "Player") else gate.acceptHttp(auth);
			assertEquals(null, ready, "one response cannot establish session");
			if (socketFirst) gate.acceptHttp(auth) else gate.acceptSocket(2, "Player");
			assertEquals("Player", ready.userName, "socket name");
			assertEquals(2, ready.group, "socket group");
			assertEquals(42, ready.userId, "http user id");
			assertEquals(true, ready.hasEmail, "http email state");
			assertEquals("abc", ready.token, "http token");
			assertEquals(9, ready.guildId, "http guild");
			assertEquals("3,7", ready.favoriteLevels.join(","), "http favorites");
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
