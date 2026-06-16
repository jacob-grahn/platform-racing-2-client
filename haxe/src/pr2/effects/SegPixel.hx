package pr2.effects;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Point;

/**
	A single block of a `PixelEffect1` dissolve, ported from the Flash
	`com.jiggmin.pixelEffects.pixels.SegPixel`.

	Each block holds one `pixels`x`pixels` chunk of the source bitmap. It spawns
	scattered, scaled up and fully transparent, then eases toward its final
	position/scale/opacity every frame. Once it lands it stamps itself into the
	shared `product` bitmap (so the assembled image persists), blanks its own
	chunk, and fades out with a brief glint.
**/
class SegPixel extends Sprite {
	private var bitmap:Bitmap;
	private var src:BitmapData;
	private var product:BitmapData;
	private var finalX:Float;
	private var finalY:Float;
	private var pull:Float;
	private var glintFrames:Int = 20;
	private var glintCounter:Float;

	public function new(src:BitmapData, product:BitmapData, startX:Float, startY:Float, startScaleX:Float, startScaleY:Float, finalX:Float, finalY:Float, pull:Float) {
		super();

		this.glintCounter = glintFrames;
		this.finalX = finalX;
		this.finalY = finalY;
		this.pull = pull;
		this.src = src;
		this.product = product;
		alpha = 0;
		bitmap = new Bitmap(src);
		addChild(bitmap);
		x = startX;
		y = startY;
		scaleX = startScaleX;
		scaleY = startScaleY;
		addEventListener(Event.ENTER_FRAME, go);
	}

	private function go(e:Event):Void {
		if (Math.abs(x - finalX) < 1 && Math.abs(y - finalY) < 1) {
			settle();
		} else {
			x = x - (x - finalX) * pull;
			y = y - (y - finalY) * pull;
			scaleX = scaleX - (scaleX - 1) * pull;
			scaleY = scaleY - (scaleY - 1) * pull;
			alpha = alpha - (alpha - 1) * pull;
		}
	}

	private function settle():Void {
		x = finalX;
		y = finalY;
		scaleX = scaleY = 1;
		alpha = 1;
		removeEventListener(Event.ENTER_FRAME, go);
		addEventListener(Event.ENTER_FRAME, glint);
		product.copyPixels(src, src.rect, new Point(finalX, finalY));
		src.fillRect(src.rect, 0xFFFFFF);
		alpha = 0.25;
	}

	private function glint(e:Event):Void {
		glintCounter--;
		if (glintCounter > 0) {
			alpha = glintCounter / glintFrames / 2;
		} else {
			remove();
		}
	}

	private function remove():Void {
		removeEventListener(Event.ENTER_FRAME, glint);
		removeEventListener(Event.ENTER_FRAME, go);
		src.dispose();
		removeChild(bitmap);
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
