package pr2.level;

import pr2.level.Level.LevelBlock;

class LevelDecoderTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testM3RelativeWalk();
		if (pr2.DeterministicTestMode.finishSmokeSuite("LevelDecoderTest")) return;
		testM3ArtBackgroundAndLayers();
		testM2SegMultOne();
		testM4Options();
		testM1HexAbsolute();
		testUnsupportedModeThrows();
		trace('LevelDecoderTest passed $assertions assertions');
	}

	private static function testM3RelativeWalk():Void {
		// mode ` bgColor ` blocks. Block tokens: "relX;relY[;code]".
		var level = LevelDecoder.decode("m3`e0c8b8`334;335;11,1;0;12,0;1;0,1;0");
		assertEquals(0xE0C8B8, level.bgColor, "m3 bg color");
		assertEquals(4, level.blocks.length, "m3 block count");
		// 334*30, 335*30 with start code 11 -> resolved 111.
		assertBlock(level.blocks[0], ObjectCodes.BLOCK_START1, 10020, 10050, "m3 first start");
		assertBlock(level.blocks[1], ObjectCodes.BLOCK_START2, 10050, 10050, "m3 second start");
		// code omitted -> keeps previous (0 -> basic1) after stepping y.
		assertBlock(level.blocks[2], ObjectCodes.BLOCK_BASIC1, 10050, 10080, "m3 new code 0");
		assertBlock(level.blocks[3], ObjectCodes.BLOCK_BASIC1, 10080, 10080, "m3 carried code");
	}

	private static function testM3ArtBackgroundAndLayers():Void {
		var level = LevelDecoder.decode([
			"m3",
			"ffffff",
			"0;0;11",
			"10;20;1;150;50,5;5;t;hello|world;16711680;200;100",
			"",
			"",
			"c123456,t4,d1;2;3;4",
			"",
			"",
			"207",
			"2;3;5",
			"",
			"",
			"mwrong,d9;9;1;1"
		].join("`"));

		assertEquals(207, level.artBackgroundCode, "art background code");
		assertEquals(5, level.artLayers.length, "art layer count");
		assertEquals(1.0, level.artLayers[0].scale, "bg1 scale");
		assertEquals(0.5, level.artLayers[1].scale, "bg2 scale");
		assertEquals(0.25, level.artLayers[2].scale, "bg3 scale");
		assertEquals(1.0, level.artLayers[3].scale, "bg4 scale");
		assertEquals(2.0, level.artLayers[4].scale, "bg5 scale");
		assertEquals(1, level.artLayers[0].objects.length, "layer 1 object count");
		assertEquals(1, level.artLayers[0].texts.length, "layer 1 text count");
		assertEquals(3, level.artLayers[0].drawActions.length, "layer 1 draw actions");
		assertEquals(2, level.artLayers[4].drawActions.length, "erase draw action is preserved for renderer decision");

		var object = level.artLayers[0].objects[0];
		assertEquals(1, object.code, "art object code");
		assertEquals(10.0, object.x, "art object x");
		assertEquals(20.0, object.y, "art object y");
		assertEquals(1.5, object.scaleX, "art object scale x");
		assertEquals(0.5, object.scaleY, "art object scale y");

		var text = level.artLayers[0].texts[0];
		assertEquals("hello|world", text.text, "text content");
		assertEquals(15.0, text.x, "text x carries relative cursor");
		assertEquals(25.0, text.y, "text y carries relative cursor");
		assertEquals(0xFF0000, text.color, "text color");
		assertEquals(2.0, text.scaleX, "text scale x");
		assertEquals(1.0, text.scaleY, "text scale y");

		var color = level.artLayers[0].drawActions[0];
		assertEquals("c", color.kind, "draw color kind");
		assertEquals(0x123456, Std.int(color.values[0]), "draw color");
		var stroke = level.artLayers[0].drawActions[2];
		assertEquals("d", stroke.kind, "stroke kind");
		assertEquals(4, stroke.values.length, "stroke values");
	}

	private static function testM2SegMultOne():Void {
		var level = LevelDecoder.decode("m2`000000`5;7;4");
		assertEquals(1, level.blocks.length, "m2 block count");
		// segMult 1: coords are not multiplied.
		assertBlock(level.blocks[0], ObjectCodes.BLOCK_BRICK, 5, 7, "m2 unscaled coords");
	}

	private static function testM4Options():Void {
		var level = LevelDecoder.decode("m4`000000`0;0;19;3-4-5,2;0");
		assertEquals(2, level.blocks.length, "m4 block count");
		assertBlock(level.blocks[0], ObjectCodes.BLOCK_MOVE, 0, 0, "m4 move block");
		assertEquals("3-4-5", level.blocks[0].options, "m4 options preserved");
		// Carried code, stepped x by 2 segments.
		assertBlock(level.blocks[1], ObjectCodes.BLOCK_MOVE, 60, 0, "m4 carried code + step");
	}

	private static function testM1HexAbsolute():Void {
		// First block token is the hex base offset; the rest are code;x;y in hex.
		var level = LevelDecoder.decode("m1`ffffff`5;5,2;3;4");
		assertEquals(1, level.blocks.length, "m1 block count");
		// code 0x2 -> 102, x 0x3 + 0x5, y 0x4 + 0x5.
		assertBlock(level.blocks[0], ObjectCodes.BLOCK_BASIC3, 8, 9, "m1 hex + base offset");
	}

	private static function testUnsupportedModeThrows():Void {
		assertions++;
		try {
			LevelDecoder.decode("zz`000000`0;0;0");
		} catch (_:Dynamic) {
			return;
		}
		throw "unsupported read mode should throw";
	}

	private static function assertBlock(block:LevelBlock, code:Int, x:Int, y:Int, message:String):Void {
		assertEquals(code, block.code, message + " code");
		assertEquals(x, block.worldX, message + " x");
		assertEquals(y, block.worldY, message + " y");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
