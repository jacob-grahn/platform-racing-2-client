package pr2.page;

import openfl.display.Sprite;

/**
	Level-editor block grid overlay from `background.BlockGridLines`.
**/
class BlockGridLines extends Sprite {
	public static inline var SEG_SIZE:Float = 30;
	public static inline var VIEW_WIDTH:Float = 550;
	public static inline var VIEW_HEIGHT:Float = 400;

	public var drawnWidth(default, null):Float = 0;
	public var drawnHeight(default, null):Float = 0;

	public function new() {
		super();
		mouseEnabled = false;
		mouseChildren = false;
		drawGrid(1);
	}

	public function setZoom(zoom:Float):Void {
		if (Math.isNaN(zoom) || zoom <= 0) {
			return;
		}
		drawGrid(zoom);
	}

	public function setPos(remX:Float, remY:Float):Void {
		remX %= SEG_SIZE;
		remY %= SEG_SIZE;
		x = remX - Math.floor((width / 2) / SEG_SIZE) * SEG_SIZE;
		y = remY - Math.floor((height / 2) / SEG_SIZE) * SEG_SIZE;
	}

	public function remove():Void {
		graphics.clear();
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function drawGrid(zoom:Float):Void {
		var maxSegsX = VIEW_WIDTH / zoom + SEG_SIZE;
		var maxSegsY = VIEW_HEIGHT / zoom + SEG_SIZE;
		drawnWidth = maxSegsX;
		drawnHeight = maxSegsY;
		graphics.clear();
		graphics.lineStyle(1, 0x777777, 0.25);
		var curX:Float = 0;
		while (curX <= maxSegsX) {
			graphics.moveTo(curX, 0);
			graphics.lineTo(curX, maxSegsY);
			curX += SEG_SIZE;
		}
		var curY:Float = 0;
		while (curY <= maxSegsY) {
			graphics.moveTo(0, curY);
			graphics.lineTo(maxSegsX, curY);
			curY += SEG_SIZE;
		}
	}
}
