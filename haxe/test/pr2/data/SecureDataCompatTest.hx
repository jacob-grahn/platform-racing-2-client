package pr2.data;

import com.jiggmin.data.Encryptor;
import com.jiggmin.data.SecureData;
import com.jiggmin.data.SecureStore;

class SecureDataCompatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testNumberEntriesUseHiddenValuePlusKey();
		testBoolRoundTrip();
		testEncryptedStringSaltRoundTrip();
		testStaticSecureDataFacade();
		testRemoveClearsEntries();
		trace('SecureDataCompatTest passed $assertions assertions');
	}

	private static function testNumberEntriesUseHiddenValuePlusKey():Void {
		var store = new SecureStore();
		store.setNumber("rank", 42);
		var entry = store.entryForTests("rank");
		assertNotNull(entry, "numeric entry");
		assertClose(42, (entry.hidden:Float) - (entry.key:Float), "hidden number subtracts key");
		assertEquals(42.0, store.getNumber("rank"), "numeric getter");

		store.setNumber("rank", 47);
		assertEquals(true, store.entryForTests("rank") == entry, "existing numeric entry updates in place");
		assertClose(47, (entry.hidden:Float) - (entry.key:Float), "updated hidden number subtracts key");
	}

	private static function testBoolRoundTrip():Void {
		var store = new SecureStore();
		assertEquals(false, store.getBool("flag"), "missing bool defaults false");
		store.setBool("flag", true);
		assertEquals(true, store.getBool("flag"), "true bool");
		store.setBool("flag", false);
		assertEquals(false, store.getBool("flag"), "false bool");
	}

	private static function testEncryptedStringSaltRoundTrip():Void {
		var store = new SecureStore();
		store.initEncryptor("session", "salt-value");
		var entry = store.entryForTests("session");
		assertNotNull(entry, "encrypted entry");
		assertEquals(true, Std.isOfType(entry.key, Encryptor), "entry stores encryptor as key");
		assertEquals(true, entry.hidden != "salt-value", "salt is stored encrypted");
		assertEquals("salt-value", store.getString("session"), "encrypted salt decrypts");
	}

	private static function testStaticSecureDataFacade():Void {
		SecureData.resetForTests();
		assertEquals(0.0, SecureData.getNumber("missing"), "missing static number");
		SecureData.setNumber("userRank", 5);
		assertEquals(5.0, SecureData.getNumber("userRank"), "static number");
		SecureData.setBool("trial", true);
		assertEquals(true, SecureData.getBool("trial"), "static bool");
		SecureData.initEncryptor("salt", "verify");
		assertEquals("verify", SecureData.getString("salt"), "static encrypted string");
	}

	private static function testRemoveClearsEntries():Void {
		var store = new SecureStore();
		store.setNumber("rank", 42);
		store.remove();
		assertEquals(null, store.entryForTests("rank"), "remove clears entries");
		assertEquals(0.0, store.getNumber("rank"), "removed number defaults");
		assertEquals(null, store.getString("rank"), "removed string defaults");
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) throw '$message: value was null';
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000000000001) throw '$message: expected $expected, got $actual';
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
