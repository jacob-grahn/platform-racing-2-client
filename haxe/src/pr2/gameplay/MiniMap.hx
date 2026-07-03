package pr2.gameplay;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.geom.Rectangle;
import pr2.display.Removable;
import pr2.level.ObjectCodes;
import pr2.runtime.PR2MovieClip;

/**
	Port of `gameplay/MiniMap.as`.

	Blocks are added in original PR2 pixel space (the same coordinates the block
	layer is placed at). The minimap fills a flat black silhouette of every block
	into `blockSprite`, scales it to fit the authored 400x44 strip, rasterizes it
	to a bitmap, and then layers finish boxes and live player dots over it in the
	same coordinate space so they track the level geometry. Player dots are kept
	at a constant 4px on screen regardless of the minimap scale, matching
	`scaleChildDots`.

	`Course` positions the minimap at holder offset (-195, -198); with the game
	holder at the 550x400 stage centre (275, 200) that is stage (80, 2).
**/
class MiniMap extends Removable {
	public static inline var MAX_SPACE_WIDTH:Int = 400;
	public static inline var MAX_SPACE_HEIGHT:Int = 44;
	private static inline var BLOCK_SIZE:Int = 30;

	private var bitmapData:BitmapData;
	private var bitmap:Bitmap;
	private var holder:Sprite = new Sprite();
	private var blockSprite:Sprite = new Sprite();
	private var finishSprite:Sprite = new Sprite();
	private var playerDots:Sprite = new Sprite();
	private var m:PR2MovieClip;
	private var scale:Float = 1;
	private var blockCount:Int = 0;

	public function new() {
		super();
		m = PR2MovieClip.fromLinkage("MiniMapGraphic");
		addChild(m);
		blockSprite.graphics.beginFill(0);
	}

	/** Adds one block silhouette; finish blocks also get a finish box overlay. */
	public function addBlock(blockCode:Int, blockX:Float, blockY:Float):Void {
		if (blockCode == ObjectCodes.BLOCK_FINISH) {
			var finishBox = PR2MovieClip.fromLinkage("MiniMapFinishGraphic");
			finishBox.x = blockX + 15;
			finishBox.y = blockY + 15;
			finishSprite.addChild(finishBox);
		}
		drawBlock(blockX, blockY);
		blockCount++;
	}

	/** Removes a finish box previously placed at the given (centre) coordinates. */
	public function removeFinish(x:Float, y:Float):Void {
		var i = 0;
		while (i < finishSprite.numChildren) {
			var child = finishSprite.getChildAt(i);
			if (child.x == x && child.y == y) {
				finishSprite.removeChild(child);
				return;
			}
			i++;
		}
	}

	private function drawBlock(blockX:Float, blockY:Float):Void {
		blockSprite.graphics.beginFill(0);
		blockSprite.graphics.moveTo(blockX, blockY);
		blockSprite.graphics.lineTo(blockX + BLOCK_SIZE, blockY);
		blockSprite.graphics.lineTo(blockX + BLOCK_SIZE, blockY + BLOCK_SIZE);
		blockSprite.graphics.lineTo(blockX, blockY + BLOCK_SIZE);
		blockSprite.graphics.lineTo(blockX, blockY);
		blockSprite.graphics.endFill();
	}

	/** Creates a player dot, adds it to the live dot layer, and returns it. */
	public function getDot():MiniMapDot {
		var dot = new MiniMapDot();
		playerDots.addChild(dot);
		scaleChildDots(playerDots, holder.scaleX);
		return dot;
	}

	/** Bakes the accumulated block silhouette into a bitmap and lays out overlays. */
	public function rasterize():Void {
		if (blockCount == 0) {
			return;
		}
		blockSprite.graphics.endFill();
		blockSprite.scaleX = blockSprite.scaleY = 1;
		var rasterScale = rasterizeScale(blockSprite.width, blockSprite.height);
		finishSprite.scaleX = finishSprite.scaleY = rasterScale;
		playerDots.scaleX = playerDots.scaleY = rasterScale;
		blockSprite.scaleX = blockSprite.scaleY = rasterScale;

		var frame = new Sprite();
		frame.addChild(blockSprite);
		var bounds:Rectangle = blockSprite.getBounds(frame);
		finishSprite.x = playerDots.x = blockSprite.x = -bounds.left;
		finishSprite.y = playerDots.y = blockSprite.y = -bounds.top;

		var pixelW = numLimit(blockSprite.width, 1, MAX_SPACE_WIDTH);
		var pixelH = numLimit(blockSprite.height, 1, MAX_SPACE_WIDTH);
		bitmapData = new BitmapData(Math.ceil(pixelW), Math.ceil(pixelH), true, 0);
		bitmap = new Bitmap(bitmapData);
		bitmapData.draw(frame);

		blockSprite.graphics.clear();
		blockSprite = new Sprite();
		addChild(holder);
		holder.addChild(bitmap);
		holder.addChild(finishSprite);
		holder.addChild(playerDots);
		applyScale();
	}

	private function applyScale():Void {
		if (bitmap == null) {
			return;
		}
		holder.scaleX = holder.scaleY = 1;
		var bounds:Rectangle = bitmap.getBounds(this);
		scale = numLimit(fitScale(bounds.width, bounds.height), 0, 1);
		holder.scaleX = holder.scaleY = scale;
		bounds = bitmap.getBounds(this);
		var centerX = Std.int((MAX_SPACE_WIDTH - bounds.width) / 2);
		var centerY = Std.int((MAX_SPACE_HEIGHT - bounds.height) / 2);
		holder.x = holder.x + (centerX - bounds.left) + 3;
		holder.y = holder.y + (centerY - bounds.top) + 3;
		scaleChildDots(playerDots, scale);
		scaleChildDots(finishSprite, scale);
	}

	private function scaleChildDots(layer:Sprite, layerScale:Float):Void {
		var i = 0;
		while (i < layer.numChildren) {
			var child:DisplayObject = layer.getChildAt(i);
			child.width = child.height = 4 / (layerScale * layer.scaleX);
			i++;
		}
	}

	public function rotate(angle:Float):Void {
		holder.rotation = angle;
		applyScale();
	}

	public function clear():Void {
		if (bitmapData != null) {
			bitmapData.dispose();
			bitmapData = null;
		}
		while (finishSprite != null && finishSprite.numChildren > 0) {
			finishSprite.removeChildAt(0);
		}
	}

	override public function remove():Void {
		if (isRemoved()) return;
		clear();
		while (playerDots != null && playerDots.numChildren > 0) {
			var dot = Std.downcast(playerDots.getChildAt(0), MiniMapDot);
			if (dot != null) {
				dot.remove();
			}
			if (playerDots.numChildren > 0) {
				playerDots.removeChildAt(0);
			}
		}
		if (m != null && m.parent == this) {
			removeChild(m);
		}
		bitmap = null;
		holder = null;
		blockSprite = null;
		finishSprite = null;
		playerDots = null;
		m = null;
		super.remove();
	}

	/**
		The scale that fits the block silhouette into the authored strip, matching
		MiniMap.rasterize: it independently fits width-then-height and
		height-then-width and keeps the looser of the two so very wide or very tall
		levels still fill one strip dimension.
	**/
	public static function rasterizeScale(blockWidth:Float, blockHeight:Float):Float {
		var widthFitW = MAX_SPACE_WIDTH / blockWidth;
		var heightFitW = MAX_SPACE_WIDTH / blockHeight;
		var heightFitH = MAX_SPACE_HEIGHT / blockHeight;
		var widthFitH = MAX_SPACE_HEIGHT / blockWidth;
		var a = widthFitW < heightFitH ? widthFitW : heightFitH;
		var b = heightFitW < widthFitH ? heightFitW : widthFitH;
		return a > b ? a : b;
	}

	/** The display scale that fits the rasterized bitmap into the strip. */
	public static function fitScale(bitmapWidth:Float, bitmapHeight:Float):Float {
		var fitW = MAX_SPACE_WIDTH / bitmapWidth;
		var fitH = MAX_SPACE_HEIGHT / bitmapHeight;
		return fitW < fitH ? fitW : fitH;
	}

	/** Port of Data.numLimit. */
	public static function numLimit(value:Float, minimum:Float, maximum:Float):Float {
		if (value > maximum) {
			return maximum;
		} else if (value < minimum) {
			return minimum;
		}
		return value;
	}
}
