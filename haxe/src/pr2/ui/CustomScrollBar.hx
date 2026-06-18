package pr2.ui;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `ui.CustomScrollBar`: a draggable thumb plus up/down arrows that
	scroll a `target` display object vertically within a fixed view height. The
	arrows scroll continuously while held (one `scrollStep` per frame) and the
	thumb maps its travel onto the target's overflow (`target.height - viewHeight`).

	The thumb/arrow/track positions math is exposed via the static `thumbToTargetY`
	helper so the scroll mapping can be unit-tested without real art.
**/
class CustomScrollBar extends Sprite {
	private var art:Null<PR2MovieClip>;
	private var thumb:Null<DisplayObject>;
	private var upArrow:Null<DisplayObject>;
	private var downArrow:Null<DisplayObject>;
	private var track:Null<DisplayObject>;
	private var target:Null<DisplayObject>;
	private var stageRef:Null<Stage>;

	private var thumbMinY:Float = 0;
	private var thumbMaxY:Float = 0;
	private var targetInitialY:Float = 0;
	private var viewHeight:Float = 0;
	private var pos:Float = 0;
	private var scrollStep:Float = 5;
	private var scrollDelta:Float = 0;
	private var scrolling:Bool = false;

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("CustomScrollBarGraphic", {maxNestedDepth: 4});
		addChild(art);
		thumb = findChild("thumb");
		upArrow = findChild("upArrow");
		downArrow = findChild("downArrow");
		track = findChild("track");
		if (thumb != null) {
			thumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
		}
		if (upArrow != null) {
			upArrow.addEventListener(MouseEvent.MOUSE_DOWN, onUpArrowDown);
		}
		if (downArrow != null) {
			downArrow.addEventListener(MouseEvent.MOUSE_DOWN, onDownArrowDown);
		}
	}

	/**
		Map a thumb Y onto a target Y, matching the Flash math. The thumb fraction
		`(thumbY - minY) / (maxY - minY)` scrolls the target across its overflow,
		clamped so the target never scrolls below its initial position.
	**/
	public static function thumbToTargetY(thumbY:Float, thumbMinY:Float, thumbMaxY:Float, targetInitialY:Float, targetHeight:Float, viewHeight:Float):Float {
		var clamped = thumbY;
		if (clamped > thumbMaxY) {
			clamped = thumbMaxY;
		}
		if (clamped < thumbMinY) {
			clamped = thumbMinY;
		}
		var fraction = (clamped - thumbMinY) / (thumbMaxY - thumbMinY);
		var overflow = targetHeight - viewHeight;
		var y = targetInitialY - (fraction * overflow);
		if (y > targetInitialY) {
			y = targetInitialY;
		}
		return Math.round(y);
	}

	public function init(target:DisplayObject, trackHeight:Float, viewHeight:Float):Void {
		this.stageRef = stage;
		if (track != null) {
			track.height = trackHeight - 15;
		}
		if (downArrow != null) {
			downArrow.y = trackHeight - downArrow.height;
			thumbMaxY = downArrow.y - (thumb != null ? thumb.height / 2 : 0);
		}
		if (upArrow != null) {
			thumbMinY = upArrow.height + (thumb != null ? thumb.height / 2 : 0);
		}
		this.targetInitialY = target.y;
		this.target = target;
		this.viewHeight = viewHeight;
		scaleX = scaleY = 1;
	}

	public function position(thumbY:Float):Void {
		if (thumb == null || target == null) {
			return;
		}
		var clamped = thumbY;
		if (clamped > thumbMaxY) {
			clamped = thumbMaxY;
		}
		if (clamped < thumbMinY) {
			clamped = thumbMinY;
		}
		pos = clamped;
		thumb.y = clamped;
		target.y = thumbToTargetY(clamped, thumbMinY, thumbMaxY, targetInitialY, target.height, viewHeight);
	}

	private function onThumbDown(_:MouseEvent):Void {
		if (stageRef == null) {
			return;
		}
		stageRef.addEventListener(MouseEvent.MOUSE_UP, onThumbUp);
		stageRef.addEventListener(MouseEvent.MOUSE_MOVE, onThumbDrag);
	}

	private function onThumbUp(_:MouseEvent):Void {
		if (stageRef == null) {
			return;
		}
		stageRef.removeEventListener(MouseEvent.MOUSE_UP, onThumbUp);
		stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, onThumbDrag);
	}

	private function onThumbDrag(event:MouseEvent):Void {
		var local = globalToLocal(new Point(0, event.stageY));
		position(local.y);
	}

	private function onUpArrowDown(_:MouseEvent):Void {
		startContinuousScroll(-scrollStep);
	}

	private function onDownArrowDown(_:MouseEvent):Void {
		startContinuousScroll(scrollStep);
	}

	private function startContinuousScroll(delta:Float):Void {
		removeEventListener(Event.ENTER_FRAME, scroll);
		addEventListener(Event.ENTER_FRAME, scroll);
		if (stageRef != null) {
			stageRef.addEventListener(MouseEvent.MOUSE_UP, onArrowUp);
		}
		scrollDelta = delta;
	}

	private function onArrowUp(_:MouseEvent):Void {
		removeEventListener(Event.ENTER_FRAME, scroll);
	}

	private function scroll(_:Event):Void {
		position(pos + scrollDelta);
	}

	private function findChild(name:String):Null<DisplayObject> {
		return pr2.lobby.LobbyArt.findByName(art, name);
	}

	public function remove():Void {
		if (thumb != null) {
			thumb.removeEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
		}
		if (upArrow != null) {
			upArrow.removeEventListener(MouseEvent.MOUSE_DOWN, onUpArrowDown);
		}
		if (downArrow != null) {
			downArrow.removeEventListener(MouseEvent.MOUSE_DOWN, onDownArrowDown);
		}
		removeEventListener(Event.ENTER_FRAME, scroll);
		if (stageRef != null) {
			stageRef.removeEventListener(MouseEvent.MOUSE_UP, onArrowUp);
			stageRef.removeEventListener(MouseEvent.MOUSE_UP, onThumbUp);
			stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, onThumbDrag);
		}
		target = null;
		stageRef = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
