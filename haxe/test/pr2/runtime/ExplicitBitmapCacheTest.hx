package pr2.runtime;

import openfl.display.Shape;
import openfl.display.Sprite;

class ExplicitBitmapCacheTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testCachePreservesLocalRegistrationAndTransform();
		testInvalidateRefreshAndDisposeRestoreSource();
		testSharedBitmapAndPreservedChildren();
		testEmptyTargetAndInvalidScale();
		trace('ExplicitBitmapCacheTest passed $assertions assertions');
	}

	private static function testCachePreservesLocalRegistrationAndTransform():Void {
		var target = new Sprite();
		target.x = 12.25;
		target.y = -7.5;
		target.scaleX = 1.2;
		target.scaleY = 0.8;
		target.rotation = 17;
		var authored = target.transform.matrix.clone();

		var art = rectangle(-10, -6, 25, 18);
		target.addChild(art);
		var cache = ExplicitBitmapCache.attach(target, {scale: 0.5, padding: 2, bitmapName: "testCache"});

		assertTrue(cache.valid, "non-empty target is cached");
		assertTrue(cache.bitmap != null, "cache exposes its rendered bitmap");
		assertEquals("testCache", cache.bitmap.name, "cache applies the requested bitmap name");
		assertTrue(!art.visible, "source child is hidden while cached");
		assertClose(-14, cache.bitmap.x, "bitmap x retains negative local bounds and padding");
		assertClose(-10, cache.bitmap.y, "bitmap y retains negative local bounds and padding");
		assertMatrix(authored, target.transform.matrix, "cache preserves the target transform");
		assertTrue(!target.cacheAsBitmap, "explicit cache disables native cacheAsBitmap");
		assertEquals(null, target.cacheAsBitmapMatrix, "explicit cache clears native cache matrix");
	}

	private static function testInvalidateRefreshAndDisposeRestoreSource():Void {
		var target = new Sprite();
		target.cacheAsBitmap = true;
		target.cacheAsBitmapMatrix = new openfl.geom.Matrix(2, 0, 0, 2, 3, 4);
		var visibleArt = rectangle(0, 0, 10, 10);
		var hiddenArt = rectangle(20, 0, 10, 10);
		hiddenArt.visible = false;
		target.addChild(visibleArt);
		target.addChild(hiddenArt);
		var cache = ExplicitBitmapCache.attach(target);
		var firstBitmap = cache.bitmap;

		cache.invalidate();
		assertTrue(!cache.valid, "invalidate marks the cache stale");
		assertEquals(null, cache.bitmap, "invalidate removes the rendered bitmap");
		assertTrue(visibleArt.visible, "invalidate restores a visible source child");
		assertTrue(!hiddenArt.visible, "invalidate preserves an originally hidden source child");

		visibleArt.graphics.drawRect(0, 0, 20, 20);
		assertTrue(cache.refresh(), "refresh rebuilds an invalid cache");
		assertTrue(cache.bitmap != firstBitmap, "refresh creates a new bitmap");
		assertTrue(!visibleArt.visible && !hiddenArt.visible, "refresh hides all source children behind the bitmap");

		var refreshedBitmap = cache.bitmap;
		cache.dispose();
		assertTrue(!cache.valid, "dispose marks the cache invalid");
		assertEquals(null, cache.bitmap, "dispose clears the bitmap reference");
		assertEquals(null, refreshedBitmap.parent, "dispose removes the bitmap from the target");
		assertTrue(visibleArt.visible, "dispose restores visible source art");
		assertTrue(!hiddenArt.visible, "dispose restores hidden source art");
		assertTrue(target.cacheAsBitmap, "dispose restores the target's native cache setting");
		assertClose(2, target.cacheAsBitmapMatrix.a, "dispose restores the native cache matrix scale");
		assertClose(3, target.cacheAsBitmapMatrix.tx, "dispose restores the native cache matrix offset");
	}

	private static function testEmptyTargetAndInvalidScale():Void {
		var empty = new Sprite();
		var cache = ExplicitBitmapCache.attach(empty);
		assertTrue(!cache.valid, "empty target does not produce a valid cache");
		assertEquals(null, cache.bitmap, "empty target has no bitmap");

		var threw = false;
		try {
			new ExplicitBitmapCache(empty, {scale: 0});
		} catch (_:Dynamic) {
			threw = true;
		}
		assertTrue(threw, "non-positive cache scale is rejected");
	}

	private static function testSharedBitmapAndPreservedChildren():Void {
		var source = new Sprite();
		var sourceArt = rectangle(-4, -3, 12, 10);
		var sourceOverlay = rectangle(20, 20, 4, 4);
		sourceOverlay.name = "overlay";
		source.addChild(sourceArt);
		source.addChild(sourceOverlay);
		var owner = ExplicitBitmapCache.attach(source, {preservedChildNames: ["overlay"]});
		assertTrue(!sourceArt.visible, "owner hides rasterized source art");
		assertTrue(sourceOverlay.visible, "owner leaves preserved overlay live");
		assertTrue(source.getChildIndex(sourceOverlay) > source.getChildIndex(owner.bitmap), "preserved overlay remains above the base raster");

		var target = new Sprite();
		var targetArt = rectangle(-4, -3, 12, 10);
		var targetOverlay = rectangle(20, 20, 4, 4);
		targetOverlay.name = "overlay";
		target.addChild(targetArt);
		target.addChild(targetOverlay);
		var shared = owner.attachShared(target, {preservedChildNames: ["overlay"]});
		assertEquals(owner.bitmap.bitmapData, shared.bitmap.bitmapData, "shared mount reuses owner pixels");
		assertTrue(!targetArt.visible, "shared mount hides its vector source");
		assertTrue(targetOverlay.visible, "shared mount leaves its preserved overlay live");
		assertTrue(target.getChildIndex(targetOverlay) > target.getChildIndex(shared.bitmap), "shared overlay remains above the base raster");

		var pixels = owner.bitmap.bitmapData;
		shared.dispose();
		assertEquals(pixels, owner.bitmap.bitmapData, "disposing a shared mount leaves owner pixels intact");
		owner.dispose();
		assertTrue(sourceArt.visible && sourceOverlay.visible, "owner disposal restores all source layers");
	}

	private static function rectangle(x:Float, y:Float, width:Float, height:Float):Shape {
		var shape = new Shape();
		shape.graphics.beginFill(0x3366CC);
		shape.graphics.drawRect(x, y, width, height);
		shape.graphics.endFill();
		return shape;
	}

	private static function assertMatrix(expected:openfl.geom.Matrix, actual:openfl.geom.Matrix, message:String):Void {
		assertClose(expected.a, actual.a, '$message a');
		assertClose(expected.b, actual.b, '$message b');
		assertClose(expected.c, actual.c, '$message c');
		assertClose(expected.d, actual.d, '$message d');
		assertClose(expected.tx, actual.tx, '$message tx');
		assertClose(expected.ty, actual.ty, '$message ty');
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.0001) throw '$message: expected $expected, got $actual';
	}

	private static function assertTrue(value:Bool, message:String):Void {
		assertions++;
		if (!value) throw message;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
