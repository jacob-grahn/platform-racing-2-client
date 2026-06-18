package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.text.TextField;

/**
	A faithful-ish port of the Flash `fl.controls.UIScrollBar` component (library
	item `Components/UIScrollBar`, linkage `fl.controls.UIScrollBar`). Only one
	standalone instance exists in the source; it pairs with `TextArea`, so this
	implementation focuses on the vertical-scrollbar role the `FlTextArea` port
	needs: a track, draggable thumb, and up/down arrows over the real
	`ScrollBarSkins` artwork.

	Public surface mirrors the parts of the fl API the source relies on:

	  - `scrollTarget` — a multiline `TextField`; the bar tracks its `scrollV`
	    and writes back when the user scrolls.
	  - `setScrollProperties` / `scrollPosition` — manual model control.
	  - `Event.SCROLL` — dispatched when the position changes via interaction.
**/
class FlUIScrollBar extends Sprite {
	private static inline final SKIN_PREFIX:String = "Components/Component Assets/ScrollBarSkins/";
	public static inline final WIDTH:Float = 15;
	private static inline final ARROW_HEIGHT:Float = 15;
	private static final TRACK_GRID = new Rectangle(0, 3, 15, 9);

	private var trackHolder:Sprite;
	private var thumb:Sprite;
	private var upArrow:Sprite;
	private var downArrow:Sprite;

	private var barHeight:Float = 100;
	private var minPos:Float = 0;
	private var maxPos:Float = 0;
	private var pageSize:Float = 1;
	private var position:Float = 0;

	private var dragging:Bool = false;
	private var dragOffset:Float = 0;

	private var _scrollTarget:Null<TextField>;

	public var scrollPosition(get, set):Float;
	public var scrollTarget(get, set):Null<TextField>;

	public function new(height:Float = 100) {
		super();
		barHeight = height;

		trackHolder = new Sprite();
		addChild(trackHolder);

		upArrow = makeArrow("ScrollArrowUp_upSkin", true);
		addChild(upArrow);

		downArrow = makeArrow("ScrollArrowDown_upSkin", false);
		addChild(downArrow);

		thumb = makeThumb();
		addChild(thumb);

		layout();
	}

	public function setSize(height:Float):Void {
		barHeight = height;
		layout();
	}

	// --- model --------------------------------------------------------------

	/**
		`pageSize` is the visible window; `minPos`/`maxPos` are the scroll range
		(fl uses line indices for a TextArea). Mirrors fl's
		`setScrollProperties(pageSize, minScrollPosition, maxScrollPosition)`.
	**/
	public function setScrollProperties(pageSize:Float, minPos:Float, maxPos:Float):Void {
		this.pageSize = pageSize <= 0 ? 1 : pageSize;
		this.minPos = minPos;
		this.maxPos = Math.max(minPos, maxPos);
		position = clampPosition(position);
		layout();
	}

	private function get_scrollPosition():Float {
		return position;
	}

	private function set_scrollPosition(value:Float):Float {
		position = clampPosition(value);
		layout();
		return position;
	}

	private function get_scrollTarget():Null<TextField> {
		return _scrollTarget;
	}

	private function set_scrollTarget(field:Null<TextField>):Null<TextField> {
		_scrollTarget = field;
		syncFromTarget();
		return _scrollTarget;
	}

	/** Recompute range/position from the bound TextField's current line metrics. */
	public function syncFromTarget():Void {
		if (_scrollTarget == null) {
			return;
		}
		var maxScroll = _scrollTarget.maxScrollV;
		setScrollProperties(_scrollTarget.bottomScrollV - _scrollTarget.scrollV + 1, 1, maxScroll);
		position = clampPosition(_scrollTarget.scrollV);
		layout();
	}

	private function clampPosition(value:Float):Float {
		if (value < minPos) {
			return minPos;
		}
		if (value > maxPos) {
			return maxPos;
		}
		return value;
	}

	// --- interaction --------------------------------------------------------

	private function step(delta:Float):Void {
		var next = clampPosition(position + delta);
		if (next == position) {
			return;
		}
		position = next;
		applyToTarget();
		layout();
		dispatchEvent(new Event(Event.SCROLL));
	}

	private function applyToTarget():Void {
		if (_scrollTarget != null) {
			_scrollTarget.scrollV = Std.int(position);
		}
	}

	private function onThumbDown(event:MouseEvent):Void {
		dragging = true;
		dragOffset = thumb.mouseY;
		stage != null ? stage.addEventListener(MouseEvent.MOUSE_MOVE, onDrag) : null;
		stage != null ? stage.addEventListener(MouseEvent.MOUSE_UP, onDragEnd) : null;
	}

	private function onDrag(event:MouseEvent):Void {
		if (!dragging) {
			return;
		}
		var travel = trackTravel();
		if (travel <= 0) {
			return;
		}
		var localY = this.mouseY - ARROW_HEIGHT - dragOffset;
		var fraction = localY / travel;
		var range = maxPos - minPos;
		var next = clampPosition(minPos + fraction * range);
		if (next != position) {
			position = next;
			applyToTarget();
			layout();
			dispatchEvent(new Event(Event.SCROLL));
		}
	}

	private function onDragEnd(event:MouseEvent):Void {
		dragging = false;
		if (stage != null) {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDrag);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onDragEnd);
		}
	}

	// --- layout / skin ------------------------------------------------------

	private function trackTravel():Float {
		return Math.max(0, (barHeight - 2 * ARROW_HEIGHT) - thumbHeight());
	}

	private function thumbHeight():Float {
		var trackLen = barHeight - 2 * ARROW_HEIGHT;
		var range = (maxPos - minPos) + pageSize;
		if (range <= 0) {
			return trackLen;
		}
		return Math.max(12, trackLen * (pageSize / range));
	}

	private function layout():Void {
		// Track between the two arrows.
		while (trackHolder.numChildren > 0) {
			trackHolder.removeChildAt(0);
		}
		var trackLen = Math.max(0, barHeight - 2 * ARROW_HEIGHT);
		var trackSkin = FlSkin.create(SKIN_PREFIX + "ScrollTrack_skin");
		if (trackSkin != null) {
			var bounds = FlSkin.nativeBounds(trackSkin, WIDTH, 100);
			FlSkin.nineSlice(trackSkin, TRACK_GRID, bounds.width, bounds.height, WIDTH, trackLen);
			trackSkin.y = ARROW_HEIGHT;
			trackHolder.addChild(trackSkin);
		} else {
			var fallback = new Shape();
			fallback.graphics.beginFill(0xE8E8E8);
			fallback.graphics.drawRect(0, ARROW_HEIGHT, WIDTH, trackLen);
			fallback.graphics.endFill();
			trackHolder.addChild(fallback);
		}

		upArrow.y = 0;
		downArrow.y = barHeight - ARROW_HEIGHT;

		var travel = trackTravel();
		var range = maxPos - minPos;
		var fraction = range <= 0 ? 0 : (position - minPos) / range;
		thumb.y = ARROW_HEIGHT + fraction * travel;
		layoutThumb();

		var scrollable = maxPos > minPos;
		thumb.visible = scrollable;
	}

	private function makeArrow(skinName:String, isUp:Bool):Sprite {
		var holder = new Sprite();
		holder.buttonMode = true;
		holder.useHandCursor = true;
		holder.mouseChildren = false;
		var skin = FlSkin.create(SKIN_PREFIX + skinName);
		if (skin != null) {
			holder.addChild(skin);
		} else {
			var shape = new Shape();
			shape.graphics.beginFill(0xBBBBBB);
			shape.graphics.drawRect(0, 0, WIDTH, ARROW_HEIGHT);
			shape.graphics.endFill();
			holder.addChild(shape);
		}
		holder.addEventListener(MouseEvent.CLICK, function(_) step(isUp ? -1 : 1));
		return holder;
	}

	private function makeThumb():Sprite {
		var holder = new Sprite();
		holder.buttonMode = true;
		holder.useHandCursor = true;
		holder.mouseChildren = false;
		holder.addEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
		return holder;
	}

	private function layoutThumb():Void {
		while (thumb.numChildren > 0) {
			thumb.removeChildAt(0);
		}
		var h = thumbHeight();
		var skin = FlSkin.create(SKIN_PREFIX + "ScrollThumb_upSkin");
		if (skin != null) {
			var bounds = FlSkin.nativeBounds(skin, WIDTH, 30);
			FlSkin.nineSlice(skin, new Rectangle(0, 3, WIDTH, Math.max(1, bounds.height - 6)), bounds.width, bounds.height, WIDTH, h);
			thumb.addChild(skin);
		} else {
			var shape = new Shape();
			shape.graphics.beginFill(0x9AA7B4);
			shape.graphics.drawRoundRect(1, 0, WIDTH - 2, h, 6, 6);
			shape.graphics.endFill();
			thumb.addChild(shape);
		}
	}
}
