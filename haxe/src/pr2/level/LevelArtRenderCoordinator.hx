package pr2.level;

import haxe.Timer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Point;
import pr2.Constants;
import pr2.gameplay.PrizePopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.level.Level.LevelArtLayer;
import pr2.level.LevelArtCursor.ArtDrawCursor;
import pr2.level.LevelArtRasterizer.ArtRasterTiles;

/** Coordinates layer creation, incremental art work, and raster-tile mounting. */
@:access(pr2.level.LevelRenderer)
class LevelArtRenderCoordinator {
	private final owner:LevelRenderer;
	private var rasterSaveFrame:Int = -1;
	private var rasterSavesStartedThisFrame:Int = 0;

	public function new(owner:LevelRenderer) this.owner = owner;

	public function drawLayer(index:Int):Void {
		if (!owner.drawArtEnabled || index >= owner.level.artLayers.length) return;
		var layer = owner.level.artLayers[index];
		var container = new Sprite();
		container.name = 'artLayer${index + 1}';
		container.x = LevelRenderer.artParallaxOffsetX(owner.offsetX, layer.scale);
		container.y = LevelRenderer.artParallaxOffsetY(owner.offsetY, layer.scale);
		owner.artLayerContainers[index] = container;
		var rasterCanvas = new Sprite();
		rasterCanvas.name = LevelRenderer.ART_RASTER_CANVAS_NAME;
		container.addChild(rasterCanvas);
		var strokeTiles = createRasterTiles(rasterCanvas, index, owner.artRasterScale);
		owner.artRasterTileLayers[index] = strokeTiles;
		if (owner.incrementalBlocks) {
			owner.totalArtItems += layer.drawActions.length + layer.objects.length + layer.texts.length;
			owner.artDrawCursors[index] = new ArtDrawCursor(container, strokeTiles, layer);
		} else {
			try {
				strokeTiles.applyAll(layer.drawActions);
				owner.drawLayerObjects(container, layer.objects, layer.scale);
				owner.drawLayerTexts(container, layer.texts, layer.scale);
			} catch (error:Dynamic) {
				handleFailure(error);
			}
		}
		owner.worldContainer.addChild(container);
		updateViewWindow(strokeTiles, true);
		if (!owner.incrementalBlocks) {
			updateRasterTiles();
			continueRasterWork();
		}
	}

	private function createRasterTiles(rasterCanvas:Sprite, layerIndex:Int, rasterScale:Float):ArtRasterTiles {
		return new ArtRasterTiles(rasterCanvas, owner.artRasterBudget, rasterScale, {
			store: owner.artTileStore,
			groupKey: owner.artTileCacheGroup,
			levelId: owner.level.id,
			layerIndex: layerIndex
		}, continueRasterWork);
	}

	public function drawBatch(event:Event):Void {
		if (!pr2.runtime.FrameClock.shouldRunSimulationFrame()) return;
		var deadline = Timer.stamp() + LevelRenderer.RENDER_FRAME_ESCAPE_SECONDS;
		try {
			drawNextForFrame(deadline);
			if (Timer.stamp() < deadline) updateRasterTiles();
		} catch (error:Dynamic) {
			handleFailure(error);
		}
		if (owner.drawnArtItems >= owner.totalArtItems) {
			owner.removeEventListener(Event.ENTER_FRAME, drawBatch);
			continueRasterWork();
		}
	}

	private function drawNextForFrame(escapeDeadline:Float):Void {
		var deadline = owner.blocksPerFrame == LevelRenderer.DEFAULT_BLOCKS_PER_FRAME
			? Math.min(Timer.stamp() + LevelRenderer.ART_DRAW_FRAME_BUDGET_SECONDS, escapeDeadline) : escapeDeadline;
		var drawnThisFrame = 0;
		var actionBatchLimit = owner.blocksPerFrame == LevelRenderer.DEFAULT_BLOCKS_PER_FRAME ? LevelRenderer.ART_DRAW_ACTION_BATCH_LIMIT : 1;
		var maxItemsThisFrame = owner.blocksPerFrame == LevelRenderer.DEFAULT_BLOCKS_PER_FRAME ? 1000000 : owner.blocksPerFrame;
		while (owner.drawnArtItems < owner.totalArtItems && drawnThisFrame < maxItemsThisFrame && (drawnThisFrame == 0 || Timer.stamp() < deadline)) {
			var before = owner.drawnArtItems;
			drawNextItems(actionBatchLimit, deadline);
			if (owner.drawnArtItems == before) return;
			drawnThisFrame += owner.drawnArtItems - before;
		}
	}

	private function drawNextItems(limit:Int, ?deadline:Null<Float>):Void {
		var remaining = limit;
		while (remaining > 0 && owner.drawnArtItems < owner.totalArtItems) {
			while (owner.nextArtLayerToDraw < owner.artDrawCursors.length && owner.artDrawCursors[owner.nextArtLayerToDraw] == null) owner.nextArtLayerToDraw++;
			if (owner.nextArtLayerToDraw >= owner.artDrawCursors.length) return;
			var cursor = owner.artDrawCursors[owner.nextArtLayerToDraw];
			if (owner.artOptions != null && owner.artOptions.artDrawFaultInjector != null) owner.artOptions.artDrawFaultInjector(owner.attemptedArtItems);
			var started = Timer.stamp();
			var drawn = cursor.drawNext(owner.artOptions != null && owner.artOptions.artDrawFaultInjector != null ? 1 : remaining, deadline);
			recordProfile(cursor, owner.nextArtLayerToDraw, drawn, (Timer.stamp() - started) * 1000);
			if (drawn > 0) {
				owner.attemptedArtItems += drawn;
				owner.drawnArtItems += drawn;
				remaining -= drawn;
			}
			if (cursor.isComplete()) owner.nextArtLayerToDraw++;
			if (deadline != null && Timer.stamp() >= deadline) return;
		}
	}

	private function recordProfile(cursor:ArtDrawCursor, layerIndex:Int, drawn:Int, elapsedMs:Float):Void {
		owner.artProfileLastMs = cursor.lastProfileMs > 0 ? cursor.lastProfileMs : elapsedMs;
		owner.artProfileLastLayer = layerIndex;
		owner.artProfileLastAction = cursor.lastProfileActionIndex;
		owner.artProfileLastKind = cursor.lastProfileKind;
		owner.artProfileLastPath = cursor.lastProfilePath;
		owner.artProfileLastMode = cursor.lastProfileMode;
		owner.artProfileLastItems = drawn;
		owner.artProfileLastValues = cursor.lastProfileValueCount;
		owner.artProfileLastTiles = cursor.lastProfileTileCount;
		owner.artProfileLastSpanX = cursor.lastProfileTileSpanX;
		owner.artProfileLastSpanY = cursor.lastProfileTileSpanY;
		if (elapsedMs >= LevelRenderer.ART_DRAW_SLOW_PROFILE_MS) owner.artProfileSlowCount++;
		if (elapsedMs > owner.artProfileMaxMs) {
			owner.artProfileMaxMs = elapsedMs;
			owner.artProfileMaxLayer = owner.artProfileLastLayer;
			owner.artProfileMaxAction = owner.artProfileLastAction;
			owner.artProfileMaxKind = owner.artProfileLastKind;
			owner.artProfileMaxPath = owner.artProfileLastPath;
			owner.artProfileMaxMode = owner.artProfileLastMode;
			owner.artProfileMaxItems = owner.artProfileLastItems;
			owner.artProfileMaxValues = owner.artProfileLastValues;
			owner.artProfileMaxTiles = owner.artProfileLastTiles;
			owner.artProfileMaxSpanX = owner.artProfileLastSpanX;
			owner.artProfileMaxSpanY = owner.artProfileLastSpanY;
		}
	}

	public function updateViewWindows(force:Bool):Void {
		for (tiles in owner.artRasterTileLayers) if (tiles != null) updateViewWindow(tiles, force);
		if (owner.drawnArtItems >= owner.totalArtItems) continueRasterWork();
	}

	private function updateViewWindow(tiles:ArtRasterTiles, force:Bool):Void {
		var rasterCanvas = tiles.rasterCanvas;
		if (rasterCanvas.parent == null) return;
		var toLocal = rasterCanvas.transform.matrix.clone();
		var layerIndex = owner.artLayerContainers.indexOf(Std.downcast(rasterCanvas.parent, Sprite));
		if (layerIndex >= 0 && layerIndex < owner.level.artLayers.length) {
			var layer = owner.level.artLayers[layerIndex];
			toLocal.concat(owner.layerMatrix(
				LevelRenderer.artParallaxOffsetX(owner.rawOffsetX, layer.scale),
				LevelRenderer.artParallaxOffsetY(owner.rawOffsetY, layer.scale)
			));
		} else {
			toLocal.concat(rasterCanvas.parent.transform.matrix);
		}
		toLocal.concat(owner.tweenRotationMatrix(owner.tweenRotation));
		toLocal.invert();
		var minX = Math.POSITIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY;
		var maxY = Math.NEGATIVE_INFINITY;
		var view = owner.viewport;
		for (corner in [view.topLeft, new Point(view.right, view.top), new Point(view.left, view.bottom), view.bottomRight]) {
			var local = toLocal.transformPoint(corner);
			if (local.x < minX) minX = local.x;
			if (local.x > maxX) maxX = local.x;
			if (local.y < minY) minY = local.y;
			if (local.y > maxY) maxY = local.y;
		}
		tiles.setVisibleWorldWindow(minX, maxX, minY, maxY, force);
	}

	private function handleFailure(error:Dynamic):Void {
		if (!owner.artLoadWarningShown) {
			owner.artLoadWarningShown = true;
			emitWarning(owner.artOptions != null && owner.artOptions.editorWarning == true ? LevelRenderer.ART_LOAD_WARNING_EDITOR : LevelRenderer.ART_LOAD_WARNING_GAME, true);
		}
		owner.drawnArtItems = owner.totalArtItems;
		owner.nextArtLayerToDraw = owner.artDrawCursors.length;
		for (tiles in owner.artRasterTileLayers) if (tiles != null) tiles.finishIndexingAfterFailure();
		owner.removeEventListener(Event.ENTER_FRAME, drawBatch);
		continueRasterWork();
	}

	private function continueRasterWork():Void {
		if (hasPendingTiles() && !owner.artRasterWorkActive) {
			owner.artRasterWorkActive = true;
			owner.addEventListener(Event.ENTER_FRAME, onRasterWorkFrame);
		}
	}

	private function onRasterWorkFrame(event:Event):Void {
		if (!pr2.runtime.FrameClock.shouldRunSimulationFrame()) return;
		updateRasterTiles();
		if (!hasPendingTiles()) {
			owner.artRasterWorkActive = false;
			owner.removeEventListener(Event.ENTER_FRAME, onRasterWorkFrame);
		}
	}

	private function updateRasterTiles():Int {
		var frameClock = pr2.runtime.FrameClock.current;
		var frameNumber = frameClock == null ? -1 : frameClock.simulationFrameNumber;
		if (frameNumber < 0 || frameNumber != rasterSaveFrame) {
			rasterSaveFrame = frameNumber;
			rasterSavesStartedThisFrame = 0;
		}
		var remaining = LevelRenderer.ART_RASTER_SAVES_PER_FRAME - rasterSavesStartedThisFrame;
		var started = 0;
		for (tiles in owner.artRasterTileLayers) {
			if (tiles == null) continue;
			var layerStarted = tiles.updateTiles(remaining);
			started += layerStarted;
			remaining -= layerStarted;
		}
		rasterSavesStartedThisFrame += started;
		return started;
	}

	private function hasPendingTiles():Bool {
		for (tiles in owner.artRasterTileLayers) if (tiles != null && tiles.hasPendingTileWork()) return true;
		return false;
	}

	public function isTileBakeComplete():Bool {
		for (tiles in owner.artRasterTileLayers) if (tiles != null && !tiles.isBakeComplete()) return false;
		return true;
	}

	private function emitWarning(message:String, gatePopup:Bool):Void {
		owner.artWarningMessage = message;
		if (owner.artOptions != null && owner.artOptions.onArtWarning != null) {
			owner.artOptions.onArtWarning(message);
			return;
		}
		if (owner.artOptions != null && owner.artOptions.suppressArtWarningPopup == true) return;
		var open = Popup.getOpen();
		if (!gatePopup || open.length == 0 || (open.length == 1 && Std.isOfType(open[0], PrizePopup))) new MessagePopup(message);
	}

	public function notifyRasterStopped():Void {
		owner.stoppedRasterizing = true;
		if (!owner.rasterStopNotified) {
			owner.rasterStopNotified = true;
			emitWarning(LevelRenderer.ART_RASTER_STOP_WARNING, false);
		}
	}

	public function rerasterizeLayers(rasterScale:Float):Void {
		for (index in 0...owner.artRasterTileLayers.length) {
			var oldTiles = owner.artRasterTileLayers[index];
			if (oldTiles == null || index >= owner.level.artLayers.length) continue;
			var oldCanvas = oldTiles.rasterCanvas;
			var container = Std.downcast(oldCanvas.parent, Sprite);
			if (container == null) continue;

			var newCanvas = new Sprite();
			newCanvas.name = LevelRenderer.ART_RASTER_CANVAS_NAME;
			var childIndex = container.getChildIndex(oldCanvas);
			container.addChildAt(newCanvas, childIndex);
			var newTiles = createRasterTiles(newCanvas, index, rasterScale);
			try {
				newTiles.applyAll(owner.level.artLayers[index].drawActions);
				owner.artRasterTileLayers[index] = newTiles;
				updateViewWindow(newTiles, true);
				newTiles.renderHotTilesNow();
				oldTiles.dispose();
				if (oldCanvas.parent != null) oldCanvas.parent.removeChild(oldCanvas);
			} catch (error:Dynamic) {
				newTiles.dispose();
				if (newCanvas.parent != null) newCanvas.parent.removeChild(newCanvas);
				handleFailure(error);
				return;
			}
		}
		continueRasterWork();
	}

	public function dispose():Void {
		owner.removeEventListener(Event.ENTER_FRAME, onRasterWorkFrame);
		owner.artRasterWorkActive = false;
		for (tiles in owner.artRasterTileLayers) if (tiles != null) tiles.dispose();
		owner.artRasterTileLayers.resize(0);
	}
}
