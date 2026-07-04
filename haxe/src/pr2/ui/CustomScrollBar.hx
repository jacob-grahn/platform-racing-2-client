package pr2.ui;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import pr2.app.AppStage;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class CustomScrollBar extends Sprite {
	private var art:PR2MovieClip;
	private var target:Null<DisplayObject>;
	private var thumb:Null<DisplayObject>;
	private var upArrow:Null<DisplayObject>;
	private var downArrow:Null<DisplayObject>;
	private var track:Null<DisplayObject>;
	private var thumbMinY:Float = 0;
	private var thumbMaxY:Float = 0;
	private var targetInitialY:Float = 0;
	private var viewHeight:Float = 0;
	private var pos:Float = 0;
	private var scrollStep:Float = 5;
	private var scrollDelta:Float = 0;
	private var removed:Bool = false;

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("CustomScrollBarGraphic", {maxNestedDepth: 5});
		addChild(art);
		thumb = DisplayUtil.findByName(art, "thumb");
		upArrow = DisplayUtil.findByName(art, "upArrow");
		downArrow = DisplayUtil.findByName(art, "downArrow");
		track = DisplayUtil.findByName(art, "track");
		if (thumb != null) thumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbDown, false, 0, true);
		if (upArrow != null) upArrow.addEventListener(MouseEvent.MOUSE_DOWN, onUpArrowDown, false, 0, true);
		if (downArrow != null) downArrow.addEventListener(MouseEvent.MOUSE_DOWN, onDownArrowDown, false, 0, true);
	}

	public function init(target:DisplayObject, scrollHeight:Float, viewHeight:Float):Void {
		if (track != null) track.height = scrollHeight - 15;
		if (downArrow != null) downArrow.y = scrollHeight - downArrow.height;
		thumbMaxY = downArrow == null || thumb == null ? 0 : downArrow.y - thumb.height / 2;
		thumbMinY = upArrow == null || thumb == null ? 0 : upArrow.height + thumb.height / 2;
		targetInitialY = target.y;
		this.target = target;
		this.viewHeight = viewHeight;
		scaleX = scaleY = 1;
		position(thumbMinY);
	}

	public function position(value:Float):Void {
		if (target == null || thumb == null) return;
		if (value > thumbMaxY) value = thumbMaxY;
		if (value < thumbMinY) value = thumbMinY;
		thumb.y = pos = value;
		target.y = thumbToTargetY(thumb.y, thumbMinY, thumbMaxY, targetInitialY, target.height, viewHeight);
	}

	public static function thumbToTargetY(thumbY:Float, thumbMinY:Float, thumbMaxY:Float, targetInitialY:Float, targetHeight:Float,
			viewHeight:Float):Float {
		if (thumbY > thumbMaxY) thumbY = thumbMaxY;
		if (thumbY < thumbMinY) thumbY = thumbMinY;
		var range = thumbMaxY - thumbMinY;
		var fraction = range == 0 ? 0 : (thumbY - thumbMinY) / range;
		var targetRange = Math.max(0, targetHeight - viewHeight);
		var y = Math.round(targetInitialY - fraction * targetRange);
		return y > targetInitialY ? targetInitialY : y;
	}

	public function thumbMaxYForTests():Float {
		return thumbMaxY;
	}

	public function removedForTests():Bool {
		return removed;
	}

	private function onThumbDown(_:MouseEvent):Void {
		if (AppStage.stage == null) return;
		AppStage.stage.addEventListener(MouseEvent.MOUSE_UP, onThumbUp, false, 0, true);
		AppStage.stage.addEventListener(MouseEvent.MOUSE_MOVE, onThumbDrag, false, 0, true);
	}

	private function onUpArrowDown(_:MouseEvent):Void {
		startContinuousScroll(-scrollStep);
	}

	private function onDownArrowDown(_:MouseEvent):Void {
		startContinuousScroll(scrollStep);
	}

	private function startContinuousScroll(delta:Float):Void {
		removeEventListener(Event.ENTER_FRAME, scroll);
		addEventListener(Event.ENTER_FRAME, scroll, false, 0, true);
		if (AppStage.stage != null) {
			AppStage.stage.addEventListener(MouseEvent.MOUSE_UP, onArrowUp, false, 0, true);
		}
		scrollDelta = delta;
	}

	private function onArrowUp(_:MouseEvent):Void {
		removeEventListener(Event.ENTER_FRAME, scroll);
	}

	private function scroll(_:Event):Void {
		position(pos + scrollDelta);
	}

	private function onThumbUp(_:MouseEvent):Void {
		if (AppStage.stage == null) return;
		AppStage.stage.removeEventListener(MouseEvent.MOUSE_UP, onThumbUp);
		AppStage.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThumbDrag);
	}

	private function onThumbDrag(event:MouseEvent):Void {
		var point = globalToLocal(new Point(0, event.stageY));
		position(point.y);
	}

	public function remove():Void {
		removed = true;
		if (thumb != null) thumb.removeEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
		if (upArrow != null) upArrow.removeEventListener(MouseEvent.MOUSE_DOWN, onUpArrowDown);
		if (downArrow != null) downArrow.removeEventListener(MouseEvent.MOUSE_DOWN, onDownArrowDown);
		removeEventListener(Event.ENTER_FRAME, scroll);
		if (AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_UP, onArrowUp);
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_UP, onThumbUp);
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThumbDrag);
		}
		target = null;
		thumb = null;
		upArrow = null;
		downArrow = null;
		track = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
