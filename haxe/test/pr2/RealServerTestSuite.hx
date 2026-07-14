package pr2;

import pr2.net.LoginSocketProtocol;
import pr2.net.LoginSocketProtocol.LoginSocketMessage;
import pr2.net.ServerStatusClient;

class RealServerTestSuite {
	private static var assertions:Int = 0;

	public static function main():Void {
		testParsesUsableServerForConnect();
		testBuildsConnectHandshake();
		trace('RealServerTestSuite passed $assertions assertions');
	}

	private static function testParsesUsableServerForConnect():Void {
		var result = ServerStatusClient.parse('{"servers":[{"address":"derrn.example.com","port":"9160","server_id":"2","server_name":"Derron","status":"online","population":"12","guild_id":"0","happy_hour":"1"}]}');
		assertEquals(1, result.servers.length, "server count");

		var server = result.servers[0];
		assertEquals("derrn.example.com", server.address, "server address");
		assertEquals(9160, server.port, "server port");
		assertEquals(2, server.serverId, "server id");
		assertEquals("Derron (12 online)", server.label(), "server label");
		assertEquals("wss://pr2hub.com/gameservers/2", server.websocketUrl(false), "gameserver relay URL");
		assertEquals("wss://pr2hub.com/gameservers/2", server.websocketUrl(true), "gameserver relay URL is always secure");
	}

	private static function testBuildsConnectHandshake():Void {
		var protocol = new LoginSocketProtocol(2);
		assertEquals("138`1`request_login_id`" + LoginSocketProtocol.END_CHAR, protocol.requestLoginIdFrame(), "login id request frame");

		var messages = protocol.append("abc`1`setLoginID`12345" + LoginSocketProtocol.END_CHAR);
		assertEquals(1, messages.length, "login id response count");
		assertLoginId("12345", messages[0], "login id response");
	}

	private static function assertLoginId(expected:String, actual:LoginSocketMessage, message:String):Void {
		assertions++;
		switch (actual) {
			case LoginId(loginId) if (loginId == expected):
			case _:
				throw '$message: expected LoginId($expected), got $actual';
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
