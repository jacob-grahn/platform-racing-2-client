package pr2.crypto;

import com.hurlant.crypto.symmetric.AESKey;
import com.hurlant.crypto.symmetric.CBCMode;
import com.hurlant.crypto.symmetric.IMode;
import com.hurlant.crypto.symmetric.IPad;
import com.hurlant.crypto.symmetric.ISymmetricKey;

class HurlantSymmetricCompatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testAesBlockVectors();
		testCbcPkcs5WithForcedIV();
		testCustomPaddingAndInterfaces();
		testDecryptRequiresIVAndDispose();
		trace('HurlantSymmetricCompatTest passed $assertions assertions');
	}

	private static function testAesBlockVectors():Void {
		assertAesVector(
			"000102030405060708090a0b0c0d0e0f",
			"00112233445566778899aabbccddeeff",
			"69c4e0d86a7b0430d8cdb78070b4c55a",
			"aes128"
		);
		assertAesVector(
			"000102030405060708090a0b0c0d0e0f1011121314151617",
			"00112233445566778899aabbccddeeff",
			"dda97ca4864cdfe06eaf70a0ec0d7191",
			"aes192"
		);
		assertAesVector(
			"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
			"00112233445566778899aabbccddeeff",
			"8ea2b7ca516745bfeafc49904b496089",
			"aes256"
		);
	}

	private static function testCbcPkcs5WithForcedIV():Void {
		var key = ByteArrayCompat.fromHex("2b7e151628aed2a6abf7158809cf4f3c");
		var iv = ByteArrayCompat.fromHex("000102030405060708090a0b0c0d0e0f");
		var plain = ByteArrayCompat.fromHex("6bc1bee22e409f96e93d7e117393172a");
		var mode = new CBCMode(new AESKey(key));
		mode.IV = iv;
		mode.encrypt(plain);
		assertEquals("7649abac8119b246cee98e9b12e9197d8964e0b149c10b7b682e6e39aaeb731c", plain.toHex(), "CBC PKCS5 encrypt vector");
		assertEquals("000102030405060708090a0b0c0d0e0f", mode.IV.toHex(), "CBC stores forced IV");
		assertEquals("aes128-cbc", mode.toString(), "CBC toString");

		var decryptMode = new CBCMode(new AESKey(key));
		decryptMode.IV = iv;
		decryptMode.decrypt(plain);
		assertEquals("6bc1bee22e409f96e93d7e117393172a", plain.toHex(), "CBC PKCS5 decrypt unpads");
	}

	private static function testCustomPaddingAndInterfaces():Void {
		var pad = new IdentityPad();
		var key:ISymmetricKey = new AESKey(ByteArrayCompat.fromHex("2b7e151628aed2a6abf7158809cf4f3c"));
		var mode:IMode = new CBCMode(key, pad);
		var cbc:CBCMode = cast mode;
		cbc.IV = ByteArrayCompat.fromHex("000102030405060708090a0b0c0d0e0f");
		var block = ByteArrayCompat.fromHex("6bc1bee22e409f96e93d7e117393172a");
		mode.encrypt(block);
		assertEquals(16, pad.blockSize, "custom pad receives block size");
		assertEquals(1, pad.padCalls, "custom pad called on encrypt");
		assertEquals("7649abac8119b246cee98e9b12e9197d", block.toHex(), "CBC custom pad leaves one-block vector");
		mode.decrypt(block);
		assertEquals(1, pad.unpadCalls, "custom pad called on decrypt");
		assertEquals("6bc1bee22e409f96e93d7e117393172a", block.toHex(), "CBC custom pad decrypt round trip");
	}

	private static function testDecryptRequiresIVAndDispose():Void {
		var mode = new CBCMode(new AESKey(ByteArrayCompat.fromHex("000102030405060708090a0b0c0d0e0f")));
		var threw = false;
		try {
			mode.decrypt(ByteArrayCompat.fromHex("69c4e0d86a7b0430d8cdb78070b4c55a"));
		} catch (e:Dynamic) {
			threw = Std.string(e).indexOf("an IV must be set before calling decrypt()") >= 0;
		}
		assertEquals(true, threw, "CBC decrypt requires IV");

		var key = new AESKey(ByteArrayCompat.fromHex("000102030405060708090a0b0c0d0e0f"));
		mode = new CBCMode(key);
		mode.IV = ByteArrayCompat.fromHex("000102030405060708090a0b0c0d0e0f");
		mode.dispose();
		assertEquals(null, @:privateAccess mode.key, "IVMode dispose clears key");
		assertEquals(null, @:privateAccess mode.padding, "IVMode dispose clears padding");
		assertEquals(null, @:privateAccess mode.prng, "IVMode dispose clears prng");
		assertEquals(null, @:privateAccess mode.iv, "IVMode dispose clears iv");
		assertEquals(null, @:privateAccess mode.lastIV, "IVMode dispose clears lastIV");
		assertEquals(0, @:privateAccess key.keyLength, "AESKey dispose clears key length");
		assertEquals(0, @:privateAccess key.roundKeys.length, "AESKey dispose clears round keys");
	}

	private static function assertAesVector(keyHex:String, plainHex:String, cipherHex:String, label:String):Void {
		var key = new AESKey(ByteArrayCompat.fromHex(keyHex));
		assertEquals(label, key.toString(), '$label toString');
		assertEquals(16, key.getBlockSize(), '$label block size');
		var block = ByteArrayCompat.fromHex("ffff" + plainHex + "eeee");
		block.position = 7;
		key.encrypt(block, 2);
		assertEquals("ffff" + cipherHex + "eeee", block.toHex(), '$label encrypt at offset');
		assertEquals(7, block.position, '$label encrypt keeps position');
		key.decrypt(block, 2);
		assertEquals("ffff" + plainHex + "eeee", block.toHex(), '$label decrypt at offset');
		assertEquals(7, block.position, '$label decrypt keeps position');
		key.dispose();
		assertEquals("aes0", key.toString(), '$label dispose clears toString length');
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}

private class IdentityPad implements IPad {
	public var blockSize:Int = 0;
	public var padCalls:Int = 0;
	public var unpadCalls:Int = 0;

	public function new() {}

	public function pad(a:ByteArrayCompat):Void {
		padCalls++;
	}

	public function unpad(a:ByteArrayCompat):Void {
		unpadCalls++;
	}

	public function setBlockSize(bs:Int):Void {
		blockSize = bs;
	}
}
