package pr2.net;

class SavedAccountsTest {
	private static var assertions = 0;

	public static function main():Void {
		testStoreIdMatchesFlashBaseUrl();
		testLoadsFlashArrayShape();
		testAddUpdatesTokenAndMovesAccountFirst();
		testDeleteByNameAndTokenMode();
		testGetAllReturnsStaticAccountsArray();
		SavedAccounts.disablePersistenceForTests();
		trace('SavedAccountsTest passed $assertions assertions');
	}

	private static function testStoreIdMatchesFlashBaseUrl():Void {
		assertEquals("pr2hub_dev_logged_in", SavedAccounts.storeIdForTests("https://pr2hub.dev"), "dev store id");
		assertEquals("pr2hub_logged_in", SavedAccounts.storeIdForTests("https://pr2hub.com"), "production store id");
	}

	private static function testLoadsFlashArrayShape():Void {
		SavedAccounts.setRawAccountsForTests([
			{name: "  Alice  ", token: "first"},
			{name: "   ", token: "blank"},
			{name: "Bob", token: "second"},
		]);
		assertEquals(2, SavedAccounts.getAll().length, "blank saved account names ignored");
		assertEquals("Alice", SavedAccounts.getAll()[0].name, "loaded names are trimmed");
		assertEquals("first", SavedAccounts.getAll()[0].token, "loaded token preserved");
	}

	private static function testAddUpdatesTokenAndMovesAccountFirst():Void {
		SavedAccounts.useMemoryStoreForTests();
		SavedAccounts.add("  Alice  ", "first");
		SavedAccounts.add("Bob", "second");
		SavedAccounts.add("alice", "updated");
		assertEquals(2, SavedAccounts.getAll().length, "case-insensitive replacement");
		assertEquals("Alice", SavedAccounts.getAll()[0].name, "updated account keeps original stored name");
		assertEquals("updated", SavedAccounts.getAll()[0].token, "token updated");
		assertEquals("Alice", Reflect.field((cast SavedAccounts.rawAccountsForTests():Array<Dynamic>)[0], "name"), "raw store keeps array object shape");
		assertEquals("updated", Reflect.field((cast SavedAccounts.rawAccountsForTests():Array<Dynamic>)[0], "token"), "raw store keeps token field");
	}

	private static function testDeleteByNameAndTokenMode():Void {
		SavedAccounts.useMemoryStoreForTests();
		SavedAccounts.add("Alice", "first");
		SavedAccounts.add("Bob", "second");
		assertEquals(true, SavedAccounts.deleteAccount("second", "token"), "delete by token mode");
		assertEquals(false, SavedAccounts.deleteAccount("missing"), "missing delete rejected");
		assertEquals(true, SavedAccounts.deleteAccount("Alice", "name"), "delete by name mode");
		assertEquals(0, SavedAccounts.getAll().length, "all accounts removed");
	}

	private static function testGetAllReturnsStaticAccountsArray():Void {
		SavedAccounts.useMemoryStoreForTests();
		SavedAccounts.add("Alice", "first");
		var all = SavedAccounts.getAll();
		all.push({name: "Bob", token: "second"});
		assertEquals(2, SavedAccounts.getAll().length, "getAll returns Flash static array identity");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
