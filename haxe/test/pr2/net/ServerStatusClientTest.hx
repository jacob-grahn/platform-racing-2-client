package pr2.net;

class ServerStatusClientTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testParsesServerList();
		trace('ServerStatusClientTest passed $assertions assertions');
	}

	private static function testParsesServerList():Void {
		var result = ServerStatusClient.parse('{"servers":[{"address":" Derron.example.com ","port":"9160","server_id":"2","server_name":"Derron","status":"online","population":"12","guild_id":"0","happy_hour":"1"}]}');
		assertEquals(1, result.servers.length, "server count");
		assertEquals(" Derron.example.com ", result.servers[0].address, "address");
		assertEquals(9160, result.servers[0].port, "port");
		assertEquals(2, result.servers[0].serverId, "server id");
		assertEquals("Derron", result.servers[0].name, "server name");
		assertEquals("online", result.servers[0].status, "status");
		assertEquals(12, result.servers[0].population, "population");
		assertEquals(true, result.servers[0].happyHour, "happy hour");
		assertEquals("Derron (12 online)", result.servers[0].label(), "label");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
