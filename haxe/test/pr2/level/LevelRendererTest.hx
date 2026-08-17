package pr2.level;

import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.utils.ByteArray;
import pr2.Constants;
import pr2.effects.BlockPiece;
import pr2.lobby.account.Settings;
import pr2.level.Level.LevelArtLayer;
import pr2.level.Level.LevelArtObject;
import pr2.level.Level.LevelDrawAction;
import pr2.level.Level.LevelTextObject;
import pr2.level.Level.LevelBlock;
import pr2.level.ArtTileStorage.ArtTileStore;
import pr2.level.LevelArtRasterizer.ArtRasterTiles;
import pr2.runtime.FontResolver;
import pr2.runtime.FrameClock;
import pr2.runtime.FrameRateDiagnostics;
import pr2.runtime.FrameRateSettings;

class LevelRendererTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testBlockAssetMapping", testBlockAssetMapping);
		if (pr2.DeterministicTestMode.finishSmokeSuite("LevelRendererTest")) return;
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testArtAssetMappings", testArtAssetMappings);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testPackedArtBackgroundMounts", testPackedArtBackgroundMounts);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testDefaultArtStrokeThickness", testDefaultArtStrokeThickness);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testArtEraseStrokeClearsRasterTiles", testArtEraseStrokeClearsRasterTiles);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testNativeArtRasterScaleAddsFixedSizeTiles", testNativeArtRasterScaleAddsFixedSizeTiles);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testArtRerasterizesAtHigherDensity", testArtRerasterizesAtHigherDensity);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testWorldToScreenFocus", testWorldToScreenFocus);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testPresentationCameraOffsetDoesNotRebuild", testPresentationCameraOffsetDoesNotRebuild);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testPresentationCourseRotationDoesNotAdvanceAuthority", testPresentationCourseRotationDoesNotAdvanceAuthority);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testRotationCommitDefersArtCullingUntilCameraSnap", testRotationCommitDefersArtCullingUntilCameraSnap);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testBackgroundColorTransforms", testBackgroundColorTransforms);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testArtObjectAndTextLayerScale", testArtObjectAndTextLayerScale);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testBlockAlphaUpdate", testBlockAlphaUpdate);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testOverlappingBlockGhostDisplay", testOverlappingBlockGhostDisplay);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testBlockColorMultiplierUpdate", testBlockColorMultiplierUpdate);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testBlockIceOverlayUpdate", testBlockIceOverlayUpdate);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testTeleportBlockColorBackground", testTeleportBlockColorBackground);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testBlockBumpAnimation", testBlockBumpAnimation);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testMoveBlockDisplay", testMoveBlockDisplay);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testMoveBlockArrowDisplay", testMoveBlockArrowDisplay);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testIncrementalBlockDrawing", testIncrementalBlockDrawing);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testRuntimeBlockAppendPreservesDrawingCompletion", testRuntimeBlockAppendPreservesDrawingCompletion);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testViewWindowRefreshesBeforeLeftEdgeExposure", testViewWindowRefreshesBeforeLeftEdgeExposure);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testIncrementalArtDrawing", testIncrementalArtDrawing);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testRaceReadinessWaitsForEveryArtTile", testRaceReadinessWaitsForEveryArtTile);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testRaceReadinessAcceptsEmptyArtLayers", testRaceReadinessAcceptsEmptyArtLayers);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testArtRasterTilesCullToViewWindow", testArtRasterTilesCullToViewWindow);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testArtRasterTilesReleaseColdPixels", testArtRasterTilesReleaseColdPixels);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testArtRasterSavesAreBounded", testArtRasterSavesAreBounded);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testArtRasterLifecycleUpdatesImmediately", testArtRasterLifecycleUpdatesImmediately);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testArtRasterHotAndWarmMargins", testArtRasterHotAndWarmMargins);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testArtTileCacheIdentityTracksContentAndScale", testArtTileCacheIdentityTracksContentAndScale);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testIncrementalArtFailureCompletesAndWarns", testIncrementalArtFailureCompletesAndWarns);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testRasterTileLimitStopsAndWarns", testRasterTileLimitStopsAndWarns);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testArtDefaultsToUnlimitedNativeDensity", testArtDefaultsToUnlimitedNativeDensity);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testArtBatchLimitsRejectHugeSpans", testArtBatchLimitsRejectHugeSpans);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testDrawArtSettingSkipsGameplayArt", testDrawArtSettingSkipsGameplayArt);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testBg5CircleGrid", testBg5CircleGrid);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testArrowAnimation", testArrowAnimation);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testSpawnMarkerBlocksNotRendered", testSpawnMarkerBlocksNotRendered);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testRemoteVisibleBlockActivation", testRemoteVisibleBlockActivation);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testMineExplosion", testMineExplosion);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testRotatedMineAppearUsesDisplayedWorldFrame", testRotatedMineAppearUsesDisplayedWorldFrame);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testRotatedTeleportPopUsesEffectFrame", testRotatedTeleportPopUsesEffectFrame);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testBlockPieces", testBlockPieces);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testArtLayerDepthAndParallax", testArtLayerDepthAndParallax);
		pr2.DeterministicTestMode.runTest("LevelRendererTest.testRemoveDisposesAnimatedChildren", testRemoveDisposesAnimatedChildren);
		trace('LevelRendererTest passed $assertions assertions');
	}

	private static function testPresentationCourseRotationDoesNotAdvanceAuthority():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 0, 0);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block]), block);
		renderer.setCourseRotation(0, 3);
		var blockWindowUpdates = @:privateAccess renderer.viewWindowUpdateCount;
		var artWindowUpdates = @:privateAccess renderer.artViewWindowUpdateCount;

		renderer.setPresentationCourseTweenRotation(4.5);

		assertClose(3, renderer.courseTweenRotation(), "presentation spin leaves authoritative tween angle");
		assertClose(4.5, renderer.presentationCourseTweenRotation(), "presentation spin accepts half-step angle");
		assertEquals(blockWindowUpdates, @:privateAccess renderer.viewWindowUpdateCount,
			"presentation spin does not advance block culling");
		assertEquals(artWindowUpdates, @:privateAccess renderer.artViewWindowUpdateCount,
			"presentation spin does not advance art culling");

		renderer.setCourseRotation(0, 6);
		assertClose(6, renderer.courseTweenRotation(), "next simulation advances authoritative tween");
		assertClose(6, renderer.presentationCourseTweenRotation(), "simulation restores authoritative presented tween");
		renderer.setCourseRotation(90, 0);
		assertClose(0, renderer.courseTweenRotation(), "rotation commit clears authoritative tween");
		assertClose(0, renderer.presentationCourseTweenRotation(), "rotation commit snaps presented tween");
		renderer.remove();
	}

	private static function testRotatedMineAppearUsesDisplayedWorldFrame():Void {
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, []));
		renderer.setCourseRotation(90, 0);
		var displayed = renderer.blockWorldToRotatedWorld(75, 165);
		var effect = renderer.showMineAppear(displayed.x, displayed.y, 60, 150, renderer.courseRotationDegrees, false);

		assertClose(-165, displayed.x, "90-degree receiver projects canonical mine x into its display frame");
		assertClose(75, displayed.y, "90-degree receiver projects canonical mine y into its display frame");
		assertClose(displayed.x, effect.x, "rotated mine animation uses the block layer's displayed x");
		assertClose(displayed.y, effect.y, "rotated mine animation uses the block layer's displayed y");
		assertClose(90, effect.rotation, "rotated mine artwork aligns with the committed course rotation");
		effect.remove();
		renderer.remove();
	}

	private static function testRotatedTeleportPopUsesEffectFrame():Void {
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, []));
		var effects = new Sprite();
		renderer.attachEffectLayer(effects);
		renderer.setCourseRotation(90, 0);
		var effect = renderer.showTeleportPop(-165, 75, false);

		assertEquals(effects, effect.parent, "teleport pop mounts on Flash's unrotated effect plane");
		assertClose(-165, effect.x, "rotated teleport pop keeps the player's displayed x");
		assertClose(75, effect.y, "rotated teleport pop keeps the player's displayed y");
		effect.remove();
		renderer.remove();
	}

	private static function testRotationCommitDefersArtCullingUntilCameraSnap():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 0, 0);
		var art = new LevelArtLayer([new LevelDrawAction("d", [20, 20])]);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block], [art]), block);
		var updatesBeforeCommit = @:privateAccess renderer.artViewWindowUpdateCount;

		renderer.setCourseRotation(90, 0);

		assertEquals(updatesBeforeCommit, @:privateAccess renderer.artViewWindowUpdateCount,
			"rotation commit does not reconcile art against the stale camera");
		assertEquals(true, @:privateAccess renderer.artViewRefreshPendingAfterRotation,
			"rotation commit remembers the deferred art refresh");

		renderer.setCameraOffset(180, 280);

		assertEquals(updatesBeforeCommit + 1, @:privateAccess renderer.artViewWindowUpdateCount,
			"camera snap performs one art reconciliation for the committed rotation");
		assertEquals(false, @:privateAccess renderer.artViewRefreshPendingAfterRotation,
			"camera snap clears the deferred refresh");
		renderer.remove();
	}

	private static function testPresentationCameraOffsetDoesNotRebuild():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 0, 0);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block]), block);
		renderer.setCameraOffset(10.4, 20.6);
		var blockWindowUpdates = @:privateAccess renderer.viewWindowUpdateCount;
		var artWindowUpdates = @:privateAccess renderer.artViewWindowUpdateCount;

		renderer.setPresentationCameraOffset(10.75, 20.25);

		var authoritative = renderer.cameraOffset();
		var presented = renderer.presentationCameraOffset();
		assertClose(10, authoritative.x, "presentation update leaves authoritative camera x");
		assertClose(21, authoritative.y, "presentation update leaves authoritative camera y");
		assertClose(10.75, presented.x, "presentation camera preserves fractional x");
		assertClose(20.25, presented.y, "presentation camera preserves fractional y");
		assertEquals(blockWindowUpdates, @:privateAccess renderer.viewWindowUpdateCount,
			"presentation camera does not update block culling window");
		assertEquals(artWindowUpdates, @:privateAccess renderer.artViewWindowUpdateCount,
			"presentation camera does not update art culling windows");
		var screen = renderer.worldToScreen(5, 7);
		assertClose(15.75, screen.x, "world-to-screen uses disposable presentation x");
		assertClose(27.25, screen.y, "world-to-screen uses disposable presentation y");
		var world = renderer.screenToWorld(screen.x, screen.y);
		assertClose(5, world.x, "screen-to-world inverts disposable presentation x");
		assertClose(7, world.y, "screen-to-world inverts disposable presentation y");

		var authoritativeColMin = @:privateAccess renderer.viewColMin;
		var authoritativeColMax = @:privateAccess renderer.viewColMax;
		var authoritativeRowMin = @:privateAccess renderer.viewRowMin;
		var authoritativeRowMax = @:privateAccess renderer.viewRowMax;
		renderer.setPresentationCameraOffset(-5000.5, 4000.25);
		@:privateAccess renderer.updateViewWindow(true);
		assertEquals(authoritativeColMin, @:privateAccess renderer.viewColMin,
			"forced block culling ignores disposable presentation x");
		assertEquals(authoritativeColMax, @:privateAccess renderer.viewColMax,
			"conservative block culling max remains authoritative");
		assertEquals(authoritativeRowMin, @:privateAccess renderer.viewRowMin,
			"forced block culling ignores disposable presentation y");
		assertEquals(authoritativeRowMax, @:privateAccess renderer.viewRowMax,
			"conservative block culling row max remains authoritative");
		renderer.remove();
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
		piece.dispatchEvent(new openfl.events.Event(openfl.events.Event.ENTER_FRAME));
		piece.renderPresentationFrame();
		assertClose(block.worldY + 17.94375, piece.y,
			"block-piece presentation extrapolates half of its latest gravity-driven step");
		assertClose(0.9, piece.alpha, "block-piece presentation does not advance authoritative fading");
		piece.dispatchEvent(new openfl.events.Event(openfl.events.Event.ENTER_FRAME));
		assertClose(block.worldY + 19.351875, piece.y,
			"the next block-piece simulation tick resumes from authoritative rather than presented position");
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

	private static function testOverlappingBlockGhostDisplay():Void {
		var underlying = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050);
		var active = new DecodedBlock(ObjectCodes.BLOCK_BRICK, 10020, 10050);
		var level = new TestLevel(0xFFFFFF, [underlying, active]);
		var renderer = new LevelRenderer(level, underlying);
		var blockLayer = worldLayer(renderer, 1);
		var stack = Std.downcast(blockLayer.getChildAt(0), Sprite);
		var underlyingDisplay = Std.downcast(stack.getChildAt(0), Sprite);
		var activeDisplay = Std.downcast(stack.getChildAt(1), Sprite);

		assertEquals(1, blockLayer.numChildren, "same-tile blocks share one culling root");
		assertEquals(2, stack.numChildren, "Flash keeps every overlapping block sprite");
		renderer.setBlockAlpha(active.worldX, active.worldY, 0.5);
		assertEquals(1.0, underlyingDisplay.alpha, "active styling does not alter the display-only ghost");
		assertEquals(0.5, activeDisplay.alpha, "active styling targets the latest overlapping block");

		var removedIndex = level.blocks.indexOf(active);
		level.blocks.splice(removedIndex, 1);
		renderer.removeRuntimeBlockDisplay(active, removedIndex);

		assertEquals(1, blockLayer.numChildren, "removing the active overlap retains the tile culling root");
		assertEquals(1, stack.numChildren, "removing the active overlap reveals one ghost sprite");
		assertEquals(underlyingDisplay, stack.getChildAt(0), "older overlapping artwork remains visible");
		assertEquals(null, renderer.blockAlphaAt(active.worldX, active.worldY), "revealed ghost is not addressable as an active block");
		renderer.remove();
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
		assertEquals(1, strokeRaster(artLayer).numChildren, "completed stroke indexing mounts its visible tile immediately");
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
		var frames = 0;
		while (!renderer.isDrawingComplete() && frames++ < 10) renderer.dispatchEvent(new Event(Event.ENTER_FRAME));

		assertEquals(1, raster.numChildren, "art raster culling starts with only visible tiles attached");
		var visible = Std.downcast(raster.getChildAt(0), Bitmap);
		assertEquals(nearTileX, Std.int(visible.x), "initial art raster tile is the focused tile");

		renderer.setCameraOffset(180 - farX, 280 - focus.worldY);
		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, raster.numChildren, "scrolling replaces the visible tile immediately");
		assertEquals(true, renderer.isDrawingComplete(), "post-start culling cannot reopen race loading or free-scroll mode");
		var scrollFrames = 1;
		while (raster.numChildren == 0 && scrollFrames++ < 6) renderer.dispatchEvent(new Event(Event.ENTER_FRAME));

		assertEquals(1, raster.numChildren, "art raster culling keeps off-screen tiles detached after scroll");
		assertEquals(true, scrollFrames <= 5, "newly visible cached art attaches after loading");
		visible = Std.downcast(raster.getChildAt(0), Bitmap);
		assertEquals(farTileX, Std.int(visible.x), "scrolling attaches the newly visible raster tile");
	}

	private static function testRaceReadinessWaitsForEveryArtTile():Void {
		var focus = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050);
		var distance = LevelRenderer.ART_RASTER_TILE_SIZE * 15;
		var art = new LevelArtLayer([new LevelDrawAction("d", [focus.worldX, focus.worldY, distance, 0])], [], [], 1);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [focus], [art]), focus, 180, 280, true, 1);
		var frames = 0;
		while (renderer.drawnArtItemCount() == 0 && frames++ < 10) renderer.dispatchEvent(new Event(Event.ENTER_FRAME));

		assertEquals(1, renderer.drawnArtItemCount(), "all art commands can finish before tile baking");
		assertEquals(true, renderer.isDrawingComplete(), "direct tile rendering can bake every tile in the art-command frame");
		while (!renderer.isDrawingComplete() && frames++ < 20) renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(true, renderer.isDrawingComplete(), "race readiness opens after every art tile is baked");
		renderer.remove();
	}

	private static function testRaceReadinessAcceptsEmptyArtLayers():Void {
		var focus = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050);
		var drawn = new LevelArtLayer([new LevelDrawAction("d", [focus.worldX, focus.worldY])], [], [], 1);
		var empty = new LevelArtLayer([], [], [], 1);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [focus], [drawn, empty]), focus, 180, 280, true, 1);
		var frames = 0;
		while (!renderer.isDrawingComplete() && frames++ < 10) renderer.dispatchEvent(new Event(Event.ENTER_FRAME));

		assertEquals(true, renderer.isDrawingComplete(), "empty trailing art layers cannot hold race readiness open");
		renderer.remove();
	}

	private static function testArtRasterTilesReleaseColdPixels():Void {
		var raster = new Sprite();
		var store = new TestArtTileStore();
		var tile = LevelRenderer.ART_RASTER_TILE_SIZE;
		var tiles = new ArtRasterTiles(raster, null, 1, {
			store: store,
			groupKey: "test-group",
			levelId: "test-level",
			layerIndex: 0,
			encode: function(_):ByteArray {
				var bytes = new ByteArray();
				bytes.writeByte(1);
				return bytes;
			}
		});
		tiles.applyAll([
			new LevelDrawAction("d", [20, 20]),
			new LevelDrawAction("d", [tile * 6 + 20, 20])
		]);
		tiles.setVisibleWorldWindow(0, 100, 0, 100, true);
		tiles.updateTiles(1000);
		tiles.updateTiles(1000);

		assertEquals(1, tiles.hotTileCount(), "visible art tile is hot");
		assertEquals(0, tiles.unbakedTileCount(), "startup baking renders distant art before play");
		assertEquals(2, store.putCount, "startup baking persists every art tile");
		assertTrue(tiles.isBakeComplete(), "art baking completes only after every cache write");

		tiles.setVisibleWorldWindow(tile * 6, tile * 6 + 100, 0, 100, true);
		tiles.updateTiles(1000);
		tiles.updateTiles(1000);

		assertEquals(1, tiles.hotTileCount(), "newly visible art tile is promoted to hot");
		assertEquals(1, tiles.coldTileCount(), "former hot tile releases its BitmapData after persistence");
		assertEquals(1, raster.numChildren, "only the hot tile remains attached");
		tiles.dispose();
	}

	private static function testArtRasterLifecycleUpdatesImmediately():Void {
		var raster = new Sprite();
		var tile = LevelRenderer.ART_RASTER_TILE_SIZE;
		var tiles = new ArtRasterTiles(raster);
		tiles.applyAll([
			new LevelDrawAction("d", [20, 20]),
			new LevelDrawAction("d", [tile + 20, 20])
		]);
		tiles.setVisibleWorldWindow(0, tile * 2, 0, 100, true);

		assertEquals(2, tiles.hotTileCount(), "all hot tiles render immediately");
		assertEquals(2, raster.numChildren, "all hot tiles attach immediately");

		tiles.setVisibleWorldWindow(tile * 5, tile * 6, 0, 100, true);
		assertEquals(0, raster.numChildren, "tiles leaving the hot window detach immediately");
		assertEquals(2, tiles.coldTileCount(), "tiles leaving the warm window release their pixels immediately");
		tiles.dispose();
	}

	private static function testArtRasterSavesAreBounded():Void {
		var raster = new Sprite();
		var store = new TestArtTileStore();
		var tile = LevelRenderer.ART_RASTER_TILE_SIZE;
		var tiles = new ArtRasterTiles(raster, null, 1, {
			store: store,
			groupKey: "save-limit-group",
			levelId: "save-limit-level",
			layerIndex: 0,
			encode: function(_):ByteArray {
				var bytes = new ByteArray();
				bytes.writeByte(1);
				return bytes;
			}
		});
		tiles.applyAll([new LevelDrawAction("d", [20, 20, tile * 11, 0])]);
		tiles.setVisibleWorldWindow(0, tile * 12, 0, 100, true);

		assertEquals(10, tiles.updateTiles(10), "one update starts at most ten persistent-cache saves");
		assertEquals(10, store.putCount, "the first update writes only its ten-tile allowance");
		assertEquals(2, tiles.updateTiles(10), "the next update starts the remaining saves");
		assertEquals(12, store.putCount, "every tile is eventually persisted");
		tiles.dispose();
	}

	private static function testArtRasterHotAndWarmMargins():Void {
		var raster = new Sprite();
		var tile = LevelRenderer.ART_RASTER_TILE_SIZE;
		var tiles = new ArtRasterTiles(raster);
		tiles.applyAll([
			new LevelDrawAction("d", [20, 20]),
			new LevelDrawAction("d", [tile + 20, 20]),
			new LevelDrawAction("d", [tile * 2 + 20, 20]),
			new LevelDrawAction("d", [tile * 3 + 20, 20])
		]);
		tiles.setVisibleWorldWindow(0, 100, 0, 100, true);
		tiles.updateTiles(1000);

		assertEquals(2, tiles.hotTileCount(), "visible tiles plus a one-tile margin are attached");
		assertEquals(1, tiles.warmTileCount(), "the second margin tile remains warm but detached");
		assertEquals(1, tiles.coldTileCount(), "tiles beyond the two-tile warm margin release their pixels");
		assertEquals(2, raster.numChildren, "only the visible tile and first margin tile are mounted");
		tiles.dispose();
	}

	private static function testArtTileCacheIdentityTracksContentAndScale():Void {
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 0, 0);
		var first = new TestLevel(0xFFFFFF, [block], [new LevelArtLayer([new LevelDrawAction("d", [20, 20])])]);
		var second = new TestLevel(0xFFFFFF, [block], [new LevelArtLayer([new LevelDrawAction("d", [21, 20])])]);
		var key = ArtTileCacheIdentity.groupKey(first, 1);

		assertEquals(key, ArtTileCacheIdentity.groupKey(first, 1), "unchanged art produces a stable cache group");
		assertTrue(key != ArtTileCacheIdentity.groupKey(first, 2), "raster density selects a different cache group");
		assertTrue(key != ArtTileCacheIdentity.groupKey(second, 1), "changed art selects a different cache group");
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
		var frames = 0;
		while (!renderer.isDrawingComplete() && frames++ < 10) renderer.dispatchEvent(new Event(Event.ENTER_FRAME));

		assertEquals(true, renderer.stoppedRasterizing, "raster tile budget sets stoppedRasterizing");
		assertEquals(1, warnings.length, "raster stop warning emits once");
		assertEquals(LevelRenderer.ART_RASTER_STOP_WARNING, warnings[0], "raster stop warning does not reference a removed quality option");
		assertEquals(1, strokeRaster(artLayer).numChildren, "raster tile budget stops creating new tiles after the limit");
		assertEquals(true, renderer.isDrawingComplete(), "raster stop does not leave renderer stuck drawing");
	}

	private static function testArtDefaultsToUnlimitedNativeDensity():Void {
		Settings.disablePersistenceForTests();
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 10020, 10050);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block]), block, 180, 280, false,
			LevelRenderer.DEFAULT_BLOCKS_PER_FRAME, {rasterScale: 2});
		assertEquals(-1, @:privateAccess renderer.artRasterBudget.limit, "art has no default raster tile limit");
		assertEquals(2.0, @:privateAccess renderer.artRasterScale, "art always uses native-output raster scaling");
		renderer.remove();
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
		assertTrue(Std.isOfType(blockDisplay.getChildAt(0), Bitmap), "teleport Flash-parity bitmap background is the bottom child");
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
		var clock = new FrameClock(FrameRateSettings.fromQuery("?smooth60=1", true), new FrameRateDiagnostics(function():Float return 0));
		@:privateAccess FrameClock.setCurrentForTests(clock);
		clock.advanceFrame();
		clock.advanceFrame();
		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(0.9, renderer.blockAlphaAt(water.worldX, water.worldY),
			"presentation frame holds the latest discrete block visibility/alpha state");
		clock.advanceFrame();
		renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(0.93, renderer.blockAlphaAt(water.worldX, water.worldY), "remote water ripple recovers each frame");
		@:privateAccess FrameClock.setCurrentForTests(null);
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

	private static function testNativeArtRasterScaleAddsFixedSizeTiles():Void {
		var actions = [new LevelDrawAction("d", [10, 10, 300, 0])];
		var standardRaster = new Sprite();
		LevelRenderer.renderLayerStrokes(standardRaster, actions);
		var nativeRaster = new Sprite();
		LevelRenderer.renderLayerStrokes(nativeRaster, actions, null, 2);

		assertEquals(1, standardRaster.numChildren, "standard density fits the test stroke in one tile");
		assertEquals(2, nativeRaster.numChildren, "2x native density covers the same stroke with more tiles");
		var nativeTile = Std.downcast(nativeRaster.getChildAt(0), Bitmap);
		assertEquals(LevelRenderer.ART_RASTER_TILE_SIZE + 1, nativeTile.bitmapData.width, "native-density tiles keep the fixed texture width");
		assertEquals(LevelRenderer.ART_RASTER_TILE_SIZE + 1, nativeTile.bitmapData.height, "native-density tiles keep the fixed texture height");
		assertClose(0.5, nativeTile.scaleX, "2x native-density tile covers half as many game units horizontally");
		assertClose(0.5, nativeTile.scaleY, "2x native-density tile covers half as many game units vertically");
		var nextNativeTile = Std.downcast(nativeRaster.getChildAt(1), Bitmap);
		assertClose(LevelRenderer.ART_RASTER_TILE_SIZE / 2, nextNativeTile.x, "next 2x tile begins after half the standard world span");
	}

	private static function testArtRerasterizesAtHigherDensity():Void {
		Settings.disablePersistenceForTests();
		var block = new DecodedBlock(ObjectCodes.BLOCK_BASIC1, 0, 0);
		var art = new LevelArtLayer([new LevelDrawAction("d", [10, 10, 300, 0])], [], [], 1);
		var renderer = new LevelRenderer(new TestLevel(0xFFFFFF, [block], [art]), block, 180, 280, false,
			LevelRenderer.DEFAULT_BLOCKS_PER_FRAME, {rasterScale: 1});
		var frames = 0;
		while (!renderer.isDrawingComplete() && frames++ < 10) renderer.dispatchEvent(new Event(Event.ENTER_FRAME));

		assertEquals(1, strokeRaster(worldLayer(renderer, 1)).numChildren, "art starts with one standard-density tile");
		@:privateAccess renderer.artRenderer.rerasterizeLayers(2);
		while (strokeRaster(worldLayer(renderer, 1)).numChildren < 2 && frames++ < 20) renderer.dispatchEvent(new Event(Event.ENTER_FRAME));
		var rerasterized = strokeRaster(worldLayer(renderer, 1));
		assertEquals(2, rerasterized.numChildren, "density increase rebuilds existing art with more tiles");
		assertClose(0.5, Std.downcast(rerasterized.getChildAt(0), Bitmap).scaleX,
			"rebuilt art tiles use the higher raster density");

		renderer.remove();
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
		assertEquals(true, object.cacheAsBitmap, "static placed artwork starts with renderer caching enabled");
		var objectParent = object.parent;
		var textParent = text.parent;
		renderer.setPresentationCameraOffset(180.5, 279.5);
		renderer.setPresentationCourseTweenRotation(1.5);
		assertEquals(true, object.cacheAsBitmap, "presentation camera/course transforms preserve static art caching");
		assertEquals(true, text.cacheAsBitmap, "presentation camera/course transforms preserve text bitmap caching");
		assertEquals(objectParent, object.parent, "presentation transforms do not rebuild or reparent static artwork");
		assertEquals(textParent, text.parent, "presentation transforms do not rebuild or reparent cached text");
		assertEquals(true, renderer.debugArtCachingEnabled(), "presentation transforms leave the renderer cache policy enabled");

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

		// Flash parallaxes the camera position alone (`Background.setPos`:
		// `x = Math.round(cameraPos * scale)`); the viewport centring sits on the
		// `GamePage` sprite (`x = 550 / 2; y = 400 / 2`). The port folds that centre
		// into the camera offset, so it has to be lifted back out before scaling —
		// otherwise every layer whose scale is not 1 drifts by
		// `(scale - 1) * halfStage` (up/left below 1, down/right above).
		var halfW = Constants.STAGE_WIDTH / 2;
		var halfH = Constants.STAGE_HEIGHT / 2;
		var rear = worldLayer(renderer, 1);
		assertEquals(halfW + Math.round((180.0 - 10020 - halfW) * 0.25), rear.x, "rear layer x applies authored parallax scale");
		assertEquals(halfH + Math.round((280.0 - 10050 - halfH) * 0.25), rear.y, "rear layer y applies authored parallax scale");

		renderer.setCameraOffset(315.4, 172.6);
		assertEquals(halfW + Math.round((315.4 - halfW) * 0.25), rear.x, "rear layer x follows camera at quarter speed");
		assertEquals(halfH + Math.round((172.6 - halfH) * 0.25), rear.y, "rear layer y follows camera at quarter speed");
		var foreground = worldLayer(renderer, 6);
		assertEquals(halfW + Math.round((315.4 - halfW) * 2), foreground.x, "foreground layer x follows camera at double speed");
		assertEquals(halfH + Math.round((172.6 - halfH) * 2), foreground.y, "foreground layer y follows camera at double speed");

		// A stage-centred camera leaves every layer exactly on the centre: parallax
		// only separates layers as the camera moves away from where it started.
		renderer.setCameraOffset(halfW, halfH);
		assertEquals(halfW, rear.x, "centred camera keeps the rear layer aligned with the block plane");
		assertEquals(halfW, foreground.x, "centred camera keeps the foreground layer aligned with the block plane");

		renderer.setCameraOffset(315.4, 172.6);
		renderer.setPresentationCameraOffset(315.75, 172.25);
		assertClose(halfW + (315.75 - halfW) * 0.25, rear.x, "presentation rear parallax preserves fractional x");
		assertClose(halfH + (172.25 - halfH) * 0.25, rear.y, "presentation rear parallax preserves fractional y");
		assertClose(halfW + (315.75 - halfW) * 2, foreground.x, "presentation foreground parallax preserves fractional x");
		assertClose(halfH + (172.25 - halfH) * 2, foreground.y, "presentation foreground parallax preserves fractional y");
		var blockLayer = worldLayer(renderer, 4);
		assertClose(315.75, blockLayer.transform.matrix.tx, "presentation block plane preserves fractional x");
		assertClose(172.25, blockLayer.transform.matrix.ty, "presentation block plane preserves fractional y");

		renderer.setCameraOffset(315.4, 172.6);
		assertEquals(halfW + Math.round((315.4 - halfW) * 0.25), rear.x, "next simulation restores rounded rear parallax x");
		assertEquals(halfH + Math.round((172.6 - halfH) * 0.25), rear.y, "next simulation restores rounded rear parallax y");
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

private class TestArtTileStore implements ArtTileStore {
	public var putCount(default, null):Int = 0;
	private final entries:Map<String, ByteArray> = new Map();
	public var enabled(get, never):Bool;
	private inline function get_enabled():Bool return true;

	public function new() {}
	public function prepareGroup(groupKey:String, levelId:String):Void {}
	// The eval test target cannot decode PNG bytes, so this fake exercises writes
	// and reports misses when a cold tile is promoted again.
	public function get(groupKey:String, tileKey:String, callback:Null<ByteArray>->Void):Void callback(null);
	public function put(groupKey:String, levelId:String, tileKey:String, bytes:ByteArray, callback:Bool->Void):Void {
		entries.set(groupKey + ":" + tileKey, bytes);
		putCount++;
		callback(true);
	}
	public function dispose():Void {}
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
