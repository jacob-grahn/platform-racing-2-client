package pr2.level;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import pr2.level.ServerLevel.DecodedArtLayer;
import pr2.level.ServerLevel.DecodedArtObject;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.level.ServerLevel.DecodedDrawAction;
import pr2.level.ServerLevel.DecodedTextObject;

class ServerLevelRendererTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testBlockAssetMapping();
		testArtAssetMappings();
		testWorldToScreenFocus();
		testBlockAlphaUpdate();
		testBlockColorMultiplierUpdate();
		testIncrementalBlockDrawing();
		testIncrementalArtDrawing();
		testArrowAnimation();
		testRemoteVisibleBlockActivation();
		testMineExplosion();
		testBlockPieces();
		testArtLayerDepthAndParallax();
		testRemoveDisposesAnimatedChildren();
		trace('ServerLevelRendererTest passed $assertions assertions');
	}

	private static function testMineExplosion():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_MINE, 10020, 10050);
		var renderer = new ServerLevelRenderer(new ServerLevel(0xFFFFFF, [block]), block);
		var effect = renderer.showMineExplosion(block.x, block.y, false);
		var blockLayer = worldLayer(renderer, 1);
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
		var blockLayer = worldLayer(renderer, 1);
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

		var blockLayer = worldLayer(renderer, 1);
		assertEquals(0.0, blockLayer.getChildAt(0).alpha, "server renderer hides removed brick");
		assertEquals(0.0, blockLayer.getChildAt(1).alpha, "server renderer hides removed mine");
		assertEquals(0.0, blockLayer.getChildAt(2).alpha, "server renderer hides removed crumble");
		assertEquals(0.0, blockLayer.getChildAt(3).alpha, "server renderer hides vanished block");
	}

	private static function testBlockColorMultiplierUpdate():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_ITEM, 10020, 10050);
		var renderer = new ServerLevelRenderer(new ServerLevel(0xFFFFFF, [block]), block);
		renderer.setBlockColorMultiplier(block.x, block.y, 0.5);

		var blockLayer = worldLayer(renderer, 1);
		var transform = blockLayer.getChildAt(0).transform.colorTransform;
		assertEquals(0.5, transform.redMultiplier, "server renderer applies depleted item red multiplier");
		assertEquals(0.5, transform.greenMultiplier, "server renderer applies depleted item green multiplier");
		assertEquals(0.5, transform.blueMultiplier, "server renderer applies depleted item blue multiplier");
	}

	private static function testIncrementalBlockDrawing():Void {
		var blocks = [
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC2, 10050, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC3, 10080, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC4, 10110, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_BRICK, 10140, 10050)
		];
		var renderer = new ServerLevelRenderer(new ServerLevel(0xFFFFFF, blocks), blocks[0], 180, 280, true, 2);
		var blockLayer = worldLayer(renderer, 1);
		assertEquals(0, renderer.drawnBlockCount(), "incremental renderer starts before drawing blocks");
		assertEquals(0, blockLayer.numChildren, "incremental block layer starts empty");
		assertEquals(false, renderer.isBlockDrawingComplete(), "incremental renderer is initially incomplete");

		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(2, renderer.drawnBlockCount(), "incremental renderer draws first frame batch");
		assertEquals(2, blockLayer.numChildren, "first frame adds one batch of blocks");

		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(4, renderer.drawnBlockCount(), "incremental renderer draws second frame batch");
		assertEquals(false, renderer.isBlockDrawingComplete(), "incremental renderer waits for final partial batch");

		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(5, renderer.drawnBlockCount(), "incremental renderer draws final partial batch");
		assertEquals(5, blockLayer.numChildren, "incremental renderer eventually attaches every block");
		assertEquals(true, renderer.isBlockDrawingComplete(), "incremental renderer reports completion");
	}

	private static function testIncrementalArtDrawing():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050);
		var art = new DecodedArtLayer([
			new DecodedDrawAction("c", [0xFF0000]),
			new DecodedDrawAction("t", [3]),
			new DecodedDrawAction("d", [0, 0, 10, 10])
		], [new DecodedArtObject(4, 10, 20)], [new DecodedTextObject("hello|world", 15, 25, 0x00FF00)], 1);
		var renderer = new ServerLevelRenderer(new ServerLevel(0xFFFFFF, [block], [art]), block, 180, 280, true, 4);
		var artLayer = worldLayer(renderer, 1);
		assertEquals(0, renderer.drawnArtItemCount(), "incremental art starts before drawing art");
		// Child 0 is the (empty) stroke raster canvas that placed art sits on top of.
		assertEquals(1, artLayer.numChildren, "incremental art layer starts with only the stroke canvas");
		assertEquals(false, renderer.isDrawingComplete(), "renderer waits for incremental art");

		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(4, renderer.drawnArtItemCount(), "first art batch counts strokes and skipped stamps");
		assertEquals(1, artLayer.numChildren, "first art batch has not reached text object");
		assertEquals(false, renderer.isDrawingComplete(), "renderer waits for remaining art item");

		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(5, renderer.drawnArtItemCount(), "second art batch draws final text item");
		assertEquals(2, artLayer.numChildren, "second art batch attaches text object above the stroke canvas");
		assertEquals(true, renderer.isDrawingComplete(), "renderer completes after blocks and art");
		var field = Std.downcast(artLayer.getChildAt(1), TextField);
		assertEquals("hello,world", field.text, "incremental text uses server text parsing");
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

		var blockLayer = worldLayer(renderer, 1);
		var blockDisplay = Std.downcast(blockLayer.getChildAt(0), Sprite);
		var pivot = Std.downcast(blockDisplay.getChildAt(1), Sprite);
		var timeline = pivot.getChildAt(0);
		for (_ in 0...7) {
			timeline.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(1, renderer.arrowFrameAt(arrow.x, arrow.y), "arrow animation returns to its stopped first frame");
		assertEquals(null, renderer.arrowFrameAt(0, 0), "non-arrow coordinate has no animation frame");
	}

	private static function testRemoteVisibleBlockActivation():Void {
		var vanish = new DecodedBlock(ObjectCodes.BLOCK_VANISH, 10020, 10050);
		var water = new DecodedBlock(ObjectCodes.BLOCK_WATER, 10050, 10050);
		var renderer = new ServerLevelRenderer(new ServerLevel(0xFFFFFF, [vanish, water]), vanish);

		renderer.activateVanish(vanish.x, vanish.y);
		assertEquals(0.0, renderer.blockAlphaAt(vanish.x, vanish.y), "remote vanish activation hides block");

		renderer.triggerWaterRipple(water.x, water.y);
		assertClose(0.9, renderer.blockAlphaAt(water.x, water.y), "remote water ripple dims block");
		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(0.93, renderer.blockAlphaAt(water.x, water.y), "remote water ripple recovers each frame");
		for (_ in 0...3) {
			renderer.triggerWaterRipple(water.x, water.y);
		}
		assertClose(0.63, renderer.blockAlphaAt(water.x, water.y), "remote water ripple stacks alpha reduction");
		for (_ in 0...20) {
			renderer.triggerWaterRipple(water.x, water.y);
		}
		assertEquals(0.5, renderer.blockAlphaAt(water.x, water.y), "remote water ripple clamps minimum alpha");
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

		assertEquals("artLayer3", worldLayer(renderer, 1).name, "furthest rear layer renders first");
		assertEquals("artLayer2", worldLayer(renderer, 2).name, "middle rear layer renders second");
		assertEquals("artLayer1", worldLayer(renderer, 3).name, "nearest rear layer renders before blocks");
		assertEquals("artLayer4", worldLayer(renderer, 5).name, "first foreground layer renders after blocks");
		assertEquals("artLayer5", worldLayer(renderer, 6).name, "nearest foreground layer renders last");

		var rear = worldLayer(renderer, 1);
		assertEquals(Math.round((180.0 - 10020) * 0.25), rear.x, "rear layer x applies authored parallax scale");
		assertEquals(Math.round((280.0 - 10050) * 0.25), rear.y, "rear layer y applies authored parallax scale");

		renderer.setCameraOffset(315.4, 172.6);
		assertEquals(Math.round(315.4 * 0.25), rear.x, "rear layer x follows camera at quarter speed");
		assertEquals(Math.round(172.6 * 0.25), rear.y, "rear layer y follows camera at quarter speed");
		var foreground = worldLayer(renderer, 6);
		assertEquals(Math.round(315.4 * 2), foreground.x, "foreground layer x follows camera at double speed");
		assertEquals(Math.round(172.6 * 2), foreground.y, "foreground layer y follows camera at double speed");
	}

	private static function testRemoveDisposesAnimatedChildren():Void {
		var arrow = new DecodedBlock(ObjectCodes.BLOCK_ARROW_RIGHT, 10020, 10050);
		var renderer = new ServerLevelRenderer(new ServerLevel(0xFFFFFF, [arrow]), arrow);
		renderer.animateArrow(arrow.x, arrow.y);
		var blockLayer = worldLayer(renderer, 1);
		var blockDisplay = Std.downcast(blockLayer.getChildAt(0), Sprite);
		var pivot = Std.downcast(blockDisplay.getChildAt(1), Sprite);
		var arrowTimeline = pivot.getChildAt(0);
		var explosion = renderer.showMineExplosion(arrow.x, arrow.y, false);
		var pieces = renderer.showBlockPieces("BrickPieceGraphic", arrow.x, arrow.y, 1, 10, 10, 25, function() return 0.5);
		var piece = pieces[0];

		assertEquals(true, arrowTimeline.hasEventListener(Event.ENTER_FRAME), "active arrow has frame listener before renderer removal");
		assertEquals(true, explosion.hasEventListener(Event.ENTER_FRAME), "active mine explosion has frame listener before renderer removal");
		assertEquals(true, piece.hasEventListener(Event.ENTER_FRAME), "active block piece has frame listener before renderer removal");

		renderer.remove();

		assertEquals(false, arrowTimeline.hasEventListener(Event.ENTER_FRAME), "renderer removal disposes active arrow timeline");
		assertEquals(false, explosion.hasEventListener(Event.ENTER_FRAME), "renderer removal disposes active mine explosion");
		assertEquals(false, piece.hasEventListener(Event.ENTER_FRAME), "renderer removal disposes active block piece");
		assertEquals(null, explosion.parent, "renderer removal detaches active mine explosion");
		assertEquals(null, piece.parent, "renderer removal detaches active block piece");
	}

	// The block and parallax art layers now live inside the renderer's rotating
	// world container (renderer child index 1), so a layer that used to sit at
	// renderer child `index` is now at world-container child `index - 1`. See
	// ServerLevelRenderer.worldContainer, which lets a rotate block spin the
	// whole world about the screen centre without moving the upright backgrounds.
	private static function worldLayer(renderer:ServerLevelRenderer, index:Int):Sprite {
		var world = Std.downcast(renderer.getChildAt(1), Sprite);
		return Std.downcast(world.getChildAt(index - 1), Sprite);
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
