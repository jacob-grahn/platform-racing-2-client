package pr2.gameplay;

import openfl.events.MouseEvent;
import openfl.display.Sprite;
import pr2.level.ObjectCodes;

class MiniMapTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testNumLimit();
		if (pr2.DeterministicTestMode.finishSmokeSuite("MiniMapTest")) return;
		testRasterizeScale();
		testFitScale();
		testDotLabels();
		testDotColors();
		testNativeMarkerStates();
		testDotHoverSuppressedUntilConfigured();
		testDotHoverCleanup();
		trace('MiniMapTest passed $assertions assertions');
	}

	private static function testNumLimit():Void {
		assertEquals(5.0, MiniMap.numLimit(5, 1, 10), "value inside range is unchanged");
		assertEquals(1.0, MiniMap.numLimit(0, 1, 10), "value below minimum clamps up");
		assertEquals(10.0, MiniMap.numLimit(99, 1, 10), "value above maximum clamps down");
	}

	private static function testRasterizeScale():Void {
		// A wide, short level: width-then-height fit (44/height) is the looser of
		// the two cross fits, so it wins, matching MiniMap.rasterize.
		assertClose(0.22, MiniMap.rasterizeScale(800, 200), "wide level keeps the looser cross fit");
		// A square level: both fits collapse so the strip-height fit dominates.
		assertClose(MiniMap.MAX_SPACE_HEIGHT / 400.0, MiniMap.rasterizeScale(400, 400), "square level fits to strip height");
	}

	private static function testFitScale():Void {
		// 800x200 silhouette: width fit 0.5 vs height fit 0.22 -> the tighter wins.
		assertClose(0.22, MiniMap.fitScale(800, 200), "fit keeps the tighter dimension");
		assertClose(MiniMap.MAX_SPACE_WIDTH / 800.0, MiniMap.fitScale(800, 40), "wide-enough bitmap fits to width");
	}

	private static function testDotLabels():Void {
		assertEquals("remote0", MiniMapDot.labelForTempId(0, false), "remote dot 0 label");
		assertEquals("remote3", MiniMapDot.labelForTempId(3, false), "remote dot 3 label");
		assertEquals("local", MiniMapDot.labelForTempId(0, true), "local dot uses the local frame");
	}

	private static function testDotColors():Void {
		assertEquals(0x10B6DE, MiniMapDot.colorForTempId(0), "remote 0 colour");
		assertEquals(0xFF0000, MiniMapDot.colorForTempId(1), "remote 1 colour");
		assertEquals(0x00FF00, MiniMapDot.colorForTempId(2), "remote 2 colour");
		assertEquals(0x999999, MiniMapDot.colorForTempId(3), "remote 3 colour");
		assertEquals(0xFFFF00, MiniMapDot.colorForTempId(4), "out-of-range id falls back to local yellow");
	}

	private static function testNativeMarkerStates():Void {
		var dot = new MiniMapDot();
		assertEquals(MiniMapDot.REMOTE0_COLOR, dot.markerColorForTests(), "native dot starts at remote0");
		dot.setTempID(2);
		assertEquals(MiniMapDot.REMOTE2_COLOR, dot.markerColorForTests(), "native dot selects its remote frame colour");
		dot.setTempID(1);
		assertEquals(MiniMapDot.REMOTE2_COLOR, dot.markerColorForTests(), "native dot latches its first assigned colour");
		dot.remove();

		var localDot = new MiniMapDot();
		localDot.setTempID(0, true);
		assertEquals(MiniMapDot.LOCAL_COLOR, localDot.markerColorForTests(), "native dot selects local frame colour");
		localDot.remove();

		var minimap = new MiniMap();
		minimap.addBlock(ObjectCodes.BLOCK_FINISH, 30, 60);
		var finishLayer:Sprite = cast Reflect.field(minimap, "finishSprite");
		assertEquals(1, finishLayer.numChildren, "finish blocks create one native finish marker");
		assertEquals(45.0, finishLayer.getChildAt(0).x, "native finish marker keeps its centred x position");
		assertEquals(75.0, finishLayer.getChildAt(0).y, "native finish marker keeps its centred y position");
		minimap.remove();
	}

	private static function testDotHoverSuppressedUntilConfigured():Void {
		var dot = new MiniMapDot();
		dot.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals(null, dot.hover, "plain minimap dot suppresses hover outside live game");
		dot.remove();
	}

	private static function testDotHoverCleanup():Void {
		var dot = new MiniMapDot();
		dot.setHoverInfo(2, "Rival", true);
		dot.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals(true, dot.hover != null, "configured minimap dot opens hover popup");
		dot.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals(null, dot.hover, "mouse out removes minimap hover popup");
		dot.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals(true, dot.hover != null, "configured minimap dot can reopen hover popup");
		dot.remove();
		assertEquals(null, dot.hover, "remove clears minimap hover popup");
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
