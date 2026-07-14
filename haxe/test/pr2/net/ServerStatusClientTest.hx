package pr2.net;

class ServerStatusClientTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testParsesServerList();
		if (pr2.DeterministicTestMode.finishSmokeSuite("ServerStatusClientTest")) return;
		testFlashLabels();
		testOrdersAndSelectsServers();
		testBetaAndInvalidFiltering();
		testDuplicateServerIdsAreSkipped();
		testFallbackSelectionUsesFirstSortedServer();
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
		assertEquals("!! Derron (online)", result.servers[0].label(), "label");
	}

	private static function testFlashLabels():Void {
		assertEquals("!! Derron (12 online)", server(2, 9160, 0, 12, "open", true).label(), "happy-hour open label");
		assertEquals("* Guild (down)", server(8, 9000, 42, 0, "down", false, "Guild").label(), "private down label");
	}

	private static function testOrdersAndSelectsServers():Void {
		var ordered = ServerStatusClient.selectList([
			server(9, 9009, 20, 5),
			server(4, 9004, 0, 190),
			server(7, 9007, 20, 30),
			server(2, 9002, 0, 20),
			server(6, 9006, 42, 10)
		], 42);
		assertEquals("6,2,4,7,9", [for (entry in ordered) entry.serverId].join(","), "guild/public/private ordering");
		assertEquals(0, ServerStatusClient.preferredIndex(ordered, 42), "own guild server preferred");
		assertEquals(1, ServerStatusClient.preferredIndex(ordered), "non-full public server preferred");
	}

	private static function testBetaAndInvalidFiltering():Void {
		var selected = ServerStatusClient.selectList([
			server(1, 9001, 0, 1),
			server(2, 9002, 205, 1),
			new ServerInfo("", 0, 3, "Invalid", "open", 1, 205, false)
		], 0, true);
		assertEquals(1, selected.length, "beta and invalid filtering count");
		assertEquals(2, selected[0].serverId, "beta keeps guild 205 server");
	}

	private static function testDuplicateServerIdsAreSkipped():Void {
		var selected = ServerStatusClient.selectList([
			server(2, 9002, 0, 20, "open", false, "First"),
			server(2, 9001, 0, 30, "open", false, "Duplicate"),
			server(3, 9003, 0, 10, "open", false, "Third")
		]);
		assertEquals("2,3", [for (entry in selected) entry.serverId].join(","), "duplicate server ids are not repeated");
		assertEquals(9001, selected[0].port, "first sorted duplicate is kept");
	}

	private static function testFallbackSelectionUsesFirstSortedServer():Void {
		var selected = ServerStatusClient.selectList([
			server(5, 9005, 17, 25, "full"),
			server(3, 9003, 0, 190, "full"),
			server(4, 9004, 0, 180, "open")
		], 17);
		assertEquals("5,3,4", [for (entry in selected) entry.serverId].join(","), "fallback list keeps Flash sorting");
		assertEquals(0, ServerStatusClient.preferredIndex(selected, 17), "fallback selects first sorted server when no open preference exists");
	}

	private static function server(id:Int, port:Int, guild:Int, population:Int, status:String = "open", happy:Bool = false, name:String = "Derron"):ServerInfo {
		return new ServerInfo("example.com", port, id, name, status, population, guild, happy);
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
