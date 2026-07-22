package pr2.level;

import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import pr2.effects.BlockPiece;
import pr2.lobby.account.Settings;
import pr2.level.Level.LevelArtLayer;
import pr2.level.Level.LevelArtObject;
import pr2.level.Level.LevelDrawAction;
import pr2.level.Level.LevelTextObject;
import pr2.level.Level.LevelBlock;
import pr2.runtime.FontResolver;

class LevelRendererTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testBlockAssetMapping();
		if (pr2.DeterministicTestMode.finishSmokeSuite("LevelRendererTest")) return;
		testArtAssetMappings();
		testPackedArtBackgroundMounts();
		testDefaultArtStrokeThickness();
		testArtEraseStrokeClearsRasterTiles();
		testWorldToScreenFocus();
		testBackgroundColorTransforms();
		testArtObjectAndTextLayerScale();
		testBlockAlphaUpdate();
		testBlockColorMultiplierUpdate();
		testBlockIceOverlayUpdate();
		testTeleportBlockColorBackground();
		testBlockBumpAnimation();
		testMoveBlockDisplay();
		testMoveBlockArrowDisplay();
		testIncrementalBlockDrawing();
		testRuntimeBlockAppendPreservesDrawingCompletion();
		testViewWindowRefreshesBeforeLeftEdgeExposure();
		testIncrementalArtDrawing();
		testArtRasterTilesCullToViewWindow();
		testIncrementalArtFailureCompletesAndWarns();
		testRasterTileLimitStopsAndWarns();
		testArtBatchLimitsRejectHugeSpans();
		testDrawArtSettingSkipsGameplayArt();
		testBg5CircleGrid();
		testArrowAnimation();
		testSpawnMarkerBlocksNotRendered();
		testRemoteVisibleBlockActivation();
		testMineExplosion();
		testBlockPieces();
		testArtLayerDepthAndParallax();
		testRemoveDisposesAnimatedChildren();
		trace('LevelRendererTest passed $assertions assertions');
	}

	private static function testMineExplosion():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_MINE, 10020, 10050);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block]), block);
		var effect = renderer.showMineExplosion(block.worldX, block.worldY, false);
		var blockLayer = worldLayer(renderer, 1);
		assertEquals(block.worldX, effect.x, "mine explosion uses block world x");
		assertEquals(block.worldY, effect.y, "mine explosion uses block world y");
		assertEquals(effect, blockLayer.getChildAt(1), "mine explosion renders over the block layer");
		for (_ in 0...100) {
			effect.animation.dispatchEvent(new openfl.events.Event(openfl.events.Event.ENTER_FRAME));
		}
		assertEquals(14, effect.animation.currentFrame, "mine explosion animation stops on authored frame 14");
		for (_ in 0...14) {
			effect.dispatchEvent(new openfl.events.Event(openfl.events.Event.ENTER_FRAME));
		}
		assertEquals(1, blockLayer.numChildren, "mine explosion removes itself after 14 frames");
	}

	private static function testBlockPieces():Void {
		var defaultPiece = new BlockPiece("BrickPieceGraphic", BlockPiece.GRAVITY, BlockPiece.FRICTION, BlockPiece.FADE_RATE, 10, 10, 25, 5,
			7, function() return 0.5);
		defaultPiece.dispatchEvent(new openfl.events.Event(openfl.events.Event.ENTER_FRAME));
		assertEquals(8.0, defaultPiece.y, "default block piece gravity matches Flash constructor");
		assertClose(0.99, defaultPiece.alpha, "default block piece fade rate matches Flash constructor");
		defaultPiece.remove();

		var block = new DecodedBlock(ObjectCodes.BLOCK_BRICK, 10020, 10050);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block]), block);
		var pieces = renderer.showBlockPieces("BrickPieceGraphic", block.worldX, block.worldY, 1, 10, 10, 25, 0.75, 0.95, 0.05,
			function() return 0.5);
		var piece = pieces[0];
		var blockLayer = worldLayer(renderer, 1);
		assertEquals(block.worldX + 15, piece.x, "piece starts at randomized position inside block");
		assertEquals(block.worldY + 15, piece.y, "piece starts at randomized position inside block");
		assertEquals(180.0, piece.rotation, "piece starts with randomized rotation");
		assertEquals(3, piece.selectedFrame, "brick fragment chooses a random native authored frame");
		piece.dispatchEvent(new openfl.events.Event(openfl.events.Event.ENTER_FRAME));
		assertEquals(block.worldY + 15.75, piece.y, "piece applies friction then gravity");
		assertEquals(3, piece.selectedFrame, "brick fragment frame does not auto-play after construction");
		assertClose(0.95, piece.alpha, "piece fades by Flash rate");
		var minePieces = renderer.showBlockPieces("MinePieceGraphic", block.worldX, block.worldY, 1, 10, 10, 25, 0.75, 0.95, 0.05,
			function() return 0.5);
		var minePiece = minePieces[0];
		assertEquals(4, minePiece.selectedFrame, "mine fragment chooses and stops on a random authored frame");
		minePiece.dispatchEvent(new openfl.events.Event(openfl.events.Event.ENTER_FRAME));
		assertEquals(4, minePiece.selectedFrame, "mine fragment frame does not auto-play after construction");
		minePiece.remove();
		var basic = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10110, 10050);
		var basicRenderer = new LevelRenderer(new TestLevel(0xFFFFFF, [basic]), basic);
		var sliced = basicRenderer.showBasicBlockPieces(basic.worldX, basic.worldY, 6, 10, 10, 25, function() return 0.5);
		assertEquals(6, sliced.length, "basic Snake dig creates the six brick-style fragments");
		var firstSlice = Std.downcast(sliced[0].visual, openfl.display.Bitmap);
		assertTrue(firstSlice != null, "basic Snake fragment is a bitmap crop rather than authored brick art");
		assertEquals(10.0, firstSlice.width, "basic Snake fragment is one third of a block wide");
		assertEquals(15.0, firstSlice.height, "basic Snake fragment is one half of a block tall");
		for (slice in sliced) slice.remove();
		for (_ in 0...19) {
			piece.dispatchEvent(new openfl.events.Event(openfl.events.Event.ENTER_FRAME));
		}
		assertEquals(1, blockLayer.numChildren, "piece removes itself after 20 frames");
		assertEquals(false, piece.hasEventListener(openfl.events.Event.ENTER_FRAME), "expired piece clears its frame listener");
		assertEquals(null, piece.parent, "expired piece is detached from the effect layer");
		assertEquals(null, piece.visual, "expired piece releases its authored visual");
	}

	private static function testBlockAlphaUpdate():Void {
		var blocks = [
			new DecodedBlock(ObjectCodes.BLOCK_BRICK, 10020, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_MINE, 10050, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_CRUMBLE, 10080, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_VANISH, 10110, 10050)
		];
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, blocks), blocks[0]);
		for (block in blocks) {
			renderer.setBlockAlpha(block.worldX, block.worldY, 0);
		}

		var blockLayer = worldLayer(renderer, 1);
		assertEquals(0.0, blockLayer.getChildAt(0).alpha, "level renderer hides removed brick");
		assertEquals(0.0, blockLayer.getChildAt(1).alpha, "level renderer hides removed mine");
		assertEquals(0.0, blockLayer.getChildAt(2).alpha, "level renderer hides removed crumble");
		assertEquals(0.0, blockLayer.getChildAt(3).alpha, "level renderer hides vanished block");
	}

	private static function testBlockColorMultiplierUpdate():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_ITEM, 10020, 10050);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block]), block);
		renderer.setBlockColorMultiplier(block.worldX, block.worldY, 0.5);

		var blockLayer = worldLayer(renderer, 1);
		var transform = blockLayer.getChildAt(0).transform.colorTransform;
		assertEquals(0.5, transform.redMultiplier, "level renderer applies depleted item red multiplier");
		assertEquals(0.5, transform.greenMultiplier, "level renderer applies depleted item green multiplier");
		assertEquals(0.5, transform.blueMultiplier, "level renderer applies depleted item blue multiplier");
	}

	private static function testBlockIceOverlayUpdate():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block]), block);

		renderer.setBlockIceOverlayAlpha(block.worldX, block.worldY, 0.75);
		assertEquals(0.75, renderer.blockIceOverlayAlphaAt(block.worldX, block.worldY), "level renderer adds ice overlay alpha");

		var blockLayer = worldLayer(renderer, 1);
		var blockDisplay = Std.downcast(blockLayer.getChildAt(0), Sprite);
		assertEquals(2, blockDisplay.numChildren, "ice overlay is a child above the base block");

		renderer.setBlockIceOverlayAlpha(block.worldX, block.worldY, 0);
		assertEquals(0.0, renderer.blockIceOverlayAlphaAt(block.worldX, block.worldY), "level renderer removes ice overlay at zero alpha");
		assertEquals(1, blockDisplay.numChildren, "ice overlay child is removed after thaw");
	}

	private static function testBlockBumpAnimation():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block]), block);
		var blockLayer = worldLayer(renderer, 1);
		var display = blockLayer.getChildAt(0);

		renderer.animateBlockBump(block.worldX, block.worldY);
		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));

		assertEquals(block.worldX, display.x, "block bump from below keeps x aligned");
		assertClose(block.worldY - 4.875, display.y, "block bump uses Flash bounce decay on first frame");
		for (_ in 0...100) {
			renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertWithin(block.worldX, display.x, 0.01, "block bump visually returns to original x");
		assertWithin(block.worldY, display.y, 0.01, "block bump visually returns to original y");
		assertEquals(true, renderer.blockIsBouncingAt(block.worldX, block.worldY), "Flash off-diagonal bounce quirk keeps listener active");

		renderer.animateBlockBump(block.worldX, block.worldY, 5, 0);
		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));

		assertClose(block.worldX + 1.625, display.x, "block side bump uses horizontal Flash bounce decay on first frame");
		assertClose(block.worldY, display.y, "block side bump keeps y aligned");
		for (_ in 0...20) {
			renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertWithin(block.worldX, display.x, 0.01, "block side bump visually returns to original x");
		assertWithin(block.worldY, display.y, 0.01, "block side bump visually returns to original y");
		assertEquals(true, renderer.blockIsBouncingAt(block.worldX, block.worldY), "Flash side-bump quirk also keeps listener active off diagonal");

		var diagonal = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10020);
		var diagonalRenderer = new LevelRenderer(new TestLevel(0xFFFFFF, [diagonal]), diagonal);
		diagonalRenderer.animateBlockBump(diagonal.worldX, diagonal.worldY);
		for (_ in 0...21) {
			diagonalRenderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(false, diagonalRenderer.blockIsBouncingAt(diagonal.worldX, diagonal.worldY), "diagonal block still clears under Flash stop condition");
	}

	private static function testMoveBlockDisplay():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_MOVE, 10020, 10050);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block]), block);

		renderer.moveBlockDisplay(10020, 10050, 10050, 10050);

		var blockLayer = worldLayer(renderer, 1);
		var display = blockLayer.getChildAt(0);
		assertEquals(10050.0, display.x, "move block display shifts to new world x");
		assertEquals(10050.0, display.y, "move block display keeps new world y");
		assertEquals(null, renderer.blockAlphaAt(10020, 10050), "old move block coordinate is no longer keyed");
		assertEquals(1.0, renderer.blockAlphaAt(10050, 10050), "new move block coordinate is keyed");
	}

	private static function testMoveBlockArrowDisplay():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_MOVE, 10020, 10050);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block]), block);
		var blockLayer = worldLayer(renderer, 1);
		var display = cast(blockLayer.getChildAt(0), Sprite);

		renderer.showMoveBlockArrow(10020, 10050, 2);
		assertEquals(2, display.numChildren, "move block arrow is added over the tile");
		assertEquals(90.0, renderer.moveBlockArrowRotationAt(10020, 10050), "right move arrow matches Flash rotation");

		renderer.moveBlockDisplay(10020, 10050, 10050, 10050);
		assertEquals(null, renderer.moveBlockArrowRotationAt(10020, 10050), "move arrow leaves old coordinate");
		assertEquals(90.0, renderer.moveBlockArrowRotationAt(10050, 10050), "move arrow follows shifted block display");

		renderer.hideMoveBlockArrow(10050, 10050);
		assertEquals(1, display.numChildren, "move block arrow is removed from the tile");
		assertEquals(null, renderer.moveBlockArrowRotationAt(10050, 10050), "move arrow key is cleared");
	}

	private static function testIncrementalBlockDrawing():Void {
		var blocks = [
			new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC2, 10050, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC3, 10080, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_BASIC4, 10110, 10050),
			new DecodedBlock(ObjectCodes.BLOCK_BRICK, 10140, 10050)
		];
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, blocks), blocks[0], 180, 280, true, 2);
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

	private static function testRuntimeBlockAppendPreservesDrawingCompletion():Void {
		// Flash records start blocks as spawn markers without occupying Map.blockArray.
		// Runtime blocks are therefore allowed to occupy the marker's exact tile.
		var start = new DecodedBlock(ObjectCodes.BLOCK_START1, 10020, 10050);
		var level = new TestLevel(0xFFFFFF, [start]);
		var renderer = new LevelRenderer(level, start);
		var mine = new DecodedBlock(ObjectCodes.BLOCK_MINE, start.worldX, start.worldY);

		assertEquals(true, renderer.isDrawingComplete(), "renderer completes before a runtime mine is appended");
		level.blocks.push(mine);
		renderer.ensureRuntimeBlockDisplay(mine);

		assertEquals(2, renderer.drawnBlockCount(), "runtime mine advances the completed decode cursor");
		assertEquals(true, renderer.isDrawingComplete(), "runtime mine does not reopen the loading/free-camera state");
		assertEquals(1.0, renderer.blockAlphaAt(mine.worldX, mine.worldY), "runtime mine mounts over the non-occupying start marker");
	}

	private static function testViewWindowRefreshesBeforeLeftEdgeExposure():Void {
		var focus = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050);
		var leftEdge = new DecodedBlock(ObjectCodes.BLOCK_BASIC2, 9750, 10050);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [focus, leftEdge]), focus, 180, 280);
		var blockLayer = worldLayer(renderer, 1);
		assertEquals(1, blockLayer.numChildren, "block just beyond the left view margin starts detached");

		renderer.setCameraOffset(-9750, 280 - 10050);

		assertEquals(2, blockLayer.numChildren, "leftward scroll attaches blocks before they reach the stage edge");
		assertEquals(0.0, renderer.worldToScreen(leftEdge.worldX, leftEdge.worldY).x, "regression block is exactly on the left edge");
	}

	private static function testIncrementalArtDrawing():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050);
		var art = new LevelArtLayer([
			new LevelDrawAction("c", [0xFF0000]),
			new LevelDrawAction("t", [3]),
			new LevelDrawAction("d", [10020, 10050, 10, 10])
		], [new LevelArtObject(4, 10, 20)], [new LevelTextObject("hello#44world", 15, 25, 0x00FF00)], 1);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block], [art]), block, 180, 280, true, 3);
		var artLayer = worldLayer(renderer, 1);
		assertEquals(0, renderer.drawnArtItemCount(), "incremental art starts before drawing art");
		// Child 0 is the (empty) stroke raster canvas that placed art sits on top of.
		assertEquals(1, artLayer.numChildren, "incremental art layer starts with only the stroke canvas");
		assertEquals(0, strokeRaster(artLayer).numChildren, "incremental art starts with no rasterized stroke tiles");
		assertEquals(false, renderer.isDrawingComplete(), "renderer waits for incremental art");

		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(3, renderer.drawnArtItemCount(), "first art batch counts the initial stroke commands");
		assertEquals(1, artLayer.numChildren, "first art batch has not reached text object");
		assertTrue(strokeRaster(artLayer).numChildren > 0, "first art batch refreshes one visible stroke tile");
		assertEquals(false, renderer.isDrawingComplete(), "renderer waits for remaining art item");

		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(5, renderer.drawnArtItemCount(), "second art batch draws final text item");
		assertEquals(3, artLayer.numChildren, "second art batch attaches object and text above the stroke canvas");
		assertTrue(strokeRaster(artLayer).numChildren > 0, "completed art rendering attaches visible stroke tiles");
		assertEquals(true, renderer.isDrawingComplete(), "renderer completes after blocks and art");
		assertEquals("Cactus", artLayer.getChildAt(1).name, "incremental art uses Objects factory for stamps");
		var field = Std.downcast(artLayer.getChildAt(2), TextField);
		assertEquals(FontResolver.resolve("Verdana"), field.defaultTextFormat.font, "level preview text uses authored Verdana font");
		assertClose(18, field.defaultTextFormat.size, "level preview text uses authored 18px font size");
		assertEquals("hello,world", field.text, "incremental text uses server text parsing");
	}

	private static function testArtRasterTilesCullToViewWindow():Void {
		var focus = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050);
		var tile = LevelRenderer.ART_RASTER_TILE_SIZE;
		var farX = focus.worldX + tile * 6;
		var nearTileX = Std.int(Math.floor(focus.worldX / tile)) * tile;
		var farTileX = Std.int(Math.floor(farX / tile)) * tile;
		var art = new LevelArtLayer([
			new LevelDrawAction("d", [focus.worldX, focus.worldY]),
			new LevelDrawAction("d", [farX, focus.worldY])
		], [], [], 1);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [focus], [art]), focus, 180, 280);
		var raster = strokeRaster(worldLayer(renderer, 1));

		assertEquals(1, raster.numChildren, "art raster culling starts with only visible tiles attached");
		var visible = Std.downcast(raster.getChildAt(0), Bitmap);
		assertEquals(nearTileX, Std.int(visible.x), "initial art raster tile is the focused tile");

		renderer.setCameraOffset(180 - farX, 280 - focus.worldY);
		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));

		assertEquals(1, raster.numChildren, "art raster culling keeps off-screen tiles detached after scroll");
		visible = Std.downcast(raster.getChildAt(0), Bitmap);
		assertEquals(farTileX, Std.int(visible.x), "scrolling attaches the newly visible raster tile");
	}

	private static function testIncrementalArtFailureCompletesAndWarns():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050);
		var art = new LevelArtLayer([
			new LevelDrawAction("d", [0, 0]),
			new LevelDrawAction("d", [10, 10])
		], [], [new LevelTextObject("after", 15, 25, 0x00FF00)], 1);
		var warnings:Array<String> = [];
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block], [art]), block, 180, 280, true, 1, {
			onArtWarning: function(message:String):Void warnings.push(message),
			artDrawFaultInjector: function(index:Int):Void {
				if (index == 0) {
					throw "forced art failure";
				}
			}
		});
		assertEquals(false, renderer.isDrawingComplete(), "renderer waits for art before injected failure");

		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));

		assertEquals(true, renderer.isDrawingComplete(), "art failure marks incremental drawing complete");
		assertEquals(3, renderer.drawnArtItemCount(), "art failure advances draw count to the layer total");
		assertEquals(1, warnings.length, "art failure warns once");
		assertTrue(warnings[0].indexOf("Some art didn't load correctly") >= 0, "art failure warning matches Flash copy");
		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, warnings.length, "completed art failure does not warn again");
	}

	private static function testRasterTileLimitStopsAndWarns():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050);
		var tile = LevelRenderer.ART_RASTER_TILE_SIZE;
		var art = new LevelArtLayer([
			new LevelDrawAction("d", [block.worldX, block.worldY]),
			new LevelDrawAction("d", [block.worldX + tile + 20, block.worldY])
		], [], [], 1);
		var warnings:Array<String> = [];
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block], [art]), block, 180, 280, false,
			LevelRenderer.DEFAULT_BLOCKS_PER_FRAME, {
				onArtWarning: function(message:String):Void warnings.push(message),
				rasterTileLimit: 1
			});
		var artLayer = worldLayer(renderer, 1);

		assertEquals(true, renderer.stoppedRasterizing, "raster tile budget sets stoppedRasterizing");
		assertEquals(1, warnings.length, "raster stop warning emits once");
		assertTrue(warnings[0].indexOf("lossless art quality") >= 0, "raster stop warning uses Flash lossless-quality hint");
		assertEquals(1, strokeRaster(artLayer).numChildren, "raster tile budget stops creating new tiles after the limit");
		assertEquals(true, renderer.isDrawingComplete(), "raster stop does not leave renderer stuck drawing");
	}

	private static function testArtBatchLimitsRejectHugeSpans():Void {
		assertEquals(true, LevelRenderer.isArtDrawBatchWithinLimits(
			LevelRenderer.ART_DRAW_BATCH_MAX_TILE_COUNT,
			LevelRenderer.ART_DRAW_BATCH_MAX_TILE_SPAN,
			LevelRenderer.ART_DRAW_BATCH_MAX_TILE_SPAN
		), "art batch accepts the configured maximum");
		assertEquals(false, LevelRenderer.isArtDrawBatchWithinLimits(
			LevelRenderer.ART_DRAW_BATCH_MAX_TILE_COUNT + 1,
			1,
			1
		), "art batch rejects too many touched tiles");
		assertEquals(false, LevelRenderer.isArtDrawBatchWithinLimits(
			2,
			LevelRenderer.ART_DRAW_BATCH_MAX_TILE_SPAN + 1,
			1
		), "art batch rejects far-apart horizontal strokes");
		assertEquals(false, LevelRenderer.isArtDrawBatchWithinLimits(
			2,
			1,
			LevelRenderer.ART_DRAW_BATCH_MAX_TILE_SPAN + 1
		), "art batch rejects far-apart vertical strokes");
	}

	private static function testDrawArtSettingSkipsGameplayArt():Void {
		Settings.disablePersistenceForTests();
		Settings.setValue(Settings.DRAW_ART, false);
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050);
		var art = new LevelArtLayer([new LevelDrawAction("d", [10, 10])], [], [new LevelTextObject("hidden", 15, 25, 0x00FF00)], 1);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block], [art], 201), block);
		var world = Std.downcast(renderer.getChildAt(1), Sprite);

		assertEquals(2, renderer.numChildren, "drawArt=false keeps only solid background and world container");
		assertEquals(1, world.numChildren, "drawArt=false skips drawable art layers");
		assertEquals(null, renderer.getChildByName("bg5CircleGrid"), "drawArt=false skips art background extras");
		assertEquals(true, renderer.isDrawingComplete(), "drawArt=false leaves renderer drawing complete");
		renderer.remove();
		Settings.setValue(Settings.DRAW_ART, true);
	}

	private static function testBg5CircleGrid():Void {
		var grid = LevelRenderer.createBg5CircleGrid(function() return 0.25);
		assertEquals(88, grid.numChildren, "BG5 grid creates Flash's 11 by 8 colored circles");
		assertEquals(false, grid.mouseEnabled, "BG5 grid ignores direct mouse input");
		assertEquals(false, grid.mouseChildren, "BG5 grid ignores child mouse input");
		assertClose(20, grid.getChildAt(0).x, "first BG5 circle x");
		assertClose(20, grid.getChildAt(0).y, "first BG5 circle y");
		assertClose(520, grid.getChildAt(grid.numChildren - 1).x, "last BG5 circle x");
		assertClose(370, grid.getChildAt(grid.numChildren - 1).y, "last BG5 circle y");

		Settings.disablePersistenceForTests();
		Settings.setValue(Settings.DRAW_ART, true);
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block], [], LevelRenderer.BG5_CODE), block);
		var mounted = Std.downcast(findChildByName(renderer, "bg5CircleGrid"), Sprite);
		assertTrue(mounted != null, "BG5 renderer mounts colored circle grid over the art background");
		assertEquals(88, mounted.numChildren, "mounted BG5 grid preserves Flash circle count");
		renderer.remove();
	}

	private static function testBlockAssetMapping():Void {
		assertEquals("assets/blocks/basic1.png", LevelRenderer.blockAssetPath(ObjectCodes.BLOCK_BASIC1), "basic1 asset");
		assertEquals("assets/blocks/start.png", LevelRenderer.blockAssetPath(ObjectCodes.BLOCK_START3), "start variants share asset");
		assertEquals("assets/blocks/teleport_block.png", LevelRenderer.blockAssetPath(ObjectCodes.BLOCK_TELEPORT), "teleport asset");
		assertEquals("assets/blocks/basic2.png", LevelRenderer.blockAssetPath(ObjectCodes.BLOCK_ARROW_RIGHT), "arrow blocks use the basic2 base tile");
		testArrowOverlay();
	}

	private static function testTeleportBlockColorBackground():Void {
		@:privateAccess assertEquals(0xFF7F50, LevelRenderer.teleportBlockColor(""), "empty teleport options use default color");
		@:privateAccess assertEquals(0xFF7F50, LevelRenderer.teleportBlockColor("16744272"), "explicit default teleport color matches empty options");
		@:privateAccess assertEquals(0x123456, LevelRenderer.teleportBlockColor("1193046"), "custom teleport options parse as decimal color");

		var block = new DecodedBlock(ObjectCodes.BLOCK_TELEPORT, 10020, 10050, "1193046");
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block]), block);
		var blockLayer = worldLayer(renderer, 1);
		var blockDisplay = Std.downcast(blockLayer.getChildAt(0), Sprite);
		assertEquals(2, blockDisplay.numChildren, "teleport block renders option-color background behind bitmap");
		assertTrue(Std.isOfType(blockDisplay.getChildAt(0), Shape), "teleport background is the bottom child");
	}

	private static function testArrowOverlay():Void {
		assertEquals("assets/svg/blocks/arrow_overlay.svg", LevelRenderer.arrowOverlayAssetPath(), "arrow overlay art path");
		assertEquals(0.0, LevelRenderer.arrowOverlayRotation(ObjectCodes.BLOCK_ARROW_UP), "up arrow points up");
		assertEquals(180.0, LevelRenderer.arrowOverlayRotation(ObjectCodes.BLOCK_ARROW_DOWN), "down arrow rotates 180");
		assertEquals(-90.0, LevelRenderer.arrowOverlayRotation(ObjectCodes.BLOCK_ARROW_LEFT), "left arrow rotates -90");
		assertEquals(90.0, LevelRenderer.arrowOverlayRotation(ObjectCodes.BLOCK_ARROW_RIGHT), "right arrow rotates 90");
		assertEquals(null, LevelRenderer.arrowOverlayRotation(ObjectCodes.BLOCK_BASIC2), "non-arrow blocks have no overlay rotation");
	}

	private static function testArrowAnimation():Void {
		var authored = new ArrowBlockView();
		var authoredLayer = Std.downcast(authored.getChildAt(0), Sprite);
		var authoredArt = authoredLayer.getChildAt(0);
		var authoredBounds = authored.getBounds(authored);
		assertWithin(0.4915222168, authoredBounds.x + authoredBounds.width / 2, 0.01, "arrow preserves XFL registration x");
		assertWithin(0, authoredBounds.y + authoredBounds.height / 2, 0.05, "arrow preserves centered XFL registration y");
		// OpenFL expands SVG strokes after the instance transform, so the 3px XFL
		// outline remains 3px around the scaled 15x22 fill.
		assertTrue(authoredBounds.width > 17 && authoredBounds.width < 19, "arrow preserves authored visible width");
		assertTrue(authoredBounds.height > 24 && authoredBounds.height < 26, "arrow preserves authored visible height");
		var multipliers = [1.0, 0.671875, 0.328125, 0.0, 0.25, 0.5, 0.75, 1.0];
		var offsets = [0.0, 85.0, 170.0, 255.0, 191.0, 128.0, 64.0, 0.0];
		for (frame in 1...9) {
			authored.animateFromFrame(frame);
			authored.stop();
			var color = authoredArt.transform.colorTransform;
			var index = frame - 1;
			assertEquals(multipliers[index], color.redMultiplier, 'arrow frame $frame red multiplier follows XFL');
			assertEquals(multipliers[index], color.greenMultiplier, 'arrow frame $frame green multiplier follows XFL');
			assertEquals(multipliers[index], color.blueMultiplier, 'arrow frame $frame blue multiplier follows XFL');
			assertEquals(offsets[index], color.redOffset, 'arrow frame $frame red offset follows XFL');
			assertEquals(offsets[index], color.greenOffset, 'arrow frame $frame green offset follows XFL');
			assertEquals(0.0, color.blueOffset, 'arrow frame $frame blue offset follows XFL');
		}
		authored.dispose();

		var arrow = new DecodedBlock(ObjectCodes.BLOCK_ARROW_RIGHT, 10020, 10050);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [arrow]), arrow);
		assertEquals(1, renderer.arrowFrameAt(arrow.worldX, arrow.worldY), "arrow timeline starts stopped on frame 1");

		var blockLayer = worldLayer(renderer, 1);
		var blockDisplay = Std.downcast(blockLayer.getChildAt(0), Sprite);
		var pivot = Std.downcast(blockDisplay.getChildAt(1), Sprite);
		var timeline = pivot.getChildAt(0);
		// Capture the chevron's full sub-tree at rest so we can prove the animation
		// does not empty it. Counting direct children alone missed the regression
		// where the frame-1 clip stayed attached but its inner chevron was disposed.
		var restDepth = deepChildCount(timeline);
		assertTrue(restDepth > 1, "arrow chevron has inner content at rest");

		renderer.animateArrow(arrow.worldX, arrow.worldY);
		assertEquals(2, renderer.arrowFrameAt(arrow.worldX, arrow.worldY), "arrow activation starts one frame brighter");

		for (_ in 0...4) {
			timeline.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(6, renderer.arrowFrameAt(arrow.worldX, arrow.worldY), "arrow timeline reaches the fading half");
		renderer.animateArrow(arrow.worldX, arrow.worldY);
		assertEquals(5, renderer.arrowFrameAt(arrow.worldX, arrow.worldY), "repeat activation steps a fading arrow back toward its bright center");

		for (_ in 0...4) {
			timeline.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(1, renderer.arrowFrameAt(arrow.worldX, arrow.worldY), "arrow overlay returns to its stopped first frame");
		assertEquals(2, blockDisplay.numChildren, "arrow block keeps its overlay after activation");
		assertEquals(restDepth, deepChildCount(timeline), "arrow chevron keeps its inner content after animating and settling");
		assertEquals(null, renderer.arrowFrameAt(0, 0), "non-arrow coordinate has no animation frame");
	}

	private static function testSpawnMarkerBlocksNotRendered():Void {
		// Flash's gameplay Map records start-block positions but never displays
		// them. Minion-egg blocks are similar spawn markers for runtime Egg effects;
		// only the brick should reach the block layer.
		var start = new DecodedBlock(ObjectCodes.BLOCK_START1, 10020, 10050);
		var minionEgg = new DecodedBlock(ObjectCodes.BLOCK_MINION_EGG, 10080, 10050);
		var brick = new DecodedBlock(ObjectCodes.BLOCK_BRICK, 10050, 10050);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [start, brick, minionEgg]), start);
		var blockLayer = worldLayer(renderer, 1);
		assertEquals(1, blockLayer.numChildren, "spawn marker blocks must not render during a race");
		assertEquals(brick.worldX, Std.downcast(blockLayer.getChildAt(0), Sprite).x, "the only rendered block is the brick, not the start marker");
		assertTrue(LevelRenderer.isStartBlockCode(ObjectCodes.BLOCK_START4), "start variants are start-block codes");
		assertTrue(!LevelRenderer.isStartBlockCode(ObjectCodes.BLOCK_BRICK), "non-start codes are not start blocks");
		assertTrue(LevelRenderer.isSpawnMarkerBlockCode(ObjectCodes.BLOCK_MINION_EGG), "minion egg block is a spawn marker");
	}

	private static function testRemoteVisibleBlockActivation():Void {
		var vanish = new DecodedBlock(ObjectCodes.BLOCK_VANISH, 10020, 10050);
		var water = new DecodedBlock(ObjectCodes.BLOCK_WATER, 10050, 10050);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [vanish, water]), vanish);

		renderer.activateVanish(vanish.worldX, vanish.worldY);
		assertEquals(0.0, renderer.blockAlphaAt(vanish.worldX, vanish.worldY), "remote vanish activation hides block");

		renderer.triggerWaterRipple(water.worldX, water.worldY);
		assertClose(0.9, renderer.blockAlphaAt(water.worldX, water.worldY), "remote water ripple dims block");
		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(0.93, renderer.blockAlphaAt(water.worldX, water.worldY), "remote water ripple recovers each frame");
		for (_ in 0...3) {
			renderer.triggerWaterRipple(water.worldX, water.worldY);
		}
		assertClose(0.63, renderer.blockAlphaAt(water.worldX, water.worldY), "remote water ripple stacks alpha reduction");
		for (_ in 0...20) {
			renderer.triggerWaterRipple(water.worldX, water.worldY);
		}
		assertEquals(0.5, renderer.blockAlphaAt(water.worldX, water.worldY), "remote water ripple clamps minimum alpha");
	}

	private static function testArtAssetMappings():Void {
		assertEquals("assets/svg/backgrounds/bg1.svg", LevelRenderer.artBackgroundAssetPath(201), "bg1 asset");
		assertEquals("assets/svg/backgrounds/bg7.svg", LevelRenderer.artBackgroundAssetPath(207), "bg7 asset");
		assertEquals("", LevelRenderer.artBackgroundAssetPath(999), "unknown background asset");
		assertEquals("assets/svg/stamps/tree1.svg", LevelRenderer.stampAssetPath(0), "tree stamp asset");
		assertEquals("assets/svg/stamps/spire2.svg", LevelRenderer.stampAssetPath(8), "spire stamp asset");
		assertEquals("assets/svg/stamps/cactus.svg", LevelRenderer.stampAssetPath(4), "composed cactus stamp asset");
		assertEquals("assets/svg/stamps/building1.svg", LevelRenderer.stampAssetPath(9), "composed building stamp asset");
	}

	private static function testPackedArtBackgroundMounts():Void {
		Settings.disablePersistenceForTests();
		Settings.setValue(Settings.DRAW_ART, true);
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block], [], 201), block);
		var background = @:privateAccess renderer.artBackgroundContainer;

		assertTrue(background != null, "art background creates its stage container");
		assertEquals(1, background.numChildren, "packed BG1 SVG mounts through SvgAsset");
		renderer.remove();
	}

	private static function testDefaultArtStrokeThickness():Void {
		var brush = new Sprite();
		LevelRenderer.drawLayerStrokes(brush, [new LevelDrawAction("d", [20, 20, 20, 0])]);
		var bounds = brush.getBounds(brush);
		assertEquals(4.0, LevelRenderer.DEFAULT_ART_BRUSH_SIZE, "server art uses Flash's default brush size");
		assertClose(4.0, bounds.height, "server art default stroke bounds match Flash brush thickness");
	}

	private static function testArtEraseStrokeClearsRasterTiles():Void {
		var raster = new Sprite();
		LevelRenderer.renderLayerStrokes(raster, [
			new LevelDrawAction("c", [0xFF0000]),
			new LevelDrawAction("t", [10]),
			new LevelDrawAction("d", [10, 10, 80, 0]),
			new LevelDrawAction("m", [], "erase"),
			new LevelDrawAction("t", [12]),
			new LevelDrawAction("d", [50, 10, 20, 0]),
			new LevelDrawAction("m", [], "draw"),
			new LevelDrawAction("c", [0x0000FF]),
			new LevelDrawAction("d", [75, 10, 10, 0])
		]);

		var tile = Std.downcast(raster.getChildAt(0), Bitmap).bitmapData;
		assertEquals(1, raster.numChildren, "mixed draw/erase strokes create one raster tile");
		assertEquals(LevelRenderer.ART_RASTER_TILE_SIZE + 1, tile.width, "raster tile keeps overlap width");
		assertEquals(LevelRenderer.ART_RASTER_TILE_SIZE + 1, tile.height, "raster tile keeps overlap height");
	}

	private static function testWorldToScreenFocus():Void {
		var focus = new DecodedBlock(ObjectCodes.BLOCK_START1, 10020, 10050);
		var level = new TestLevel(0xFFFFFF, [focus, new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10050, 10050)]);
		var renderer = new LevelRenderer(level, focus, 180, 280);

		var focused = renderer.worldToScreen(focus.worldX, focus.worldY);
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

	private static function testBackgroundColorTransforms():Void {
		var focus = new DecodedBlock(ObjectCodes.BLOCK_START1, 10020, 10050);
		var layers = [
			new LevelArtLayer([], [], [], 1),
			new LevelArtLayer([], [], [], 0.5),
			new LevelArtLayer([], [], [], 0.25),
			new LevelArtLayer([], [], [], 1),
			new LevelArtLayer([], [], [], 2)
		];
		var renderer = new LevelRenderer(new TestLevel(0x123456, [focus, new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10050, 10050)], layers),
			focus, 180, 280);

		var rearTransform = worldLayer(renderer, 1).transform.colorTransform;
		assertClose(0.6, rearTransform.redMultiplier, "quarter-scale rear art uses Flash tint multiplier");
		assertClose(0x12 * 0.4, rearTransform.redOffset, "quarter-scale rear art uses Flash red tint offset");
		assertClose(0x34 * 0.4, rearTransform.greenOffset, "quarter-scale rear art uses Flash green tint offset");
		assertClose(0x56 * 0.4, rearTransform.blueOffset, "quarter-scale rear art uses Flash blue tint offset");

		var blockTransform = worldLayer(renderer, 4).transform.colorTransform;
		assertClose(0.9, blockTransform.redMultiplier, "block map uses scale-one Flash tint multiplier");
		assertClose(0x12 * 0.1, blockTransform.redOffset, "block map uses scale-one red tint offset");

		var foregroundTransform = worldLayer(renderer, 6).transform.colorTransform;
		assertClose(1.3, foregroundTransform.redMultiplier, "double-scale foreground art uses Flash tint multiplier");
		assertClose(0x12 * -0.3, foregroundTransform.redOffset, "double-scale foreground art uses Flash red tint offset");

		renderer.setBackgroundColor(0x224466);
		rearTransform = worldLayer(renderer, 1).transform.colorTransform;
		assertClose(0x22 * 0.4, rearTransform.redOffset, "setBackgroundColor retints rear layer red offset");
		assertClose(0x44 * 0.4, rearTransform.greenOffset, "setBackgroundColor retints rear layer green offset");
		assertClose(0x66 * 0.4, rearTransform.blueOffset, "setBackgroundColor retints rear layer blue offset");
	}

	private static function testArtObjectAndTextLayerScale():Void {
		var focus = new DecodedBlock(ObjectCodes.BLOCK_START1, 10020, 10050);
		var layer = new LevelArtLayer([], [new LevelArtObject(0, 10, 20, 2, 3)], [new LevelTextObject("scaled", 15, 25, 0x00FF00, 4, 5)],
			0.5);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [focus], [layer]), focus, 180, 280);
		var artLayer = worldLayer(renderer, 1);
		var object = artLayer.getChildAt(1);
		var text = Std.downcast(artLayer.getChildAt(2), TextField);

		assertWithin(228.0, object.width, 0.02, "placed bitmap stamp keeps its authored width after object and layer scaling");
		assertWithin(259.125, object.height, 0.03, "placed bitmap stamp keeps its authored height after object and layer scaling");
		assertClose(2.0, text.scaleX, "placed text multiplies text scaleX by layer scale");
		assertClose(2.5, text.scaleY, "placed text multiplies text scaleY by layer scale");
		assertEquals(FontResolver.resolve("Verdana"), text.defaultTextFormat.font, "placed text preserves the authored font mapping");
		assertEquals(18.0, text.defaultTextFormat.size, "placed text preserves the authored font size");
		assertEquals(4, text.defaultTextFormat.leading, "placed text preserves the authored line height");
		assertEquals(false, text.selectable, "placed text remains nonselectable");
		assertEquals(false, text.wordWrap, "placed text preserves no-wrap behavior");
		assertEquals(true, text.multiline, "placed text preserves multiline behavior");
		assertEquals(true, text.cacheAsBitmap, "placed text preserves Flash bitmap caching");

		var escapedContainer = new Sprite();
		LevelRenderer.addLayerText(escapedContainer,
			new LevelTextObject("#96#38#44#59#43#45#35", 0, 0, 0x123456), 1);
		var escaped = Std.downcast(escapedContainer.getChildAt(0), TextField);
		assertEquals("`&,;+-#", escaped.text, "placed text decodes the complete Flash TextObject escape table in source order");
		assertEquals(0x123456, escaped.textColor, "placed text applies the serialized color");
	}

	private static function testArtLayerDepthAndParallax():Void {
		var focus = new DecodedBlock(ObjectCodes.BLOCK_START1, 10020, 10050);
		var layers = [
			new LevelArtLayer([], [], [], 1),
			new LevelArtLayer([], [], [], 0.5),
			new LevelArtLayer([new LevelDrawAction("d", [0, 0, 1, 1])], [], [], 0.25),
			new LevelArtLayer([], [], [], 1),
			new LevelArtLayer([], [], [], 2)
		];
		var level = new TestLevel(0xFFFFFF, [focus], layers);
		var renderer = new LevelRenderer(level, focus, 180, 280);

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
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [arrow]), arrow);
		renderer.animateArrow(arrow.worldX, arrow.worldY);
		var blockLayer = worldLayer(renderer, 1);
		var blockDisplay = Std.downcast(blockLayer.getChildAt(0), Sprite);
		var pivot = Std.downcast(blockDisplay.getChildAt(1), Sprite);
		var arrowTimeline = pivot.getChildAt(0);
		var explosion = renderer.showMineExplosion(arrow.worldX, arrow.worldY, false);
		var pieces = renderer.showBlockPieces("BrickPieceGraphic", arrow.worldX, arrow.worldY, 1, 10, 10, 25, 0.75, 0.95, 0.05,
			function() return 0.5);
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
	// LevelRenderer.worldContainer, which lets a rotate block spin the
	// whole world about the screen centre without moving the upright backgrounds.
	private static function worldLayer(renderer:LevelRenderer, index:Int):Sprite {
		var world = Std.downcast(renderer.getChildAt(1), Sprite);
		return Std.downcast(world.getChildAt(index - 1), Sprite);
	}

	private static function strokeRaster(artLayer:Sprite):Sprite {
		return Std.downcast(artLayer.getChildAt(0), Sprite);
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

	private static function assertWithin(expected:Float, actual:Float, tolerance:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > tolerance) {
			throw '$message: expected $expected +/- $tolerance, got $actual';
		}
	}

	private static function assertTrue(value:Bool, message:String):Void {
		assertions++;
		if (!value) {
			throw '$message: expected true';
		}
	}

	private static function deepChildCount(o:DisplayObject):Int {
		var container = Std.downcast(o, DisplayObjectContainer);
		if (container == null) {
			return 0;
		}
		var n = container.numChildren;
		for (i in 0...container.numChildren) {
			n += deepChildCount(container.getChildAt(i));
		}
		return n;
	}

	private static function findChildByName(root:DisplayObjectContainer, name:String):Null<DisplayObject> {
		var direct = root.getChildByName(name);
		if (direct != null) {
			return direct;
		}
		for (i in 0...root.numChildren) {
			var container = Std.downcast(root.getChildAt(i), DisplayObjectContainer);
			if (container == null) {
				continue;
			}
			var child = findChildByName(container, name);
			if (child != null) {
				return child;
			}
		}
		return null;
	}
}

private class DecodedBlock extends LevelBlock {
	public function new(code:Int, worldX:Int, worldY:Int, options:String = "") {
		super(Std.int(Math.floor(worldX / Level.DEFAULT_TILE_SIZE)), Std.int(Math.floor(worldY / Level.DEFAULT_TILE_SIZE)),
			LevelBlock.typeForCode(code), options, code);
	}
}

private class TestLevel extends Level {
	public function new(bgColor:Int, blocks:Array<DecodedBlock>, ?artLayers:Array<LevelArtLayer>, ?artBackgroundCode:Null<Int>) {
		var source = Level.fromDecoded(bgColor, cast blocks, artLayers, artBackgroundCode);
		super(source.id, source.name, source.widthTiles, source.heightTiles, source.tileSize, source.gravity, source.stats, source.playerStart,
			source.finish, cast blocks, source.minTileX, source.minTileY, source.bgColor, source.artLayers, source.artBackgroundCode, {
				minX: source.minX,
				minY: source.minY,
				maxX: source.maxX,
				maxY: source.maxY
			});
	}
}
