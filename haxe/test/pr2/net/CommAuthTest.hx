package pr2.net;

import com.jiggmin.data.Encryptor;

class CommAuthTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testInitializesEncryptedTokens();
		trace('CommAuthTest passed $assertions assertions');
	}

	private static function testInitializesEncryptedTokens():Void {
		CommAuth.resetForTests();
		assertEquals(null, CommAuth.tokenEntryForTests("1"), "reset clears default token entry");
		assertEquals("QHE0NSNwKWZZQVEhU19xMA==", CommAuth.getToken(2), "default communication token");
		assertEquals("ayo3JnBGQCZVRiEhVjFAQA==", CommAuth.getToken(10), "server 10 communication token");
		var defaultEntry = CommAuth.tokenEntryForTests("1");
		var serverTenEntry = CommAuth.tokenEntryForTests("10");
		assertNotNull(defaultEntry, "default token entry");
		assertNotNull(serverTenEntry, "server 10 token entry");
		assertEquals(true, Std.isOfType(defaultEntry.key, Encryptor), "default token stores encryptor key");
		assertEquals(true, Std.isOfType(serverTenEntry.key, Encryptor), "server 10 token stores encryptor key");
		assertEquals(true, defaultEntry.hidden != "QHE0NSNwKWZZQVEhU19xMA==", "default token is not stored in plaintext");
		assertEquals(true, serverTenEntry.hidden != "ayo3JnBGQCZVRiEhVjFAQA==", "server 10 token is not stored in plaintext");
		CommAuth.resetForTests();
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) throw '$message: value was null';
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
