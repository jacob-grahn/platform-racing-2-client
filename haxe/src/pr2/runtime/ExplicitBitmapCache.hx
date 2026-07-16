package pr2.runtime;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.PixelSnapping;
import openfl.geom.Matrix;

typedef ExplicitBitmapCacheOptions = {
	@:optional var scale:Float;
	@:optional var padding:Int;
	@:optional var smoothing:Bool;
	@:optional var pixelSnapping:PixelSnapping;
	@:optional var bitmapName:String;
}

private typedef CachedChildVisibility = {
	var child:DisplayObject;
	var visible:Bool;
}

/**
	Rasterizes a display-list subtree in its own local coordinate system while
	leaving the cached container's authored transform and registration point
	untouched. Call `invalidate()` before changing the source subtree, then
	`refresh()` after the update. `dispose()` restores the source children.
**/
class ExplicitBitmapCache {
	public static inline var DEFAULT_BITMAP_NAME:String = "__explicitBitmapCache";

	public final target:DisplayObjectContainer;
	public var bitmap(default, null):Null<Bitmap>;
	public var valid(default, null):Bool = false;

	private final scale:Float;
	private final padding:Int;
	private final smoothing:Bool;
	private final pixelSnapping:PixelSnapping;
	private final bitmapName:String;
	private final originalCacheAsBitmap:Bool;
	private final originalCacheAsBitmapMatrix:Null<Matrix>;
	private var sourceVisibility:Array<CachedChildVisibility> = [];

	public static function attach(target:DisplayObjectContainer, ?options:ExplicitBitmapCacheOptions):ExplicitBitmapCache {
		var cache = new ExplicitBitmapCache(target, options);
		cache.refresh();
		return cache;
	}

	public function new(target:DisplayObjectContainer, ?options:ExplicitBitmapCacheOptions) {
		if (target == null) {
			throw "ExplicitBitmapCache requires a target";
		}
		this.target = target;
		originalCacheAsBitmap = target.cacheAsBitmap;
		originalCacheAsBitmapMatrix = target.cacheAsBitmapMatrix == null ? null : target.cacheAsBitmapMatrix.clone();
		var requestedScale = options != null && options.scale != null ? options.scale : 1.0;
		if (requestedScale <= 0) {
			throw "ExplicitBitmapCache scale must be greater than zero";
		}
		scale = requestedScale;
		padding = options != null && options.padding != null ? Std.int(Math.max(0, options.padding)) : 0;
		smoothing = options == null || options.smoothing == null ? true : options.smoothing;
		pixelSnapping = options != null && options.pixelSnapping != null ? options.pixelSnapping : PixelSnapping.NEVER;
		bitmapName = options != null && options.bitmapName != null ? options.bitmapName : DEFAULT_BITMAP_NAME;
	}

	/** Restore the source subtree so callers can safely modify it. */
	public function invalidate():Void {
		restoreSource();
		valid = false;
	}

	/** Rebuild the bitmap if invalid. Returns false for an empty target. */
	public function refresh():Bool {
		if (valid && bitmap != null && bitmap.parent == target) {
			return true;
		}
		restoreSource();

		target.cacheAsBitmap = false;
		target.cacheAsBitmapMatrix = null;
		var authoredTransform = target.transform.matrix.clone();
		var bounds = target.getBounds(target);
		if (bounds.width <= 0 || bounds.height <= 0) {
			target.transform.matrix = authoredTransform;
			return false;
		}

		var pixelWidth = Std.int(Math.ceil(bounds.width * scale)) + padding * 2;
		var pixelHeight = Std.int(Math.ceil(bounds.height * scale)) + padding * 2;
		var bitmapData = new BitmapData(pixelWidth, pixelHeight, true, 0);
		var drawMatrix = new Matrix(
			scale,
			0,
			0,
			scale,
			-bounds.x * scale + padding,
			-bounds.y * scale + padding
		);
		bitmapData.draw(target, drawMatrix, null, null, null, true);

		var rendered = new Bitmap(bitmapData, pixelSnapping, smoothing);
		rendered.name = bitmapName;
		rendered.scaleX = rendered.scaleY = 1 / scale;
		rendered.x = bounds.x - padding / scale;
		rendered.y = bounds.y - padding / scale;

		sourceVisibility = [];
		for (index in 0...target.numChildren) {
			var child = target.getChildAt(index);
			sourceVisibility.push({child: child, visible: child.visible});
			child.visible = false;
		}
		target.addChild(rendered);
		target.transform.matrix = authoredTransform;
		bitmap = rendered;
		valid = true;
		return true;
	}

	/** Release the bitmap and restore every source child's original visibility. */
	public function dispose():Void {
		restoreSource();
		target.cacheAsBitmap = originalCacheAsBitmap;
		target.cacheAsBitmapMatrix = originalCacheAsBitmapMatrix == null ? null : originalCacheAsBitmapMatrix.clone();
		valid = false;
	}

	private function restoreSource():Void {
		var rendered = bitmap;
		if (rendered != null) {
			if (rendered.parent == target) {
				target.removeChild(rendered);
			}
			if (rendered.bitmapData != null) {
				rendered.bitmapData.dispose();
			}
			bitmap = null;
		}
		for (entry in sourceVisibility) {
			if (entry.child.parent == target) {
				entry.child.visible = entry.visible;
			}
		}
		sourceVisibility = [];
	}
}
