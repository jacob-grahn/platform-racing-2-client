package pr2.level;

import pr2.level.ServerLevel.DecodedBlock;

class ServerLevelRendererTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testBlockAssetMapping();
		testWorldToScreenFocus();
		trace('ServerLevelRendererTest passed $assertions assertions');
	}

	private static function testBlockAssetMapping():Void {
		assertEquals("assets/blocks/basic1.png", ServerLevelRenderer.blockAssetPath(ObjectCodes.BLOCK_BASIC1), "basic1 asset");
		assertEquals("assets/blocks/start.png", ServerLevelRenderer.blockAssetPath(ObjectCodes.BLOCK_START3), "start variants share asset");
		assertEquals("assets/blocks/teleport_block.png", ServerLevelRenderer.blockAssetPath(ObjectCodes.BLOCK_TELEPORT), "teleport asset");
		assertEquals("", ServerLevelRenderer.blockAssetPath(ObjectCodes.BLOCK_ARROW_RIGHT), "arrow block fallback until overlay art is exported");
	}

	private static function testWorldToScreenFocus():Void {
		var focus = new DecodedBlock(ObjectCodes.BLOCK_START1, 10020, 10050);
		var level = new ServerLevel(0xFFFFFF, [focus, new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10050, 10050)]);
		var renderer = new ServerLevelRenderer(level, focus, 180, 280);

		var focused = renderer.worldToScreen(focus.x, focus.y);
		assertEquals(180.0, focused.x, "focus x");
		assertEquals(280.0, focused.y, "focus y");

		var neighbor = renderer.worldToScreen(10050, 10050);
		assertEquals(210.0, neighbor.x, "neighbor x keeps 30px block scale");
		assertEquals(280.0, neighbor.y, "neighbor y");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
