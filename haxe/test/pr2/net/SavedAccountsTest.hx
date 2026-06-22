package pr2.net;

class SavedAccountsTest {
	private static var assertions = 0;

	public static function main():Void {
		SavedAccounts.disablePersistenceForTests();
		SavedAccounts.add("  Alice  ", "first");
		SavedAccounts.add("Bob", "second");
		SavedAccounts.add("alice", "updated");
		assertEquals(2, SavedAccounts.getAll().length, "case-insensitive replacement");
		assertEquals("alice", SavedAccounts.getAll()[0].name, "recent account moves first");
		assertEquals("updated", SavedAccounts.getAll()[0].token, "token updated");
		assertEquals(true, SavedAccounts.deleteAccount("second", true), "delete by token");
		assertEquals(false, SavedAccounts.deleteAccount("missing"), "missing delete rejected");
		assertEquals(1, SavedAccounts.getAll().length, "one account remains");
		trace('SavedAccountsTest passed $assertions assertions');
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
