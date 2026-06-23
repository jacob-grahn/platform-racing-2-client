package pr2.ui;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import pr2.gameplay.MiniMap;
import pr2.lobby.LobbyArt;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.net.ServerConfig;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `ui.RatingSelect`: the 1-5 star level-rating control on the
	finished-race page. The bar (`m.bar`) is scaled to the hovered rating and the
	`HighlightStar` slides to the matching star; clicking confirms via a
	`ConfirmPopup` and POSTs to `submit_rating.php` through an `UploadingPopup`,
	exactly as the original.
**/
class RatingSelect extends Sprite {
	private var art:Null<PR2MovieClip>;
	private var bar:Null<DisplayObject>;
	private var star:Null<PR2MovieClip>;
	private var rating:Float = 3;
	private var starWidth:Float;
	private var courseID:Int;

	public function new(id:Int) {
		super();
		this.courseID = id;
		art = PR2MovieClip.fromLinkage("RatingSelectGraphic", {maxNestedDepth: 4});
		starWidth = art.width / 5;
		star = PR2MovieClip.fromLinkage("HighlightStar", {maxNestedDepth: 2});
		scaleX = scaleY = 1.5;
		star.gotoAndStop("off");
		star.mouseChildren = false;
		star.mouseEnabled = false;
		bar = LobbyArt.findByName(art, "bar");
		addChild(art);
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
			star.gotoAndStop("off");
		}
	}

	private function overHandler(e:MouseEvent):Void {
		if (star != null) {
			star.gotoAndStop("on");
		}
	}

	private function displayRating(value:Float):Void {
		if (bar != null) {
			bar.scaleX = value / 5;
		}
		if (star != null) {
			star.x = (value - 1) * starWidth;
		}
	}

	private function ratingFromX(stageX:Float):Float {
		var origin = localToGlobal(new Point(0, 0));
		var offsetX = stageX - origin.x;
		return ratingFromOffset(offsetX, art == null ? 0 : art.width, scaleX);
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
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (star != null) {
			star.dispose();
			star = null;
		}
		bar = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
