package pr2.level;

import haxe.Timer;
import openfl.display.Sprite;
import openfl.geom.Point;
import pr2.Constants;
import pr2.level.Level.LevelBlock;

/** Maintains block sprites and the camera-window display-list culling grid. */
@:access(pr2.level.LevelRenderer)
class BlockDisplayCulling {
	private final owner:LevelRenderer;

	public function new(owner:LevelRenderer) this.owner = owner;

	public function drawNext(limit:Int, ?deadline:Null<Float>):Void {
		var end = Std.int(Math.min(owner.level.blocks.length, owner.nextBlockToDraw + limit));
		var drawn = 0;
		while (owner.nextBlockToDraw < end) {
			if (deadline != null && drawn > 0 && Timer.stamp() >= deadline) break;
			add(owner.level.blocks[owner.nextBlockToDraw++]);
			drawn++;
		}
	}

	public function add(block:LevelBlock):Void {
		if (LevelAssetCatalog.isSpawnMarkerBlockCode(block.code)) return;
		var display = owner.createBlockDisplay(block);
		owner.addBlockDisplayToStack(block, display, block.worldX, block.worldY);
	}

	public function addToGrid(worldX:Int, worldY:Int, display:Sprite):Void {
		var segX = segmentOf(worldX);
		var segY = segmentOf(worldY);
		var col = owner.blockGrid.get(segX);
		if (col == null) {
			col = new Map();
			owner.blockGrid.set(segX, col);
		}
		col.set(segY, display);
	}

	public function removeFromGrid(worldX:Int, worldY:Int):Void {
		var col = owner.blockGrid.get(segmentOf(worldX));
		if (col != null) col.remove(segmentOf(worldY));
	}

	public static inline function segmentOf(coord:Int):Int return Math.round(coord / LevelRenderer.TILE_SIZE);

	public inline function isInView(segX:Int, segY:Int):Bool {
		return owner.viewInitialized && segX >= owner.viewColMin && segX <= owner.viewColMax && segY >= owner.viewRowMin && segY <= owner.viewRowMax;
	}

	public function updateViewWindow(force:Bool):Void {
		// Culling is authoritative 30 Hz work. Never derive its bounds from the
		// disposable fractional matrix currently displayed between ticks.
		var toLocal = owner.layerMatrix(owner.offsetX, owner.offsetY);
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
		var colMin = Math.floor(minX / LevelRenderer.TILE_SIZE) - LevelRenderer.VIEW_MARGIN_SEGMENTS;
		var colMax = Math.ceil(maxX / LevelRenderer.TILE_SIZE) + LevelRenderer.VIEW_MARGIN_SEGMENTS;
		var rowMin = Math.floor(minY / LevelRenderer.TILE_SIZE) - LevelRenderer.VIEW_MARGIN_SEGMENTS;
		var rowMax = Math.ceil(maxY / LevelRenderer.TILE_SIZE) + LevelRenderer.VIEW_MARGIN_SEGMENTS;
		if (!force && owner.viewInitialized && abs(colMin - owner.viewColMin) <= LevelRenderer.VIEW_REBUILD_THRESHOLD
			&& abs(colMax - owner.viewColMax) <= LevelRenderer.VIEW_REBUILD_THRESHOLD && abs(rowMin - owner.viewRowMin) <= LevelRenderer.VIEW_REBUILD_THRESHOLD
			&& abs(rowMax - owner.viewRowMax) <= LevelRenderer.VIEW_REBUILD_THRESHOLD) return;
		if (owner.viewInitialized) {
			for (segX in owner.viewColMin...owner.viewColMax + 1) for (segY in owner.viewRowMin...owner.viewRowMax + 1) {
				if (segX < colMin || segX > colMax || segY < rowMin || segY > rowMax) setAttached(segX, segY, false);
			}
		}
		for (segX in colMin...colMax + 1) for (segY in rowMin...rowMax + 1) {
			if (!owner.viewInitialized || segX < owner.viewColMin || segX > owner.viewColMax || segY < owner.viewRowMin || segY > owner.viewRowMax) setAttached(segX, segY, true);
		}
		owner.viewColMin = colMin;
		owner.viewColMax = colMax;
		owner.viewRowMin = rowMin;
		owner.viewRowMax = rowMax;
		owner.viewInitialized = true;
	}

	private function setAttached(segX:Int, segY:Int, attach:Bool):Void {
		var col = owner.blockGrid.get(segX);
		var display = col == null ? null : col.get(segY);
		if (display == null) return;
		if (attach && display.parent != owner.blockLayer) owner.blockLayer.addChild(display);
		else if (!attach && display.parent == owner.blockLayer) owner.blockLayer.removeChild(display);
	}

	private static inline function abs(value:Int):Int return value < 0 ? -value : value;
}
