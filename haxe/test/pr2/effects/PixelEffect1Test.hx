package pr2.effects;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.Event;

class PixelEffect1Test {
	private static var assertions:Int = 0;

	public static function main():Void {
		testSegmentGridCoversPartialEdges();
		testDrawPixelConsumesSegmentsAndUsesConfiguredBackground();
		testSegPixelSettlesIntoProductAndRemovesItself();
		trace('PixelEffect1Test passed $assertions assertions');
	}

	private static function testSegmentGridCoversPartialEdges():Void {
		var source = new BitmapData(31, 16, false, 0x112233);
		var effect = new PixelEffect1(source, 0x445566, 0, 1, 15, 1, 1000000);
		effect.drawTimer.stop();

		assertEquals(3, effect.segArray.length, "segment columns cover source width");
		assertEquals(2, effect.segArray[0].length, "segment rows cover source height");
		assertEquals(30.0, effect.segArray[2][0].x, "partial right-edge segment x");
		assertEquals(15.0, effect.segArray[0][1].y, "partial bottom-edge segment y");

		effect.finishDrawing();
	}

	private static function testDrawPixelConsumesSegmentsAndUsesConfiguredBackground():Void {
		var source = new BitmapData(1, 1, false, 0xABCDEF);
		var effect = new PixelEffect1(source, 0x123456, 0, 1, 15, 1, 1000000);
		effect.drawTimer.stop();

		effect.drawPixel();

		assertEquals(0, effect.segArray.length, "single source segment is consumed");
		assertEquals(2, effect.numChildren, "effect keeps product bitmap and adds one segment");

		var segment = Std.downcast(effect.getChildAt(1), SegPixel);
		assertNotNull(segment, "drawn child is a SegPixel");
		var bitmap = Std.downcast(segment.getChildAt(0), Bitmap);
		assertNotNull(bitmap, "segment renders a bitmap child");
		assertEquals(0xABCDEF, bitmap.bitmapData.getPixel(0, 0), "segment copies source pixel");
		assertEquals(0x123456, bitmap.bitmapData.getPixel(14, 14), "segment background uses configured color outside source");

		effect.finishDrawing();
	}

	private static function testSegPixelSettlesIntoProductAndRemovesItself():Void {
		var source = new BitmapData(2, 2, false, 0xFF00CC);
		var product = new BitmapData(5, 5, false, 0x000000);
		var parent = new openfl.display.Sprite();
		var segment = new SegPixel(source, product, 0, 0, 1, 1, 2, 3, 1);
		parent.addChild(segment);

		segment.dispatchEvent(new Event(Event.ENTER_FRAME));
		segment.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(0xFF00CC, product.getPixel(2, 3), "settled segment stamps into product");
		assertEquals(0xFFFFFF, source.getPixel(0, 0), "settled segment blanks its source for glint");

		for (_ in 0...20) {
			segment.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(0, parent.numChildren, "segment removes itself after glint frames");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) {
			throw '$message: expected non-null value';
		}
	}
}
