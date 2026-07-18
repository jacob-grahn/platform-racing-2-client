package pr2.ui;

import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.gameplay.MiniMap;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.net.ServerConfig;
import pr2.runtime.SvgAsset;

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
class RatingStarMeter extends Sprite {
	public static inline var WIDTH:Float = 55.2;
	private static inline var HEIGHT:Float = 11;
	public var fillWidth(default, null):Float = 0;
	private var background:DisplayObject;
	private var fill:DisplayObject;
	private var starMask:DisplayObject;

	public function new() {
		super();
		var content = new Sprite();
		content.name = "maskedContent";
		background = SvgAsset.create("assets/svg/ui/rating_stars_background.svg");
		background.name = "background";
		fill = SvgAsset.create("assets/svg/ui/rating_stars_fill.svg");
		fill.name = "bar";
		content.addChild(background);
		content.addChild(fill);
		addChild(content);
		starMask = SvgAsset.create("assets/svg/ui/rating_stars_mask.svg");
		starMask.name = "starMask";
		addChild(starMask);
		content.mask = starMask;
		displayRating(3);
	}

	public function displayRating(value:Float):Void {
		fillWidth = WIDTH * value / 5;
		fill.scrollRect = new Rectangle(0, 0, fillWidth, HEIGHT);
	}

	public function backgroundHeight():Float {
		return starMask.getBounds(starMask).height;
	}

}
