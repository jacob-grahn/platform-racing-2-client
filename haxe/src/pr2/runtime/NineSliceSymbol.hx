package pr2.runtime;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.PixelSnapping;
import openfl.display.Sprite;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import pr2.generated.assets.AssetTypes.SymbolAssetDef;
import pr2.runtime.PR2MovieClip.PR2MovieClipOptions;

/**
	Nine-slice (scale-grid) symbol rendering.

	OpenFL 9.5.2's `scale9Grid` cannot be used here: every PR2 symbol draws its
	geometry into child `Shape`s (`VectorShapeRenderer`), never the clip's own
	`graphics`, and the default HTML5 (WebGL) renderer responds to a non-null
	`__worldScale9Grid` by rasterizing the shape at native pixelRatio scale and
	baking the instance scale back out (`Graphics.__updateRenderTransform`), never
	performing the nine-slice tiling. The net effect is the panel art renders at
	its unscaled size — far too small.

	So nine-slice is implemented here directly: the symbol's content is rasterized
	once to a `BitmapData`, sliced into nine fixed regions by the authored grid,
	and re-tiled to the placement size. Corners keep their natural size while the
	edges and center stretch, matching Flash. The placement scale is consumed as a
	target width/height (`applyPlacementScale`) the same way `fl.controls` consume
	theirs, so the instance matrix carries only translation/rotation.

	Used by the shared `SquareBG` panel behind the login popups, the lobby
	bottom-bar buttons, and the in-game quit / song-selector buttons.
**/
class NineSliceSymbol extends Sprite {
	// Supersample factor for the rasterized source. Corners stay at natural size
	// regardless of placement scale, so this only governs how crisp they (and the
	// thin authored stroke) look once the stage is upscaled to the window/HiDPI.
	private static inline var RASTER_SCALE:Float = 4;

	// Shared sources keyed by symbol so repeated instances (e.g. each login popup's
	// BG) rasterize and slice once for the whole app.
	private static var sourceCache:Map<String, NineSliceSource> = new Map();

	private var source:NineSliceSource;
	private var cells:Array<Bitmap> = [];

	public static function hasGrid(symbol:SymbolAssetDef):Bool {
		return symbol.scaleGridLeft != null
			&& symbol.scaleGridRight != null
			&& symbol.scaleGridTop != null
			&& symbol.scaleGridBottom != null;
	}

	/**
		Builds a nine-slice for `symbol`, or returns null when the grid is
		unusable (degenerate margins, empty bounds) so the caller can fall back to
		a normally-scaled clip.
	**/
	public static function tryCreate(symbol:SymbolAssetDef, ?options:PR2MovieClipOptions, nestedDepth:Int = 0):Null<NineSliceSymbol> {
		if (!hasGrid(symbol)) {
			return null;
		}
		var source = getSource(symbol, options, nestedDepth);
		if (source == null) {
			return null;
		}
		return new NineSliceSymbol(source);
	}

	private function new(source:NineSliceSource) {
		super();
		this.source = source;
		mouseEnabled = false;
		mouseChildren = false;
		for (crop in source.crops) {
			var cell = new Bitmap(crop, PixelSnapping.AUTO, true);
			cells.push(cell);
			addChild(cell);
		}
		applyPlacementScale(1, 1);
	}

	/**
		Lays the nine slices out for a placement scaled by (`scaleX`, `scaleY`).
		Corners keep their natural symbol-space size; edges stretch on one axis and
		the center on both. The laid-out box spans exactly the region a uniform
		scale would have covered, so positioning is unchanged.
	**/
	public function applyPlacementScale(scaleX:Float, scaleY:Float):Void {
		var rects = computeCells(source.boundsX, source.boundsY, source.boundsWidth, source.boundsHeight,
			source.marginLeft, source.marginRight, source.marginTop, source.marginBottom, scaleX, scaleY);
		for (i in 0...9) {
			var cell = cells[i];
			var crop = source.crops[i];
			var rect = rects[i];
			cell.x = rect.x;
			cell.y = rect.y;
			cell.scaleX = crop.width == 0 ? 0 : rect.width / crop.width;
			cell.scaleY = crop.height == 0 ? 0 : rect.height / crop.height;
			cell.smoothing = true;
		}
	}

	public function setTargetSize(width:Float, height:Float):Void {
		var scaleX = source.boundsWidth == 0 ? 1 : width / source.boundsWidth;
		var scaleY = source.boundsHeight == 0 ? 1 : height / source.boundsHeight;
		applyPlacementScale(scaleX, scaleY);
	}

	/**
		Pure nine-slice layout: returns the nine display rects (row-major
		top/middle/bottom × left/center/right) in symbol-local space for a content
		box of `bounds*` scaled by (`scaleX`, `scaleY`). Corners keep their natural
		margin size; the center and edges absorb the remaining length. The box is
		anchored where a uniform scale about the symbol origin would have placed the
		content's top-left, so positioning matches the non-sliced path. Kept pure
		(no rasterization) so the geometry is unit-testable.
	**/
	public static function computeCells(boundsX:Float, boundsY:Float, boundsWidth:Float, boundsHeight:Float, marginLeft:Float, marginRight:Float,
			marginTop:Float, marginBottom:Float, scaleX:Float, scaleY:Float):Array<Rectangle> {
		var sx = Math.abs(scaleX);
		var sy = Math.abs(scaleY);

		var colW = sliceLengths(marginLeft, marginRight, boundsWidth * sx);
		var rowH = sliceLengths(marginTop, marginBottom, boundsHeight * sy);

		var originX = boundsX * sx;
		var originY = boundsY * sy;
		var colX = [originX, originX + colW[0], originX + colW[0] + colW[1]];
		var rowY = [originY, originY + rowH[0], originY + rowH[0] + rowH[1]];

		var rects:Array<Rectangle> = [];
		for (row in 0...3) {
			for (col in 0...3) {
				rects.push(new Rectangle(colX[col], rowY[row], colW[col], rowH[row]));
			}
		}
		return rects;
	}

	// Distributes a target length across [startMargin, stretchCenter, endMargin].
	// The center absorbs the slack; when the margins alone exceed the target they
	// are scaled down together so the slices still fit (center collapses to 0).
	private static function sliceLengths(startMargin:Float, endMargin:Float, target:Float):Array<Float> {
		var margins = startMargin + endMargin;
		if (target >= margins) {
			return [startMargin, target - margins, endMargin];
		}
		var f = margins == 0 ? 0 : target / margins;
		return [startMargin * f, 0, endMargin * f];
	}

	private static function cacheKey(symbol:SymbolAssetDef):String {
		if (symbol.linkageClassName != null) return symbol.linkageClassName;
		if (symbol.name != null) return symbol.name;
		return symbol.href;
	}

	private static function getSource(symbol:SymbolAssetDef, options:PR2MovieClipOptions, nestedDepth:Int):Null<NineSliceSource> {
		var key = cacheKey(symbol);
		if (sourceCache.exists(key)) {
			return sourceCache.get(key);
		}
		var source = buildSource(symbol, options, nestedDepth);
		// Cache successes only; a failed build (null) falls back to a normal clip
		// and is cheap to retry should the symbol ever be requested again.
		if (source != null) {
			sourceCache.set(key, source);
		}
		return source;
	}

	private static function buildSource(symbol:SymbolAssetDef, options:PR2MovieClipOptions, nestedDepth:Int):Null<NineSliceSource> {
		var content = new PR2MovieClip(symbol, options, nestedDepth);
		var bounds = content.getBounds(content);
		if (bounds.width <= 0 || bounds.height <= 0) {
			content.dispose();
			return null;
		}

		// Fixed margins between the content edge and the authored grid, in symbol
		// units. Negative authored grids (a few skins) clamp to zero.
		var marginLeft = Math.max(0, symbol.scaleGridLeft - bounds.x);
		var marginRight = Math.max(0, (bounds.x + bounds.width) - symbol.scaleGridRight);
		var marginTop = Math.max(0, symbol.scaleGridTop - bounds.y);
		var marginBottom = Math.max(0, (bounds.y + bounds.height) - symbol.scaleGridBottom);
		if (marginLeft + marginRight >= bounds.width || marginTop + marginBottom >= bounds.height) {
			content.dispose();
			return null;
		}

		var pixelW = Math.ceil(bounds.width * RASTER_SCALE);
		var pixelH = Math.ceil(bounds.height * RASTER_SCALE);

		var raster = new BitmapData(pixelW, pixelH, true, 0);
		var matrix = new Matrix(RASTER_SCALE, 0, 0, RASTER_SCALE, -bounds.x * RASTER_SCALE, -bounds.y * RASTER_SCALE);
		raster.draw(content, matrix, content.transform.colorTransform, null, null, true);
		content.dispose();

		// Slice column/row pixel sizes. The center must stay at least 1px so the
		// stretched region samples real pixels.
		var left = Math.round(marginLeft * RASTER_SCALE);
		var right = Math.round(marginRight * RASTER_SCALE);
		var top = Math.round(marginTop * RASTER_SCALE);
		var bottom = Math.round(marginBottom * RASTER_SCALE);
		var centerW = pixelW - left - right;
		var centerH = pixelH - top - bottom;
		if (centerW < 1 || centerH < 1) {
			raster.dispose();
			return null;
		}

		var colPx = [left, centerW, right];
		var rowPx = [top, centerH, bottom];
		var colSrcX = [0, left, left + centerW];
		var rowSrcY = [0, top, top + centerH];

		var crops:Array<BitmapData> = [];
		var point = new Point(0, 0);
		for (row in 0...3) {
			for (col in 0...3) {
				var crop = new BitmapData(colPx[col], rowPx[row], true, 0);
				crop.copyPixels(raster, new Rectangle(colSrcX[col], rowSrcY[row], colPx[col], rowPx[row]), point);
				crops.push(crop);
			}
		}
		raster.dispose();

		return {
			crops: crops,
			boundsX: bounds.x,
			boundsY: bounds.y,
			boundsWidth: bounds.width,
			boundsHeight: bounds.height,
			marginLeft: marginLeft,
			marginRight: marginRight,
			marginTop: marginTop,
			marginBottom: marginBottom
		};
	}
}

// Sliced raster shared across instances of one symbol. `crops` is row-major
// (top/middle/bottom × left/center/right); margins and bounds are in symbol units.
private typedef NineSliceSource = {
	var crops:Array<BitmapData>;
	var boundsX:Float;
	var boundsY:Float;
	var boundsWidth:Float;
	var boundsHeight:Float;
	var marginLeft:Float;
	var marginRight:Float;
	var marginTop:Float;
	var marginBottom:Float;
}
