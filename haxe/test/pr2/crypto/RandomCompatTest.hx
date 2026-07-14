package pr2.crypto;

import com.hurlant.crypto.prng.IPRNG;
import com.hurlant.crypto.prng.Random;

class RandomCompatTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testConstructorAndSeedSurface();
		if (pr2.DeterministicTestMode.finishSmokeSuite("RandomCompatTest")) return;
		testLazyInitAndNextBytes();
		testAutoSeedAndDispose();
		testDefaultArc4ToString();
		trace('RandomCompatTest passed $assertions assertions');
	}

	private static function testConstructorAndSeedSurface():Void {
		var random = new Random(RecordingPRNG);
		assertEquals("random-recording", random.toString(), "Random toString includes state");
		assertEquals(8, @:privateAccess random.psize, "Random pool size comes from state");
		assertEquals(8, @:privateAccess random.pool.length, "Random constructor fills pool");
		assertEquals(4, @:privateAccess random.pptr, "Random constructor seeds first word");
		assertEquals(true, @:privateAccess random.seeded, "Random constructor marks seeded");
		assertEquals(false, @:privateAccess random.ready, "Random waits to initialize state");

		@:privateAccess random.pool = ByteArrayCompat.fromHex("0001020304050607");
		@:privateAccess random.pptr = 0;
		random.seed(0x01020304);
		assertEquals("0402000204050607", @:privateAccess random.pool.toHex(), "Random seed XORs little-endian bytes");
		assertEquals(4, @:privateAccess random.pptr, "Random seed advances pointer");
	}

	private static function testLazyInitAndNextBytes():Void {
		var random = new Random(RecordingPRNG);
		var state:RecordingPRNG = cast @:privateAccess random.state;
		state.queue = [0xAA, 0xBB, 0xCC];
		@:privateAccess random.pool = ByteArrayCompat.fromHex("01020304");
		@:privateAccess random.psize = 4;
		@:privateAccess random.pptr = 0;
		@:privateAccess random.ready = false;
		@:privateAccess random.seeded = true;

		assertEquals(0xAA, random.nextByte(), "Random returns first PRNG byte");
		assertEquals("01020304", state.initHex, "Random lazily initializes state with pool");
		assertEquals(1, state.initCount, "Random initializes state once");
		assertEquals(0, @:privateAccess random.pool.length, "Random clears pool after init");
		assertEquals(true, @:privateAccess random.ready, "Random becomes ready");

		var out = new ByteArrayCompat();
		out.writeByte(0x11);
		random.nextBytes(out, 2);
		assertEquals("11bbcc", out.toHex(), "Random nextBytes appends bytes");
		assertEquals(1, state.initCount, "Random nextBytes reuses ready state");
	}

	private static function testAutoSeedAndDispose():Void {
		var random = new Random(RecordingPRNG);
		@:privateAccess random.pool = ByteArrayCompat.fromHex("0000000000000000");
		@:privateAccess random.pptr = 0;
		@:privateAccess random.seeded = false;
		random.autoSeed();
		assertEquals(true, @:privateAccess random.seeded, "Random autoSeed marks seeded");
		assertEquals(true, @:privateAccess random.pptr >= 0 && @:privateAccess random.pptr < @:privateAccess random.psize, "Random autoSeed keeps pointer in pool");

		var state:RecordingPRNG = cast @:privateAccess random.state;
		random.dispose();
		assertEquals(true, state.disposed, "Random dispose disposes state");
		assertEquals(null, @:privateAccess random.pool, "Random dispose clears pool");
		assertEquals(null, @:privateAccess random.state, "Random dispose clears state");
		assertEquals(0, @:privateAccess random.psize, "Random dispose resets pool size");
		assertEquals(0, @:privateAccess random.pptr, "Random dispose resets pointer");
	}

	private static function testDefaultArc4ToString():Void {
		var random = new Random();
		assertEquals("random-rc4", random.toString(), "Random defaults to ARC4");
		random.dispose();
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}

private class RecordingPRNG implements IPRNG {
	public var queue:Array<Int> = [];
	public var initHex:String = null;
	public var initCount:Int = 0;
	public var disposed:Bool = false;

	public function new() {}

	public function getPoolSize():Int {
		return 8;
	}

	public function init(key:ByteArrayCompat):Void {
		initHex = key.toHex();
		initCount++;
	}

	public function next():Int {
		return queue.length == 0 ? 0 : queue.shift();
	}

	public function dispose():Void {
		disposed = true;
	}

	public function toString():String {
		return "recording";
	}
}
