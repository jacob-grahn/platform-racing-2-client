package pr2.ui.controls;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.ui.Keyboard;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;

/** Native fl.controls.UIScrollBar with the exact authored ScrollBarSkins. */
class GameScrollBar extends NativeControl {
	private static inline var AUTHORED_WIDTH:Float = 15;
	private static inline var ARROW_HEIGHT:Float = 15;

	public var minimum(default, null):Float;
	public var maximum(default, null):Float;
	public var pageSize(default, null):Float;
	public var lineStep(default, null):Float;
	public var value(default, set):Float;
	public var onScroll:Null<Float->Void>;

	private var useAuthoredSkin:Bool = false;
	private var trackHolder:Null<Sprite>;
	private var thumb:Null<Sprite>;
	private var upArrow:Null<Sprite>;
	private var downArrow:Null<Sprite>;
	private var thumbHovered:Bool = false;
	private var thumbPressed:Bool = false;
	private var upHovered:Bool = false;
	private var upPressed:Bool = false;
	private var downHovered:Bool = false;
	private var downPressed:Bool = false;
	private var dragging:Bool = false;
	private var dragOffset:Float = 0;

	public function new(minimum:Float = 0, maximum:Float = 100, pageSize:Float = 10, lineStep:Float = 1, ?skin:ControlSkin) {
		if (maximum < minimum || pageSize < 0 || lineStep <= 0) throw "Invalid scroll bar range";
		super(AUTHORED_WIDTH, 100, skin);
		this.minimum = minimum;
		this.maximum = maximum;
		this.pageSize = pageSize;
		this.lineStep = lineStep;
		this.value = minimum;
		useAuthoredSkin = skin == null;
		if (useAuthoredSkin) buildAuthoredParts();
		addEventListener(KeyboardEvent.KEY_DOWN, scrollFromKey);
		addEventListener(MouseEvent.MOUSE_WHEEL, scrollFromWheel);
		redraw();
	}

	public function scrollTo(next:Float):Void {
		if (!enabled || disposed) return;
		var before = value;
		value = next;
		if (value != before) dispatchScroll();
	}

	/** Matches fl.controls.UIScrollBar.setScrollProperties for text targets. */
	public function setScrollProperties(pageSize:Float, minimum:Float, maximum:Float):Void {
		if (maximum < minimum || pageSize < 0) throw "Invalid scroll bar range";
		this.pageSize = pageSize;
		this.minimum = minimum;
		this.maximum = maximum;
		value = value;
		redraw();
	}

	override public function setSize(width:Float, height:Float):Void {
		super.setSize(useAuthoredSkin ? AUTHORED_WIDTH : width, height);
		redraw();
	}

	override public function redraw():Void {
		if (!useAuthoredSkin || trackHolder == null || thumb == null || upArrow == null || downArrow == null) {
			super.redraw();
			return;
		}
		graphics.clear();
		drawTrack();
		drawArrow(upArrow, true, upHovered, upPressed);
		drawArrow(downArrow, false, downHovered, downPressed);
		downArrow.y = controlHeight - ARROW_HEIGHT;
		var scrollable = maximum > minimum;
		thumb.visible = scrollable;
		if (scrollable) {
			var fraction = (value - minimum) / (maximum - minimum);
			thumb.y = ARROW_HEIGHT + fraction * trackTravel();
			drawThumb();
		}
	}

	override public function dispose():Void {
		removeDragListeners();
		removeEventListener(KeyboardEvent.KEY_DOWN, scrollFromKey);
		removeEventListener(MouseEvent.MOUSE_WHEEL, scrollFromWheel);
		onScroll = null;
		super.dispose();
	}

	private function buildAuthoredParts():Void {
		graphics.clear();
		trackHolder = new Sprite();
		trackHolder.name = "track";
		trackHolder.addEventListener(MouseEvent.CLICK, onTrackClick);
		addChild(trackHolder);
		upArrow = makeArrow("upArrow", true);
		downArrow = makeArrow("downArrow", false);
		addChild(upArrow);
		addChild(downArrow);
		thumb = new Sprite();
		thumb.name = "thumb";
		thumb.buttonMode = true;
		thumb.useHandCursor = true;
		thumb.mouseChildren = false;
		thumb.addEventListener(MouseEvent.ROLL_OVER, function(_:MouseEvent):Void { thumbHovered = true; redraw(); });
		thumb.addEventListener(MouseEvent.ROLL_OUT, function(_:MouseEvent):Void { thumbHovered = false; if (!dragging) thumbPressed = false; redraw(); });
		thumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
		addChild(thumb);
	}

	private function makeArrow(name:String, isUp:Bool):Sprite {
		var arrow = new Sprite();
		arrow.name = name;
		arrow.buttonMode = true;
		arrow.useHandCursor = true;
		arrow.mouseChildren = false;
		arrow.addEventListener(MouseEvent.ROLL_OVER, function(_:MouseEvent):Void { if (isUp) upHovered = true; else downHovered = true; redraw(); });
		arrow.addEventListener(MouseEvent.ROLL_OUT, function(_:MouseEvent):Void { if (isUp) { upHovered = false; upPressed = false; } else { downHovered = false; downPressed = false; } redraw(); });
		arrow.addEventListener(MouseEvent.MOUSE_DOWN, function(_:MouseEvent):Void { if (isUp) upPressed = true; else downPressed = true; redraw(); });
		arrow.addEventListener(MouseEvent.MOUSE_UP, function(_:MouseEvent):Void { if (isUp) upPressed = false; else downPressed = false; redraw(); });
		arrow.addEventListener(MouseEvent.CLICK, function(_:MouseEvent):Void scrollTo(value + (isUp ? -lineStep : lineStep)));
		return arrow;
	}

	private function drawTrack():Void {
		while (trackHolder.numChildren > 0) trackHolder.removeChildAt(0);
		var track = new Sprite();
		track.addChild(NativeAssets.svg(StaticSvg.ScrollTrackAuthored));
		track.scale9Grid = new Rectangle(0, 3, 15, 9);
		track.width = AUTHORED_WIDTH;
		track.height = Math.max(0, controlHeight - 2 * ARROW_HEIGHT);
		track.y = ARROW_HEIGHT;
		trackHolder.addChild(track);
	}

	private function drawArrow(arrow:Sprite, isUp:Bool, hovered:Bool, pressed:Bool):Void {
		while (arrow.numChildren > 0) arrow.removeChildAt(0);
		arrow.addChild(NativeAssets.svg(arrowAsset(isUp, hovered, pressed)));
	}

	private function arrowAsset(isUp:Bool, hovered:Bool, pressed:Bool):StaticSvg return if (!enabled) {
			isUp ? StaticSvg.ScrollArrowUpDisabledAuthored : StaticSvg.ScrollArrowDownDisabledAuthored;
		} else if (pressed) {
			isUp ? StaticSvg.ScrollArrowUpDownAuthored : StaticSvg.ScrollArrowDownDownAuthored;
		} else if (hovered) {
			isUp ? StaticSvg.ScrollArrowUpOverAuthored : StaticSvg.ScrollArrowDownOverAuthored;
		} else {
			isUp ? StaticSvg.ScrollArrowUpUpAuthored : StaticSvg.ScrollArrowDownUpAuthored;
		};

	private function drawThumb():Void {
		while (thumb.numChildren > 0) thumb.removeChildAt(0);
		var skin = new Sprite();
		skin.addChild(NativeAssets.svg(thumbAsset()));
		skin.scale9Grid = new Rectangle(0, 3, 15, 9);
		skin.width = AUTHORED_WIDTH;
		skin.height = thumbHeight();
		thumb.addChild(skin);
		var icon = NativeAssets.svg(StaticSvg.ScrollThumbIcon);
		icon.x = (AUTHORED_WIDTH - icon.width) / 2;
		icon.y = (thumbHeight() - icon.height) / 2;
		thumb.addChild(icon);
	}

	private function thumbAsset():StaticSvg return thumbPressed ? StaticSvg.ScrollThumbDownAuthored : thumbHovered ? StaticSvg.ScrollThumbOverAuthored : StaticSvg.ScrollThumbUpAuthored;

	private function thumbHeight():Float {
		var trackLength = Math.max(0, controlHeight - 2 * ARROW_HEIGHT);
		var range = (maximum - minimum) + pageSize;
		return range <= 0 ? trackLength : Math.max(12, trackLength * (pageSize / range));
	}

	private function trackTravel():Float return Math.max(0, (controlHeight - 2 * ARROW_HEIGHT) - thumbHeight());

	private function onTrackClick(event:MouseEvent):Void {
		if (!enabled || thumb == null) return;
		var localY = trackHolder.mouseY;
		if (localY < thumb.y) scrollTo(value - pageSize); else if (localY > thumb.y + thumbHeight()) scrollTo(value + pageSize);
	}

	private function onThumbDown(_:MouseEvent):Void {
		if (!enabled || stage == null) return;
		dragging = true;
		thumbPressed = true;
		dragOffset = thumb.mouseY;
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onDrag);
		stage.addEventListener(MouseEvent.MOUSE_UP, onDragEnd);
		redraw();
	}

	private function onDrag(_:MouseEvent):Void {
		if (!dragging || trackTravel() <= 0) return;
		var fraction = (mouseY - ARROW_HEIGHT - dragOffset) / trackTravel();
		scrollTo(minimum + Math.max(0, Math.min(1, fraction)) * (maximum - minimum));
	}

	private function onDragEnd(_:MouseEvent):Void {
		dragging = false;
		thumbPressed = false;
		removeDragListeners();
		redraw();
	}

	private function removeDragListeners():Void {
		if (stage != null) {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDrag);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onDragEnd);
		}
	}

	private function dispatchScroll():Void {
		if (onScroll != null) onScroll(value);
		dispatchEvent(new Event(Event.SCROLL));
	}

	private function set_value(next:Float):Float { value = Math.max(minimum, Math.min(maximum, next)); redraw(); return value; }
	private function scrollFromWheel(event:MouseEvent):Void scrollTo(value - event.delta * lineStep);
	private function scrollFromKey(event:KeyboardEvent):Void {
		if (event.keyCode == Keyboard.UP || event.keyCode == Keyboard.LEFT) scrollTo(value - lineStep);
		if (event.keyCode == Keyboard.DOWN || event.keyCode == Keyboard.RIGHT) scrollTo(value + lineStep);
		if (event.keyCode == Keyboard.PAGE_UP) scrollTo(value - pageSize);
		if (event.keyCode == Keyboard.PAGE_DOWN) scrollTo(value + pageSize);
		if (event.keyCode == Keyboard.HOME) scrollTo(minimum);
		if (event.keyCode == Keyboard.END) scrollTo(maximum);
	}
}
