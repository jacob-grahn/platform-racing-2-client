package pr2.page;

import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.display.PixelSnapping;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.utils.Assets;
import pr2.Constants;
import pr2.runtime.SvgAsset;

class LoginBackground extends Sprite {
	private var layers:Array<LoginBackgroundLayer>;

	public function new() {
		super();
		// Each scrolling layer is a single tile of art. In the Flash source
		// (Symbol 376 -> Symbol 364/367/370/375) the looping is built from two
		// copies of that tile placed one tileWidth apart, both sliding left by one
		// tileWidth per loop so a copy always covers the seam the other leaves
		// behind. bg_front is the exception: its art is already ~2 tiles wide
		// (drawingBounds 2545 vs tileWidth ~1250), so a single copy never exposes a
		// gap. See art/raster-manifest-login.json for trim values.
		layers = [
			new LoginBackgroundLayer("assets/svg/login/bg_sky.svg", 0, 0, 1, 0, 0, 1.0, 1.00010681152344, 1, 0, 0, 1),
			new LoginBackgroundLayer("assets/svg/login/bg_far.svg", 0, 0, 1, -15.65, 240.25, 1.0, 1.0, 1508, 0, 1276.0, 2),
			new LoginBackgroundLayer("assets/svg/login/bg_mid.svg", 0, 0, 1, -36.75, 263.4, 1.00004577636719, 1.0006103515625, 383, 0, 1235.7, 2),
			// bg_front's SVG contains an embedded bitmap, retained at 2x (5078px wide).
			// At 4x it exceeds the WebGL MAX_TEXTURE_SIZE (8192 on many GPUs), so the
			// texture upload fails and the layer paints as an opaque black quad over
			// the sky. As a fast-scrolling foreground silhouette it does not need 4x
			// detail.
			new LoginBackgroundLayer("assets/login/bg_front@2x.png", -10, 1, 2, -7.2, 279.9, 1.0, 1.0, 134, -0.65, 1249.6, 1),
		];

		for (layer in layers) {
			addChild(layer);
		}

		var stageMask = new Shape();
		stageMask.graphics.beginFill(0xFFFFFF);
		stageMask.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		stageMask.graphics.endFill();
		addChild(stageMask);
		mask = stageMask;
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	private function onEnterFrame(_:Event):Void {
		for (layer in layers) {
			layer.advance();
		}
	}
}

private class LoginBackgroundLayer extends Sprite {
	private var artwork:Array<DisplayObject> = [];
	private var artOffsetX:Float;
	private var totalFrames:Int;
	private var baseTx:Float;
	private var tileWidth:Float;
	private var frame:Int = 0;

	public function new(
		assetPath:String,
		trimX:Int,
		trimY:Int,
		scale:Int,
		parentX:Float,
		parentY:Float,
		parentScaleX:Float,
		parentScaleY:Float,
		totalFrames:Int,
		baseTx:Float,
		tileWidth:Float,
		copies:Int
	) {
		super();
		this.totalFrames = totalFrames;
		this.baseTx = baseTx;
		this.tileWidth = tileWidth;
		var vectorAsset = StringTools.endsWith(assetPath, ".svg");
		artOffsetX = vectorAsset ? 0 : trimX / scale;

		// The bg-symbol layer placement (Symbol 376 matrix) is static; only the
		// tile instances scroll, so set it once on the container.
		x = parentX;
		y = parentY;
		scaleX = parentScaleX;
		scaleY = parentScaleY;

		// Lay out `copies` tiles spaced one tileWidth apart so that as the group
		// slides left by tileWidth over a loop, a trailing copy fills the gap the
		// leading copy opens up.
		for (i in 0...copies) {
			var display:DisplayObject;
			if (vectorAsset) {
				display = SvgAsset.create(assetPath);
			} else {
				var bitmap = new Bitmap(Assets.getBitmapData(assetPath), PixelSnapping.AUTO, true);
				bitmap.y = trimY / scale;
				bitmap.scaleX = 1 / scale;
				bitmap.scaleY = 1 / scale;
				display = bitmap;
			}
			addChild(display);
			artwork.push(display);
		}
		updatePosition();
	}

	public function advance():Void {
		if (totalFrames <= 1) {
			return;
		}
		frame = (frame + 1) % totalFrames;
		updatePosition();
	}

	private function updatePosition():Void {
		// Scroll offset cycles continuously through (0, -tileWidth], wrapping each
		// loop. Because adjacent copies are identical art exactly tileWidth apart,
		// the wrap from one frame to the next is seamless.
		var scroll = totalFrames > 1 ? -tileWidth * (frame / totalFrames) : 0;
		for (i in 0...artwork.length) {
			artwork[i].x = artOffsetX + baseTx + i * tileWidth + scroll;
		}
	}
}
