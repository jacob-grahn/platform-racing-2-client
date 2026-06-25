package pr2.level;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.level.ServerLevel.DecodedArtLayer;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.level.ServerLevel.DecodedDrawAction;

class ServerLevelRendererTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testBlockAssetMapping();
		testArtAssetMappings();
		testWorldToScreenFocus();
		testBlockAlphaUpdate();
		testArrowAnimation();
		testMineExplosion();
		testBlockPieces();
		testArtLayerDepthAndParallax();
		trace('ServerLevelRendererTest passed $assertions assertions');
	}

	private static function testMineExplosion():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_MINE, 10020, 10050);
		var renderer = new ServerLevelRenderer(new ServerLevel(0xFFFFFF, [block]), block);
		var effect = renderer.showMineExplosion(block.x, block.y, false);
		var blockLayer = Std.downcast(renderer.getChildAt(1), Sprite);
		assertEquals(block.x, effect.x, "mine explosion uses block world x");
		assertEquals(block.y, effect.y, "mine explosion uses block world y");
		assertEquals(effect, blockLayer.getChildAt(1), "mine explosion renders over the block layer");
		for (_ in 0...14) {
			effect.dispatchEvent(new openfl.events.Event(openfl.events.Event.ENTER_FRAME));
		}
		assertEquals(1, blockLayer.numChildren, "mine explosion removes itself after 14 frames");
	}

	private static function testBlockPieces():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_BRICK, 10020, 10050);
		var renderer = new ServerLevelRenderer(new ServerLevel(0xFFFFFF, [block]), block);
		var pieces = renderer.showBlockPieces("BrickPieceGraphic", block.x, block.y, 1, 10, 10, 25, function() return 0.5);
		var piece = pieces[0];
		var blockLayer = Std.downcast(renderer.getChildAt(1), Sprite);
		assertEquals(block.x + 15, piece.x, "piece starts at randomized position inside block");
		assertEquals(block.y + 15, piece.y, "piece starts at randomized position inside block");
		assertEquals(180.0, piece.rotation, "piece starts with randomized rotation");
		piece.dispatchEvent(new openfl.events.Event(openfl.events.Event.ENTER_FRAME));
		assertEquals(block.y + 15.75, piece.y, "piece applies friction then gravity");
		assertClose(0.95, piece.alpha, "piece fades by Flash rate");
		for (_ in 0...19) {
			piece.dispatchEvent(new openfl.events.Event(openfl.events.Event.ENTER_FRAME));
		}
		assertEquals(1, blockLayer.numChildren, "piece removes itself after 20 frames");
	}

	private static function testBlockAlphaUpdate():Void {
		var blocks = [
			new DecodedBlock(ObjectCodes.BLOCK_BRICK, 10020, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_MINE, 10050, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_CRUMBLE, 10080, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_VANISH, 10110, 10050)
		];
		var renderer = new ServerLevelRenderer(new ServerLevel(0xFFFFFF, blocks), blocks[0]);
		for (block in blocks) {
			renderer.setBlockAlpha(block.x, block.y, 0);
		}

		var blockLayer = Std.downcast(renderer.getChildAt(1), Sprite);
		assertEquals(0.0, blockLayer.getChildAt(0).alpha, "server renderer hides removed brick");
		assertEquals(0.0, blockLayer.getChildAt(1).alpha, "server renderer hides removed mine");
		assertEquals(0.0, blockLayer.getChildAt(2).alpha, "server renderer hides removed crumble");
		assertEquals(0.0, blockLayer.getChildAt(3).alpha, "server renderer hides vanished block");
	}

	private static function testBlockAssetMapping():Void {
		assertEquals("assets/blocks/basic1.png", ServerLevelRenderer.blockAssetPath(ObjectCodes.BLOCK_BASIC1), "basic1 asset");
		assertEquals("assets/blocks/start.png", ServerLevelRenderer.blockAssetPath(ObjectCodes.BLOCK_START3), "start variants share asset");
		assertEquals("assets/blocks/teleport_block.png", ServerLevelRenderer.blockAssetPath(ObjectCodes.BLOCK_TELEPORT), "teleport asset");
		assertEquals("assets/blocks/basic2.png", ServerLevelRenderer.blockAssetPath(ObjectCodes.BLOCK_ARROW_RIGHT), "arrow blocks use the basic2 base tile");
		testArrowOverlay();
	}

	private static function testArrowOverlay():Void {
		assertEquals("assets/blocks/arrow_overlay@4x.png", ServerLevelRenderer.arrowOverlayAssetPath(), "arrow overlay art path");
		assertEquals(0.0, ServerLevelRenderer.arrowOverlayRotation(ObjectCodes.BLOCK_ARROW_UP), "up arrow points up");
		assertEquals(180.0, ServerLevelRenderer.arrowOverlayRotation(ObjectCodes.BLOCK_ARROW_DOWN), "down arrow rotates 180");
		assertEquals(-90.0, ServerLevelRenderer.arrowOverlayRotation(ObjectCodes.BLOCK_ARROW_LEFT), "left arrow rotates -90");
		assertEquals(90.0, ServerLevelRenderer.arrowOverlayRotation(ObjectCodes.BLOCK_ARROW_RIGHT), "right arrow rotates 90");
		assertEquals(null, ServerLevelRenderer.arrowOverlayRotation(ObjectCodes.BLOCK_BASIC2), "non-arrow blocks have no overlay rotation");
	}

	private static function testArrowAnimation():Void {
		var arrow = new DecodedBlock(ObjectCodes.BLOCK_ARROW_RIGHT, 10020, 10050);
		var renderer = new ServerLevelRenderer(new ServerLevel(0xFFFFFF, [arrow]), arrow);
		assertEquals(1, renderer.arrowFrameAt(arrow.x, arrow.y), "arrow timeline starts stopped on frame 1");

		renderer.animateArrow(arrow.x, arrow.y);
		assertEquals(2, renderer.arrowFrameAt(arrow.x, arrow.y), "arrow activation starts one frame brighter");

		var blockLayer = Std.downcast(renderer.getChildAt(1), Sprite);
		var blockDisplay = Std.downcast(blockLayer.getChildAt(0), Sprite);
		var pivot = Std.downcast(blockDisplay.getChildAt(1), Sprite);
		var timeline = pivot.getChildAt(0);
		for (_ in 0...7) {
			timeline.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(1, renderer.arrowFrameAt(arrow.x, arrow.y), "arrow animation returns to its stopped first frame");
		assertEquals(null, renderer.arrowFrameAt(0, 0), "non-arrow coordinate has no animation frame");
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

		renderer.setCameraOffset(100.4, 200.6);
		var moved = renderer.worldToScreen(25, 35);
		assertEquals(125.0, moved.x, "camera rounds map x like Background.setPos");
		assertEquals(236.0, moved.y, "camera rounds map y like Background.setPos");
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
		assertEquals(275 + Math.round((180.0 - 275 - 10020) * 0.25), rear.x, "rear layer x applies authored parallax around stage center");
		assertEquals(200 + Math.round((280.0 - 200 - 10050) * 0.25), rear.y, "rear layer y applies authored parallax around stage center");

		renderer.setCameraOffset(315.4, 172.6);
		assertEquals(275 + Math.round((315.4 - 275) * 0.25), rear.x, "rear layer x follows camera at quarter speed");
		assertEquals(200 + Math.round((172.6 - 200) * 0.25), rear.y, "rear layer y follows camera at quarter speed");
		var foreground = Std.downcast(renderer.getChildAt(6), Sprite);
		assertEquals(275 + Math.round((315.4 - 275) * 2), foreground.x, "foreground layer x follows camera at double speed");
		assertEquals(200 + Math.round((172.6 - 200) * 2), foreground.y, "foreground layer y follows camera at double speed");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.0001) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
