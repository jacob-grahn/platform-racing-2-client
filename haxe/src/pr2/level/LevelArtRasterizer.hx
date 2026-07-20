package pr2.level;

import haxe.Timer;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import pr2.level.Level.LevelDrawAction;

/** Tile-based stroke rasterization, batching, culling, and resource budgeting. */
class ArtStrokeTileSet {
	public final keys:Array<String> = [];
	public final tileXs:Array<Int> = [];
	public final tileYs:Array<Int> = [];
	public final seen:Map<String, Bool> = new Map();
	public var minTileX:Int = 0;
	public var maxTileX:Int = 0;
	public var minTileY:Int = 0;
	public var maxTileY:Int = 0;

	public function new() {}

	public function add(key:String, tileX:Int, tileY:Int):Void {
		if (seen.exists(key)) {
			return;
		}
		seen.set(key, true);
		keys.push(key);
		tileXs.push(tileX);
		tileYs.push(tileY);
		if (keys.length == 1) {
			minTileX = maxTileX = tileX;
			minTileY = maxTileY = tileY;
			return;
		}
		if (tileX < minTileX) minTileX = tileX;
		if (tileX > maxTileX) maxTileX = tileX;
		if (tileY < minTileY) minTileY = tileY;
		if (tileY > maxTileY) maxTileY = tileY;
	}

	public function tileSpanX():Int {
		if (keys.length == 0) {
			return 0;
		}
		return Std.int((maxTileX - minTileX) / LevelRenderer.ART_RASTER_TILE_SIZE) + 1;
	}

	public function tileSpanY():Int {
		if (keys.length == 0) {
			return 0;
		}
		return Std.int((maxTileY - minTileY) / LevelRenderer.ART_RASTER_TILE_SIZE) + 1;
	}
}

class ArtRasterBudget {
	public final limit:Int;
	public var tileCount(default, null):Int = 0;
	public var stopped(default, null):Bool = false;
	private final onStopped:Void->Void;

	public function new(limit:Int, onStopped:Void->Void) {
		this.limit = limit;
		this.onStopped = onStopped;
	}

	public function reserveTile():Bool {
		if (limit < 0) {
			tileCount++;
			return true;
		}
		if (tileCount >= limit) {
			if (!stopped) {
				stopped = true;
				onStopped();
			}
			return false;
		}
		tileCount++;
		return true;
	}
}

class LargeStrokeRasterOperation {
	public final shape:Shape;
	public final strokeTiles:ArtStrokeTileSet;
	public final bounds:Rectangle;
	public final erase:Bool;
	public final profilePath:String;
	public final profileMode:String;
	public var tileIndex:Int = 0;

	public function new(shape:Shape, strokeTiles:ArtStrokeTileSet, bounds:Rectangle, erase:Bool, profilePath:String, profileMode:String) {
		this.shape = shape;
		this.strokeTiles = strokeTiles;
		this.bounds = bounds;
		this.erase = erase;
		this.profilePath = profilePath;
		this.profileMode = profileMode;
	}
}

class ArtRasterTiles {
	public final rasterCanvas:Sprite;
	public var lastProfilePath(default, null):String = "";
	public var lastProfileMode(default, null):String = "";
	public var lastProfileTileCount(default, null):Int = 0;
	public var lastProfileTileSpanX(default, null):Int = 0;
	public var lastProfileTileSpanY(default, null):Int = 0;
	private final budget:Null<ArtRasterBudget>;
	private final tiles:Map<String, Bitmap> = new Map();
	private var attachQueue:Array<String> = [];
	private var attachQueueSeen:Map<String, Bool> = new Map();
	private var pendingShape:Null<Shape>;
	private var pendingErase:Bool = false;
	private var pendingBounds:Null<Rectangle>;
	private var pendingTileKeys:Array<String> = [];
	private var pendingTileKeySeen:Map<String, Bool> = new Map();
	private var pendingTileXs:Array<Int> = [];
	private var pendingTileYs:Array<Int> = [];
	private var pendingMinTileX:Int = 0;
	private var pendingMaxTileX:Int = 0;
	private var pendingMinTileY:Int = 0;
	private var pendingMaxTileY:Int = 0;
	private var pendingLargeStroke:Null<LargeStrokeRasterOperation>;
	private var viewInitialized:Bool = false;
	private var viewMinTileX:Int = 0;
	private var viewMaxTileX:Int = 0;
	private var viewMinTileY:Int = 0;
	private var viewMaxTileY:Int = 0;
	private var color:Int = 0x000000;
	private var size:Float = LevelRenderer.DEFAULT_ART_BRUSH_SIZE;
	private var mode:String = "draw";

	public function new(rasterCanvas:Sprite, ?budget:ArtRasterBudget) {
		this.rasterCanvas = rasterCanvas;
		this.budget = budget;
	}

	public function applyAll(actions:Array<LevelDrawAction>):Void {
		for (action in actions) {
			while (!apply(action, true)) {}
		}
		flush();
	}

	public function apply(action:LevelDrawAction, batch:Bool = false, ?deadline:Null<Float>):Bool {
		if (pendingLargeStroke != null) {
			return continueLargeStroke(deadline);
		}
		switch (action.kind) {
			case "c":
				color = Std.int(action.values[0]);
				setControlProfile("color");
			case "t":
				size = action.values[0];
				setControlProfile("size");
			case "m":
				if (batch && mode != action.text) {
					flush();
				}
				mode = action.text;
				setControlProfile("mode");
			case "d":
				if (action.values.length >= 2) {
					var complete = mode == "erase" ? addEraseStrokeToBatch(action, deadline) : addDrawStrokeToBatch(action, deadline);
					if (!batch && complete && !hasPendingRasterWork()) {
						flush();
					}
					return complete;
				}
			default:
				setControlProfile("unknown");
		}
		return true;
	}

	public function flush():Void {
		if (pendingShape == null) {
			setControlProfile("flush");
			return;
		}
		setPendingFlushProfile(pendingErase ? "eraseFlush" : "flush");
		var shape = pendingShape;
		var matrix = new Matrix();
		if (pendingErase) {
			flushEraseShape(shape, matrix);
		} else {
			for (i in 0...pendingTileKeys.length) {
				var bitmap = getOrCreateTile(pendingTileXs[i], pendingTileYs[i]);
				if (bitmap == null) {
					continue;
				}
				matrix.identity();
				matrix.translate(-pendingTileXs[i], -pendingTileYs[i]);
				bitmap.bitmapData.draw(shape, matrix, null, null, null, true);
				queueTileAttach(pendingTileKeys[i]);
			}
		}
		resetPendingBatch();
	}

	private function flushEraseShape(shape:Shape, matrix:Matrix):Void {
		if (pendingBounds == null) {
			return;
		}
		var tileSize = LevelRenderer.ART_RASTER_TILE_SIZE + 1;
		for (i in 0...pendingTileKeys.length) {
			var bitmap = tiles.get(pendingTileKeys[i]);
			if (bitmap == null) {
				continue;
			}
			var tileX = pendingTileXs[i];
			var tileY = pendingTileYs[i];
			var rectX = Std.int(Math.max(0, Math.floor(pendingBounds.x - tileX)));
			var rectY = Std.int(Math.max(0, Math.floor(pendingBounds.y - tileY)));
			var rectRight = Std.int(Math.min(tileSize, Math.ceil(pendingBounds.right - tileX)));
			var rectBottom = Std.int(Math.min(tileSize, Math.ceil(pendingBounds.bottom - tileY)));
			if (rectRight <= rectX || rectBottom <= rectY) {
				continue;
			}
			var targetRect = new Rectangle(rectX, rectY, rectRight - rectX, rectBottom - rectY);
			var mask = new BitmapData(Std.int(targetRect.width), Std.int(targetRect.height), true, 0);
			matrix.identity();
			matrix.translate(-(tileX + rectX), -(tileY + rectY));
			mask.draw(shape, matrix, null, null, null, true);
			clearMaskedPixels(bitmap.bitmapData, targetRect, mask);
			mask.dispose();
			queueTileAttach(pendingTileKeys[i]);
		}
	}

	private function resetPendingBatch():Void {
		pendingShape = null;
		pendingErase = false;
		pendingBounds = null;
		pendingTileKeys = [];
		pendingTileKeySeen = new Map();
		pendingTileXs = [];
		pendingTileYs = [];
		pendingMinTileX = pendingMaxTileX = pendingMinTileY = pendingMaxTileY = 0;
	}

	public function setVisibleTileWindow(minTileX:Int, maxTileX:Int, minTileY:Int, maxTileY:Int, force:Bool):Void {
		var threshold = LevelRenderer.ART_RASTER_VIEW_REBUILD_THRESHOLD * LevelRenderer.ART_RASTER_TILE_SIZE;
		if (!force
			&& viewInitialized
			&& intAbs(minTileX - viewMinTileX) <= threshold
			&& intAbs(maxTileX - viewMaxTileX) <= threshold
			&& intAbs(minTileY - viewMinTileY) <= threshold
			&& intAbs(maxTileY - viewMaxTileY) <= threshold) {
			return;
		}
		viewMinTileX = minTileX;
		viewMaxTileX = maxTileX;
		viewMinTileY = minTileY;
		viewMaxTileY = maxTileY;
		viewInitialized = true;
		for (key in tiles.keys()) {
			var bitmap = tiles.get(key);
			if (bitmap == null) {
				continue;
			}
			if (isTileVisible(Std.int(bitmap.x), Std.int(bitmap.y))) {
				queueTileAttach(key);
			} else {
				setTileAttached(bitmap, false);
			}
		}
	}

	public function attachQueuedTiles(limit:Int):Int {
		if (limit <= 0 || attachQueue.length == 0) {
			return 0;
		}
		var attached = 0;
		var remainingKeys:Array<String> = [];
		var remainingSeen:Map<String, Bool> = new Map();
		for (key in attachQueue) {
			var bitmap = tiles.get(key);
			if (bitmap == null) {
				continue;
			}
			if (!isTileVisible(Std.int(bitmap.x), Std.int(bitmap.y))) {
				setTileAttached(bitmap, false);
				continue;
			}
			if (bitmap.parent == rasterCanvas) {
				continue;
			}
			if (attached < limit) {
				setTileAttached(bitmap, true);
				attached++;
			} else if (!remainingSeen.exists(key)) {
				remainingSeen.set(key, true);
				remainingKeys.push(key);
			}
		}
		attachQueue = remainingKeys;
		attachQueueSeen = remainingSeen;
		return attached;
	}

	public function hasQueuedVisibleTiles():Bool {
		for (key in attachQueue) {
			var bitmap = tiles.get(key);
			if (bitmap != null && bitmap.parent != rasterCanvas && isTileVisible(Std.int(bitmap.x), Std.int(bitmap.y))) {
				return true;
			}
		}
		return false;
	}

	public function hasPendingRasterWork():Bool {
		return pendingLargeStroke != null;
	}

	private function getOrCreateTile(tileX:Int, tileY:Int):Null<Bitmap> {
		var key = tileKey(tileX, tileY);
		var bitmap = tiles.get(key);
		if (bitmap != null) {
			return bitmap;
		}
		if (budget != null && !budget.reserveTile()) {
			return null;
		}
		bitmap = new Bitmap(new BitmapData(LevelRenderer.ART_RASTER_TILE_SIZE + 1, LevelRenderer.ART_RASTER_TILE_SIZE + 1, true, 0));
		bitmap.smoothing = true;
		bitmap.x = tileX;
		bitmap.y = tileY;
		tiles.set(key, bitmap);
		queueTileAttach(key);
		return bitmap;
	}

	private function isTileVisible(tileX:Int, tileY:Int):Bool {
		return !viewInitialized || (tileX >= viewMinTileX && tileX <= viewMaxTileX && tileY >= viewMinTileY && tileY <= viewMaxTileY);
	}

	private function setTileAttached(bitmap:Bitmap, attach:Bool):Void {
		if (attach) {
			if (bitmap.parent != rasterCanvas) {
				rasterCanvas.addChild(bitmap);
			}
		} else if (bitmap.parent == rasterCanvas) {
			rasterCanvas.removeChild(bitmap);
		}
	}

	private function queueTileAttach(key:String):Void {
		if (attachQueueSeen.exists(key)) {
			return;
		}
		var bitmap = tiles.get(key);
		if (bitmap == null || bitmap.parent == rasterCanvas || !isTileVisible(Std.int(bitmap.x), Std.int(bitmap.y))) {
			return;
		}
		attachQueueSeen.set(key, true);
		attachQueue.push(key);
	}

	private static inline function intAbs(value:Int):Int {
		return value < 0 ? -value : value;
	}

	private function startLargeStroke(action:LevelDrawAction, erase:Bool, profilePath:String, ?deadline:Null<Float>):Bool {
		flush();
		var radius = Math.max(0.5, size / 2);
		var strokeTiles = collectStrokeTilesForErase(action, radius);
		if (strokeTiles.keys.length == 0) {
			setEstimatedStrokeProfile(action, profilePath);
			return true;
		}
		var shape = strokeShape(action, erase ? 0xFFFFFF : color);
		var bounds = strokeBounds(action, radius);
		pendingLargeStroke = new LargeStrokeRasterOperation(shape, strokeTiles, bounds, erase, profilePath, mode);
		return continueLargeStroke(deadline);
	}

	private function continueLargeStroke(?deadline:Null<Float>):Bool {
		var op = pendingLargeStroke;
		if (op == null) {
			return true;
		}
		setLargeStrokeProfile(op);
		var matrix = new Matrix();
		var processed = 0;
		while (op.tileIndex < op.strokeTiles.keys.length && (processed == 0 || deadline == null || Timer.stamp() < deadline)) {
			if (op.erase) {
				eraseLargeStrokeTile(op, matrix);
			} else {
				drawLargeStrokeTile(op, matrix);
			}
			op.tileIndex++;
			processed++;
		}
		if (op.tileIndex >= op.strokeTiles.keys.length) {
			pendingLargeStroke = null;
			return true;
		}
		return false;
	}

	private function drawLargeStrokeTile(op:LargeStrokeRasterOperation, matrix:Matrix):Void {
		var tileX = op.strokeTiles.tileXs[op.tileIndex];
		var tileY = op.strokeTiles.tileYs[op.tileIndex];
		var bitmap = getOrCreateTile(tileX, tileY);
		if (bitmap == null) {
			return;
		}
		matrix.identity();
		matrix.translate(-tileX, -tileY);
		bitmap.bitmapData.draw(op.shape, matrix, null, null, null, true);
		queueTileAttach(op.strokeTiles.keys[op.tileIndex]);
	}

	private function eraseLargeStrokeTile(op:LargeStrokeRasterOperation, matrix:Matrix):Void {
		var key = op.strokeTiles.keys[op.tileIndex];
		var bitmap = tiles.get(key);
		if (bitmap == null) {
			return;
		}
		var tileX = op.strokeTiles.tileXs[op.tileIndex];
		var tileY = op.strokeTiles.tileYs[op.tileIndex];
		var tileSize = LevelRenderer.ART_RASTER_TILE_SIZE + 1;
		var rectX = Std.int(Math.max(0, Math.floor(op.bounds.x - tileX)));
		var rectY = Std.int(Math.max(0, Math.floor(op.bounds.y - tileY)));
		var rectRight = Std.int(Math.min(tileSize, Math.ceil(op.bounds.right - tileX)));
		var rectBottom = Std.int(Math.min(tileSize, Math.ceil(op.bounds.bottom - tileY)));
		if (rectRight <= rectX || rectBottom <= rectY) {
			return;
		}
		var targetRect = new Rectangle(rectX, rectY, rectRight - rectX, rectBottom - rectY);
		var mask = new BitmapData(Std.int(targetRect.width), Std.int(targetRect.height), true, 0);
		matrix.identity();
		matrix.translate(-(tileX + rectX), -(tileY + rectY));
		mask.draw(op.shape, matrix, null, null, null, true);
		clearMaskedPixels(bitmap.bitmapData, targetRect, mask);
		mask.dispose();
		queueTileAttach(key);
	}

	private function clearMaskedPixels(target:BitmapData, targetRect:Rectangle, mask:BitmapData):Void {
		var maskPixels = mask.getPixels(mask.rect);
		if (maskPixels == null) {
			return;
		}
		var width = Std.int(targetRect.width);
		var height = Std.int(targetRect.height);
		var targetX = Std.int(targetRect.x);
		var targetY = Std.int(targetRect.y);
		maskPixels.position = 0;
		target.lock();
		for (y in 0...height) {
			for (x in 0...width) {
				if (maskPixels.readUnsignedInt() != 0) {
					target.setPixel32(targetX + x, targetY + y, 0);
				}
			}
		}
		target.unlock(targetRect);
	}

	private function strokeShape(action:LevelDrawAction, strokeColor:Int):Shape {
		var shape = new Shape();
		var graphics = shape.graphics;
		graphics.lineStyle(size, strokeColor);
		var x = action.values[0];
		var y = action.values[1];
		graphics.moveTo(x, y);
		graphics.lineTo(x - 0.15, y);
		graphics.moveTo(x, y);
		var i = 2;
		while (i + 1 < action.values.length) {
			var nextX = x + action.values[i];
			var nextY = y + action.values[i + 1];
			graphics.lineTo(nextX, nextY);
			x = nextX;
			y = nextY;
			i += 2;
		}
		return shape;
	}

	private function strokeBounds(action:LevelDrawAction, radius:Float):Rectangle {
		var x = action.values[0];
		var y = action.values[1];
		var minX = x - radius - 1;
		var minY = y - radius - 1;
		var maxX = x + radius + 1;
		var maxY = y + radius + 1;
		var i = 2;
		while (i + 1 < action.values.length) {
			x += action.values[i];
			y += action.values[i + 1];
			minX = Math.min(minX, x - radius - 1);
			minY = Math.min(minY, y - radius - 1);
			maxX = Math.max(maxX, x + radius + 1);
			maxY = Math.max(maxY, y + radius + 1);
			i += 2;
		}
		return new Rectangle(minX, minY, maxX - minX, maxY - minY);
	}

	private function addDrawStrokeToBatch(action:LevelDrawAction, ?deadline:Null<Float>):Bool {
		var radius = Math.max(0.5, size / 2);
		var strokeTiles = collectStrokeTiles(action, radius);
		if (strokeTiles == null) {
			flush();
			return startLargeStroke(action, false, "tileFallback", deadline);
		}
		if (pendingShape != null && pendingErase) {
			flush();
		}
		if (!canAddStrokeTilesToBatch(strokeTiles)) {
			flush();
		}
		if (!canAddStrokeTilesToBatch(strokeTiles)) {
			return startLargeStroke(action, false, "tileFallback", deadline);
		}
		setStrokeTileProfile(strokeTiles, "batch");
		if (pendingShape == null) {
			pendingShape = new Shape();
			pendingErase = false;
		}
		var graphics = pendingShape.graphics;
		graphics.lineStyle(size, color);
		appendStrokeToGraphics(graphics, action);
		addPendingStrokeTiles(strokeTiles);
		return true;
	}

	private function addEraseStrokeToBatch(action:LevelDrawAction, ?deadline:Null<Float>):Bool {
		var radius = Math.max(0.5, size / 2);
		var strokeTiles = collectStrokeTiles(action, radius);
		if (strokeTiles == null) {
			flush();
			return startLargeStroke(action, true, "eraseTileFallback", deadline);
		}
		if (pendingShape != null && !pendingErase) {
			flush();
		}
		if (!canAddStrokeTilesToBatch(strokeTiles)) {
			flush();
		}
		if (!canAddStrokeTilesToBatch(strokeTiles)) {
			return startLargeStroke(action, true, "eraseTileFallback", deadline);
		}
		setStrokeTileProfile(strokeTiles, "eraseBatch");
		if (pendingShape == null) {
			pendingShape = new Shape();
			pendingErase = true;
		}
		var graphics = pendingShape.graphics;
		graphics.lineStyle(size, 0xFFFFFF);
		appendStrokeToGraphics(graphics, action);
		addPendingStrokeTiles(strokeTiles);
		addPendingBounds(strokeBounds(action, radius));
		return true;
	}

	private function appendStrokeToGraphics(graphics:openfl.display.Graphics, action:LevelDrawAction):Void {
		var x = action.values[0];
		var y = action.values[1];
		graphics.moveTo(x, y);
		graphics.lineTo(x - 0.15, y);
		graphics.moveTo(x, y);
		var i = 2;
		while (i + 1 < action.values.length) {
			var nextX = x + action.values[i];
			var nextY = y + action.values[i + 1];
			graphics.lineTo(nextX, nextY);
			x = nextX;
			y = nextY;
			i += 2;
		}
	}

	private function collectStrokeTiles(action:LevelDrawAction, radius:Float):Null<ArtStrokeTileSet> {
		var tiles = new ArtStrokeTileSet();
		var x = action.values[0];
		var y = action.values[1];
		addTilesForBounds(tiles, x - radius - 1, y - radius - 1, x + radius + 1, y + radius + 1);
		if (!isStrokeTileSetBatchable(tiles)) {
			return null;
		}
		var i = 2;
		while (i + 1 < action.values.length) {
			var nextX = x + action.values[i];
			var nextY = y + action.values[i + 1];
			addTilesForBounds(tiles,
				Math.min(x, nextX) - radius - 1,
				Math.min(y, nextY) - radius - 1,
				Math.max(x, nextX) + radius + 1,
				Math.max(y, nextY) + radius + 1
			);
			if (!isStrokeTileSetBatchable(tiles)) {
				return null;
			}
			x = nextX;
			y = nextY;
			i += 2;
		}
		return tiles;
	}

	private function collectStrokeTilesForErase(action:LevelDrawAction, radius:Float):ArtStrokeTileSet {
		var tiles = new ArtStrokeTileSet();
		var x = action.values[0];
		var y = action.values[1];
		addTilesForBounds(tiles, x - radius - 1, y - radius - 1, x + radius + 1, y + radius + 1);
		var i = 2;
		while (i + 1 < action.values.length) {
			var nextX = x + action.values[i];
			var nextY = y + action.values[i + 1];
			addTilesForBounds(tiles,
				Math.min(x, nextX) - radius - 1,
				Math.min(y, nextY) - radius - 1,
				Math.max(x, nextX) + radius + 1,
				Math.max(y, nextY) + radius + 1
			);
			x = nextX;
			y = nextY;
			i += 2;
		}
		return tiles;
	}

	private function addTilesForBounds(tiles:ArtStrokeTileSet, minX:Float, minY:Float, maxX:Float, maxY:Float):Void {
		var tile = LevelRenderer.ART_RASTER_TILE_SIZE;
		var tileY = tileOrigin(Std.int(Math.floor(minY)));
		var endY = tileOrigin(Std.int(Math.floor(maxY)));
		while (tileY <= endY) {
			var tileX = tileOrigin(Std.int(Math.floor(minX)));
			var endX = tileOrigin(Std.int(Math.floor(maxX)));
			while (tileX <= endX) {
				var key = tileKey(tileX, tileY);
				tiles.add(key, tileX, tileY);
				tileX += tile;
			}
			tileY += tile;
		}
	}

	private function isStrokeTileSetBatchable(tiles:ArtStrokeTileSet):Bool {
		return LevelRenderer.isArtDrawBatchWithinLimits(tiles.keys.length, tiles.tileSpanX(), tiles.tileSpanY());
	}

	private function canAddStrokeTilesToBatch(strokeTiles:ArtStrokeTileSet):Bool {
		var count = pendingTileKeys.length;
		var minTileX = pendingMinTileX;
		var maxTileX = pendingMaxTileX;
		var minTileY = pendingMinTileY;
		var maxTileY = pendingMaxTileY;
		if (pendingShape == null) {
			count = 0;
			minTileX = strokeTiles.minTileX;
			maxTileX = strokeTiles.maxTileX;
			minTileY = strokeTiles.minTileY;
			maxTileY = strokeTiles.maxTileY;
		}
		for (i in 0...strokeTiles.keys.length) {
			var key = strokeTiles.keys[i];
			var tileX = strokeTiles.tileXs[i];
			var tileY = strokeTiles.tileYs[i];
			if (!pendingTileKeySeen.exists(key)) {
				count++;
			}
			if (tileX < minTileX) minTileX = tileX;
			if (tileX > maxTileX) maxTileX = tileX;
			if (tileY < minTileY) minTileY = tileY;
			if (tileY > maxTileY) maxTileY = tileY;
		}
		var tile = LevelRenderer.ART_RASTER_TILE_SIZE;
		return LevelRenderer.isArtDrawBatchWithinLimits(
			count,
			Std.int((maxTileX - minTileX) / tile) + 1,
			Std.int((maxTileY - minTileY) / tile) + 1
		);
	}

	private function addPendingStrokeTiles(strokeTiles:ArtStrokeTileSet):Void {
		for (i in 0...strokeTiles.keys.length) {
			var key = strokeTiles.keys[i];
			if (!pendingTileKeySeen.exists(key)) {
				var tileX = strokeTiles.tileXs[i];
				var tileY = strokeTiles.tileYs[i];
				pendingTileKeySeen.set(key, true);
				pendingTileKeys.push(key);
				pendingTileXs.push(tileX);
				pendingTileYs.push(tileY);
				if (pendingTileKeys.length == 1) {
					pendingMinTileX = pendingMaxTileX = tileX;
					pendingMinTileY = pendingMaxTileY = tileY;
				} else {
					if (tileX < pendingMinTileX) pendingMinTileX = tileX;
					if (tileX > pendingMaxTileX) pendingMaxTileX = tileX;
					if (tileY < pendingMinTileY) pendingMinTileY = tileY;
					if (tileY > pendingMaxTileY) pendingMaxTileY = tileY;
				}
			}
		}
	}

	private function addPendingBounds(bounds:Rectangle):Void {
		if (pendingBounds == null) {
			pendingBounds = bounds;
			return;
		}
		var minX = Math.min(pendingBounds.x, bounds.x);
		var minY = Math.min(pendingBounds.y, bounds.y);
		var maxX = Math.max(pendingBounds.right, bounds.right);
		var maxY = Math.max(pendingBounds.bottom, bounds.bottom);
		pendingBounds.setTo(minX, minY, maxX - minX, maxY - minY);
	}

	private function setControlProfile(path:String):Void {
		lastProfilePath = path;
		lastProfileMode = mode;
		lastProfileTileCount = 0;
		lastProfileTileSpanX = 0;
		lastProfileTileSpanY = 0;
	}

	private function setStrokeTileProfile(strokeTiles:ArtStrokeTileSet, path:String):Void {
		lastProfilePath = path;
		lastProfileMode = mode;
		lastProfileTileCount = strokeTiles.keys.length;
		lastProfileTileSpanX = strokeTiles.tileSpanX();
		lastProfileTileSpanY = strokeTiles.tileSpanY();
	}

	private function setEstimatedStrokeProfile(action:LevelDrawAction, path:String):Void {
		var bounds = strokeBounds(action, Math.max(0.5, size / 2));
		var minTileX = tileOrigin(Std.int(Math.floor(bounds.x)));
		var maxTileX = tileOrigin(Std.int(Math.floor(bounds.right)));
		var minTileY = tileOrigin(Std.int(Math.floor(bounds.y)));
		var maxTileY = tileOrigin(Std.int(Math.floor(bounds.bottom)));
		var tile = LevelRenderer.ART_RASTER_TILE_SIZE;
		lastProfilePath = path;
		lastProfileMode = mode;
		lastProfileTileSpanX = Std.int((maxTileX - minTileX) / tile) + 1;
		lastProfileTileSpanY = Std.int((maxTileY - minTileY) / tile) + 1;
		lastProfileTileCount = lastProfileTileSpanX * lastProfileTileSpanY;
	}

	private function setLargeStrokeProfile(op:LargeStrokeRasterOperation):Void {
		lastProfilePath = op.profilePath;
		lastProfileMode = op.profileMode;
		lastProfileTileCount = op.strokeTiles.keys.length;
		lastProfileTileSpanX = op.strokeTiles.tileSpanX();
		lastProfileTileSpanY = op.strokeTiles.tileSpanY();
	}

	private function setPendingFlushProfile(path:String):Void {
		lastProfilePath = path;
		lastProfileMode = mode;
		lastProfileTileCount = pendingTileKeys.length;
		if (pendingTileKeys.length == 0) {
			lastProfileTileSpanX = 0;
			lastProfileTileSpanY = 0;
			return;
		}
		var tile = LevelRenderer.ART_RASTER_TILE_SIZE;
		lastProfileTileSpanX = Std.int((pendingMaxTileX - pendingMinTileX) / tile) + 1;
		lastProfileTileSpanY = Std.int((pendingMaxTileY - pendingMinTileY) / tile) + 1;
	}

	private static inline function tileOrigin(pixel:Int):Int {
		var tile = LevelRenderer.ART_RASTER_TILE_SIZE;
		return Std.int(Math.floor(pixel / tile)) * tile;
	}

	private static inline function tileKey(tileX:Int, tileY:Int):String {
		return tileX + "," + tileY;
	}
}
