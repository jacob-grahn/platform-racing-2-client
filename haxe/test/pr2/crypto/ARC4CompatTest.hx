package pr2.crypto;

import com.hurlant.crypto.prng.ARC4;
import com.hurlant.crypto.prng.IPRNG;
import com.hurlant.crypto.symmetric.IStreamCipher;

class ARC4CompatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testStreamVectorAndInterfaces();
		if (pr2.DeterministicTestMode.finishSmokeSuite("ARC4CompatTest")) return;
		testMutableBlockEncryptDecrypt();
		testDisposeWipesState();
		trace('ARC4CompatTest passed $assertions assertions');
	}

	private static function testStreamVectorAndInterfaces():Void {
		var key = new ByteArrayCompat();
		key.writeUTFBytes("Key");
		var prng:IPRNG = new ARC4(key);
		var stream:IStreamCipher = cast prng;
		assertEquals(256, prng.getPoolSize(), "ARC4 pool size");
		assertEquals(1, stream.getBlockSize(), "ARC4 block size");
		assertEquals("rc4", prng.toString(), "ARC4 toString");

		var expected = [0xEB, 0x9F, 0x77, 0x81, 0xB7, 0x34, 0xCA, 0x72, 0xA7];
		for (i in 0...expected.length) {
			assertEquals(expected[i], prng.next(), 'ARC4 keystream byte $i');
		}
	}

	private static function testMutableBlockEncryptDecrypt():Void {
		var key = new ByteArrayCompat();
		key.writeUTFBytes("Key");
		var block = new ByteArrayCompat();
		block.writeUTFBytes("Plaintext");
		block.position = 4;
		var cipher = new ARC4(key);
		cipher.encrypt(block);
		assertEquals("bbf316e8d940af0ad3", block.toHex(), "ARC4 encrypt mutates block bytes");
		assertEquals(4, block.position, "ARC4 encrypt leaves position untouched");

		var decipher = new ARC4(key);
		decipher.decrypt(block);
		assertEquals("Plaintext", block.toBytes().toString(), "ARC4 decrypt reverses encryption");
		assertEquals(4, block.position, "ARC4 decrypt leaves position untouched");
	}

	private static function testDisposeWipesState():Void {
		var key = new ByteArrayCompat();
		key.writeUTFBytes("Key");
		var cipher = new ARC4(key);
		assertEquals(0xEB, cipher.next(), "ARC4 first byte before dispose");
		cipher.dispose();
		assertEquals(null, @:privateAccess cipher.s, "ARC4 dispose clears state");
		assertEquals(0, @:privateAccess cipher.i, "ARC4 dispose resets i");
		assertEquals(0, @:privateAccess cipher.j, "ARC4 dispose resets j");
		assertEquals("rc4", cipher.toString(), "ARC4 toString survives dispose");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
