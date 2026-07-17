package pr2.ui;

import openfl.display.GradientType;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.gameplay.MiniMap;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.net.ServerConfig;

/**
	Native port of Flash `ui.RatingSelect`: the 1-5 star level-rating control on
	the finished-race page. The meter keeps the authored masked-star appearance;
	the explicit hover star slides to the matching star. Clicking confirms via a
	`ConfirmPopup` and POSTs to `submit_rating.php` through an `UploadingPopup`,
	exactly as the original.
**/
class RatingSelect extends Sprite {
	private var meter:Null<RatingStarMeter>;
	private var star:Null<Shape>;
	private var rating:Float = 3;
	private var starWidth:Float;
	private var courseID:Int;

	public function new(id:Int) {
		super();
		this.courseID = id;
		meter = new RatingStarMeter();
		starWidth = RatingStarMeter.WIDTH / 5;
		star = NativeAssets.svg(StaticSvg.RatingStarHighlight);
		scaleX = scaleY = 1.5;
		star.visible = false;
		addChild(meter);
		addChild(star);
		addEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
		addEventListener(MouseEvent.CLICK, clickHandler);
		addEventListener(MouseEvent.MOUSE_OUT, outHandler);
		addEventListener(MouseEvent.MOUSE_OVER, overHandler);
		displayRating(rating);
	}

	private function moveHandler(e:MouseEvent):Void {
		displayRating(ratingFromX(e.stageX));
	}

	private function clickHandler(e:MouseEvent):Void {
		rating = ratingFromX(e.stageX);
		new ConfirmPopup(rateLevel, "Are you sure you want to rate this level " + Std.int(rating) + "?");
	}

	private function rateLevel():Void {
		var fields = ["level_id" => Std.string(courseID), "rating" => Std.string(Std.int(rating))];
		new UploadingPopup(ServerConfig.submitRatingUrl(), fields, "Submitting rating...");
	}

	private function outHandler(e:MouseEvent):Void {
		displayRating(rating);
		if (star != null) {
			star.visible = false;
		}
	}

	private function overHandler(e:MouseEvent):Void {
		if (star != null) {
			star.visible = true;
		}
	}

	private function displayRating(value:Float):Void {
		if (meter != null) {
			meter.displayRating(value);
		}
		if (star != null) {
			star.x = (value - 1) * starWidth;
		}
	}

	private function ratingFromX(stageX:Float):Float {
		var origin = localToGlobal(new Point(0, 0));
		var offsetX = stageX - origin.x;
		return ratingFromOffset(offsetX, meter == null ? 0 : RatingStarMeter.WIDTH, scaleX);
	}

	/**
		Pure form of `ratingFromX`: map a pointer offset (in global pixels from the
		control's left edge) to a 1-5 rating, clamping the same way AS3 did.
	**/
	public static function ratingFromOffset(offsetX:Float, artWidth:Float, scale:Float):Float {
		if (artWidth == 0 || scale == 0) {
			return 1;
		}
		return MiniMap.numLimit(Math.ceil(offsetX / (artWidth * scale) * 5), 1, 5);
	}

	public function remove():Void {
		removeEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
		removeEventListener(MouseEvent.CLICK, clickHandler);
		removeEventListener(MouseEvent.MOUSE_OUT, outHandler);
		removeEventListener(MouseEvent.MOUSE_OVER, overHandler);
		if (meter != null) {
			removeChild(meter);
			meter = null;
		}
		if (star != null) {
			removeChild(star);
			star = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	public function meterFillWidthForTests():Float {
		return meter == null ? 0 : meter.fillWidth;
	}

	public function hoverVisibleForTests():Bool {
		return star != null && star.visible;
	}

	public function meterBackgroundHeightForTests():Float {
		return meter == null ? 0 : meter.backgroundHeight();
	}
}

/** Explicit rendering of the original `RatingSelectGraphic` masked meter. */
private class RatingStarMeter extends Sprite {
	public static inline var WIDTH:Float = 55.2;
	private static inline var HEIGHT:Float = 11;
	public var fillWidth(default, null):Float = 0;
	private var background:Shape;
	private var fill:Shape;

	public function new() {
		super();
		background = new Shape();
		background.graphics.beginGradientFill(GradientType.LINEAR, [0x8C8C8C, 0x474E29], [1, 1], [0, 255], verticalGradient());
		// Both gradient layers are children of the five-star mask in the XFL.
		// Drawing a solid rectangle here leaves an opaque olive strip around the
		// stars on the finished-race popup.
		for (index in 0...5) drawStar(background, 5.5 + 11.05 * index, 5.35);
		background.graphics.endFill();
		addChild(background);

		fill = new Shape();
		fill.graphics.beginGradientFill(GradientType.LINEAR, [0x50CD18, 0x248E58], [1, 1], [0, 255], verticalGradient());
		for (index in 0...5) drawStar(fill, 5.5 + 11.05 * index, 5.35);
		fill.graphics.endFill();
		addChild(fill);
		displayRating(3);
	}

	public function displayRating(value:Float):Void {
		fillWidth = WIDTH * value / 5;
		fill.scrollRect = new Rectangle(0, 0, fillWidth, HEIGHT);
	}

	public function backgroundHeight():Float {
		return background.getBounds(background).height;
	}

	private static function verticalGradient():Matrix {
		var matrix = new Matrix();
		matrix.createGradientBox(WIDTH, HEIGHT, Math.PI / 2, 0, 0);
		return matrix;
	}

	private static function drawStar(shape:Shape, cx:Float, cy:Float):Void {
		shape.graphics.moveTo(cx + 1.05, cy - 1);
		shape.graphics.lineTo(cx - 0.05, cy - 5.35);
		shape.graphics.lineTo(cx - 1.1, cy - 1);
		shape.graphics.lineTo(cx - 5.5, cy - 1.25);
		shape.graphics.lineTo(cx - 5.5, cy - 1.2);
		shape.graphics.lineTo(cx - 4.6, cy - 0.9);
		shape.graphics.lineTo(cx - 1.95, cy + 1.1);
		shape.graphics.lineTo(cx - 3.55, cy + 5.3);
		shape.graphics.lineTo(cx - 0.1, cy + 2.45);
		shape.graphics.lineTo(cx - 0.05, cy + 2.5);
		shape.graphics.lineTo(cx + 3.4, cy + 5.35);
		shape.graphics.lineTo(cx + 1.7, cy + 1.2);
		shape.graphics.lineTo(cx + 5.5, cy - 1.25);
		shape.graphics.lineTo(cx + 5.5, cy - 1.3);
		shape.graphics.lineTo(cx + 4.7, cy - 1.25);
		shape.graphics.lineTo(cx + 2.05, cy - 1);
		shape.graphics.lineTo(cx + 1.2, cy - 0.95);
		shape.graphics.lineTo(cx + 1.05, cy - 1);
	}
}
