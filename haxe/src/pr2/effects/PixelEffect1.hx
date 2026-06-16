package pr2.effects;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.TimerEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.Timer;

/**
	Pixel-dissolve reveal, ported from the Flash
	`com.jiggmin.pixelEffects.PixelEffect1`.

	The source bitmap is sliced into a grid of `pixels`x`pixels` blocks. On a
	repeating timer, three blocks at a time are spawned as `SegPixel`s that fly
	in from scattered, scaled-up, transparent starting points and assemble into
	the final image. This is the Jiggmin intro's "floating blocks come together
	to reveal the logo" effect.

	Defaults match the original `new PixelEffect1(logo)` call:
	bgColor 0, spread 500, pull 0.19, pixels 15, scaleRange 15, interval 55ms.
**/
class PixelEffect1 extends Sprite {
	private var src:BitmapData;
	private var product:BitmapData;
	private var productBitmap:Bitmap;
	private var spread:Float;
	private var pull:Float;
	private var pixels:Int;
	private var scaleRange:Float;
	private var interval:Float;
	private var segArray:Array<Array<Point>>;
	private var drawTimer:Timer;

	public function new(src:BitmapData, bgColor:Int = 0, spread:Float = 500, pull:Float = 0.19, pixels:Int = 15, scaleRange:Float = 15, interval:Float = 55) {
		super();

		this.src = src;
		this.spread = spread;
		this.pull = pull;
		this.pixels = pixels;
		this.scaleRange = scaleRange;
		this.interval = interval;
		product = new BitmapData(src.width, src.height, false, bgColor);
		productBitmap = new Bitmap(product);
		addChild(productBitmap);
		segArray = createSegArray();

		drawTimer = new Timer(interval);
		drawTimer.addEventListener(TimerEvent.TIMER, drawPixels);
		drawTimer.start();

		// Stop the timer if the effect leaves the display list (e.g. the intro
		// is skipped or cleared) so it cannot keep firing after disposal.
		addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
	}

	private function createSegArray():Array<Array<Point>> {
		var arr:Array<Array<Point>> = [];
		var segX:Int = 0;
		while (segX * pixels < src.width) {
			arr[segX] = [];
			var segY:Int = 0;
			while (segY * pixels < src.height) {
				arr[segX][segY] = new Point(segX * pixels, segY * pixels);
				segY++;
			}
			segX++;
		}
		return arr;
	}

	private function drawPixels(e:TimerEvent):Void {
		drawPixel();
		drawPixel();
		drawPixel();
	}

	private function drawPixel():Void {
		if (segArray.length > 0) {
			var col:Int = Math.floor(Math.random() * segArray.length);
			var row:Int = Math.floor(Math.random() * segArray[col].length);
			var px:Float = segArray[col][row].x;
			var py:Float = segArray[col][row].y;
			segArray[col].splice(row, 1);
			if (segArray[col].length <= 0) {
				segArray.splice(col, 1);
			}

			var chunk:BitmapData = new BitmapData(pixels, pixels, false, 0);
			var rect:Rectangle = new Rectangle(px, py, pixels, pixels);
			chunk.copyPixels(src, rect, new Point(0, 0));

			var startX:Float = px + Math.random() * spread - spread / 2 - pixels * scaleRange / 2;
			var startY:Float = py + Math.random() * spread - spread / 2 - pixels * scaleRange / 2;
			var startScaleX:Float = Math.random() * scaleRange;
			var startScaleY:Float = Math.random() * scaleRange;
			var seg:SegPixel = new SegPixel(chunk, product, startX, startY, startScaleX, startScaleY, px, py, pull);
			addChild(seg);
		} else {
			finishDrawing();
		}
	}

	private function finishDrawing():Void {
		drawTimer.stop();
	}

	private function onRemovedFromStage(e:Event):Void {
		removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		if (drawTimer != null) {
			drawTimer.stop();
		}
	}
}
