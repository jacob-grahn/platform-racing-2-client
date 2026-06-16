package pr2.level;

import pr2.level.ServerLevel.DecodedBlock;

class ServerLevelDecoderTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testM3RelativeWalk();
		testM2SegMultOne();
		testM4Options();
		testM1HexAbsolute();
		testUnsupportedModeThrows();
		trace('ServerLevelDecoderTest passed $assertions assertions');
	}

	private static function testM3RelativeWalk():Void {
		// mode ` bgColor ` blocks. Block tokens: "relX;relY[;code]".
		var level = ServerLevelDecoder.decode("m3`e0c8b8`334;335;11,1;0;12,0;1;0,1;0");
		assertEquals(0xE0C8B8, level.bgColor, "m3 bg color");
		assertEquals(4, level.blocks.length, "m3 block count");
		// 334*30, 335*30 with start code 11 -> resolved 111.
		assertBlock(level.blocks[0], ObjectCodes.BLOCK_START1, 10020, 10050, "m3 first start");
		assertBlock(level.blocks[1], ObjectCodes.BLOCK_START2, 10050, 10050, "m3 second start");
		// code omitted -> keeps previous (0 -> basic1) after stepping y.
		assertBlock(level.blocks[2], ObjectCodes.BLOCK_BASIC1, 10050, 10080, "m3 new code 0");
		assertBlock(level.blocks[3], ObjectCodes.BLOCK_BASIC1, 10080, 10080, "m3 carried code");
	}

	private static function testM2SegMultOne():Void {
		var level = ServerLevelDecoder.decode("m2`000000`5;7;4");
		assertEquals(1, level.blocks.length, "m2 block count");
		// segMult 1: coords are not multiplied.
		assertBlock(level.blocks[0], ObjectCodes.BLOCK_BRICK, 5, 7, "m2 unscaled coords");
	}

	private static function testM4Options():Void {
		var level = ServerLevelDecoder.decode("m4`000000`0;0;19;3-4-5,2;0");
		assertEquals(2, level.blocks.length, "m4 block count");
		assertBlock(level.blocks[0], ObjectCodes.BLOCK_MOVE, 0, 0, "m4 move block");
		assertEquals("3-4-5", level.blocks[0].opts, "m4 options preserved");
		// Carried code, stepped x by 2 segments.
		assertBlock(level.blocks[1], ObjectCodes.BLOCK_MOVE, 60, 0, "m4 carried code + step");
	}

	private static function testM1HexAbsolute():Void {
		// First block token is the hex base offset; the rest are code;x;y in hex.
		var level = ServerLevelDecoder.decode("m1`ffffff`5;5,2;3;4");
		assertEquals(1, level.blocks.length, "m1 block count");
		// code 0x2 -> 102, x 0x3 + 0x5, y 0x4 + 0x5.
		assertBlock(level.blocks[0], ObjectCodes.BLOCK_BASIC3, 8, 9, "m1 hex + base offset");
	}

	private static function testUnsupportedModeThrows():Void {
		assertions++;
		try {
			ServerLevelDecoder.decode("zz`000000`0;0;0");
		} catch (_:Dynamic) {
			return;
		}
		throw "unsupported read mode should throw";
	}

	private static function assertBlock(block:DecodedBlock, code:Int, x:Int, y:Int, message:String):Void {
		assertEquals(code, block.code, message + " code");
		assertEquals(x, block.x, message + " x");
		assertEquals(y, block.y, message + " y");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
