package pr2.level;

import openfl.display.Sprite;
import pr2.level.ServerLevel.DecodedArtLayer;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.level.ServerLevel.DecodedDrawAction;

class ServerLevelRendererTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testBlockAssetMapping();
		testArtAssetMappings();
		testWorldToScreenFocus();
		testArtLayerDepthAndParallax();
		trace('ServerLevelRendererTest passed $assertions assertions');
	}

	private static function testBlockAssetMapping():Void {
		assertEquals("assets/blocks/basic1.png", ServerLevelRenderer.blockAssetPath(ObjectCodes.BLOCK_BASIC1), "basic1 asset");
		assertEquals("assets/blocks/start.png", ServerLevelRenderer.blockAssetPath(ObjectCodes.BLOCK_START3), "start variants share asset");
		assertEquals("assets/blocks/teleport_block.png", ServerLevelRenderer.blockAssetPath(ObjectCodes.BLOCK_TELEPORT), "teleport asset");
		assertEquals("", ServerLevelRenderer.blockAssetPath(ObjectCodes.BLOCK_ARROW_RIGHT), "arrow block fallback until overlay art is exported");
	}

	private static function testArtAssetMappings():Void {
		assertEquals("assets/backgrounds/bg1@4x.png", ServerLevelRenderer.artBackgroundAssetPath(201), "bg1 asset");
		assertEquals("assets/backgrounds/bg7@4x.png", ServerLevelRenderer.artBackgroundAssetPath(207), "bg7 asset");
		assertEquals("", ServerLevelRenderer.artBackgroundAssetPath(999), "unknown background asset");
		assertEquals("assets/stamps/tree1@4x.png", ServerLevelRenderer.stampAssetPath(0), "tree stamp asset");
		assertEquals("assets/stamps/spire2@4x.png", ServerLevelRenderer.stampAssetPath(8), "spire stamp asset");
		assertEquals("", ServerLevelRenderer.stampAssetPath(4), "unexported cactus stamp skipped");
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

	private static function testArtLayerDepthAndParallax():Void {
		var focus = new DecodedBlock(ObjectCodes.BLOCK_START1, 10020, 10050);
		var layers = [
			new DecodedArtLayer([], [], [], 1),
			new DecodedArtLayer([], [], [], 0.5),
			new DecodedArtLayer([new DecodedDrawAction("d", [0, 0, 1, 1])], [], [], 0.25),
			new DecodedArtLayer([], [], [], 1),
			new DecodedArtLayer([], [], [], 2)
		];
		var level = new ServerLevel(0xFFFFFF, [focus], layers);
		var renderer = new ServerLevelRenderer(level, focus, 180, 280);

		assertEquals("artLayer3", renderer.getChildAt(1).name, "furthest rear layer renders first");
		assertEquals("artLayer2", renderer.getChildAt(2).name, "middle rear layer renders second");
		assertEquals("artLayer1", renderer.getChildAt(3).name, "nearest rear layer renders before blocks");
		assertEquals("artLayer4", renderer.getChildAt(5).name, "first foreground layer renders after blocks");
		assertEquals("artLayer5", renderer.getChildAt(6).name, "nearest foreground layer renders last");

		var rear = Std.downcast(renderer.getChildAt(1), Sprite);
		assertEquals(Math.round((180.0 - 10020) * 0.25), rear.x, "rear layer x applies authored parallax");
		assertEquals(Math.round((280.0 - 10050) * 0.25), rear.y, "rear layer y applies authored parallax");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
