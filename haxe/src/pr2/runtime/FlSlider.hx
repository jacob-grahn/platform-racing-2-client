package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;

/**
	A faithful port of the Flash `fl.controls.Slider` component (library item
	`Components/Slider`, linkage `fl.controls.Slider`). Used by the stat/options
	/size/quantity menus.

	A horizontal track (`SliderTrack_skin`) with a draggable thumb
	(`SliderThumb_*Skin`). PR2 source drives it through:

	  - `value` / `minimum` / `maximum` — the model (defaults 0..100, like the
	    stat and volume sliders).
	  - `snapInterval` — value quantisation (defaults to 1).
	  - `FlSliderEvent.CHANGE` (== `Event.CHANGE`) on value change, plus
	    `THUMB_PRESS` / `THUMB_RELEASE` around a drag.

	Replaces the inert generic placeholder with the real artwork and drag.
**/
class FlSlider extends Sprite {
	private static inline final SKIN_PREFIX:String = "Components/Component Assets/SliderSkins/Slider";
	private static inline final TRACK_NOMINAL_WIDTH:Float = 80;
	private static inline final TRACK_NOMINAL_HEIGHT:Float = 4;
	private static final TRACK_GRID = new Rectangle(2.25, 0, 75.75, 4);

	private var trackHolder:Sprite;
	private var thumbHolder:Sprite;
	private var thumbCache:Map<String, DisplayObject> = new Map();
	private var currentThumb:Null<DisplayObject>;

	private var trackWidth:Float = 100;
	private var trackHeight:Float = 4;
	private var trackNativeWidth:Float = TRACK_NOMINAL_WIDTH;
	private var trackNativeHeight:Float = TRACK_NOMINAL_HEIGHT;

	private var _value:Float = 0;
	private var _minimum:Float = 0;
	private var _maximum:Float = 100;
	private var _enabled:Bool = true;

	private var mouseOver:Bool = false;
	private var dragging:Bool = false;

	/** Value quantisation step; fl defaults to 0 (continuous) but PR2 uses 1. */
	public var snapInterval:Float = 1;

	public var value(get, set):Float;
	public var minimum(get, set):Float;
	public var maximum(get, set):Float;
	public var enabled(get, set):Bool;

	public function new(width:Float = 100) {
		super();
		trackWidth = width;

		trackHolder = new Sprite();
		addChild(trackHolder);

		thumbHolder = new Sprite();
		thumbHolder.buttonMode = true;
		thumbHolder.useHandCursor = true;
		thumbHolder.mouseChildren = false;
		addChild(thumbHolder);

		thumbHolder.addEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
		addEventListener(MouseEvent.ROLL_OVER, function(_) { mouseOver = true; redrawThumb(); });
		addEventListener(MouseEvent.ROLL_OUT, function(_) { mouseOver = false; redrawThumb(); });
		// Clicking the track jumps the value toward the click point.
		addEventListener(MouseEvent.MOUSE_DOWN, onTrackDown);

		layoutTrack();
		redrawThumb();
		layoutThumb();
	}

	public function setSize(width:Float, height:Float):Void {
		trackWidth = width;
		layoutTrack();
		layoutThumb();
	}

	// --- model --------------------------------------------------------------

	private function get_value():Float {
		return _value;
	}

	private function set_value(v:Float):Float {
		_value = clamp(snap(v));
		layoutThumb();
		return _value;
	}

	private function get_minimum():Float {
		return _minimum;
	}

	private function set_minimum(v:Float):Float {
		_minimum = v;
		_value = clamp(_value);
		layoutThumb();
		return _minimum;
	}

	private function get_maximum():Float {
		return _maximum;
	}

	private function set_maximum(v:Float):Float {
		_maximum = v;
		_value = clamp(_value);
		layoutThumb();
		return _maximum;
	}

	private function get_enabled():Bool {
		return _enabled;
	}

	private function set_enabled(value:Bool):Bool {
		if (_enabled == value) {
			return _enabled;
		}
		_enabled = value;
		mouseEnabled = value;
		mouseChildren = value;
		thumbHolder.buttonMode = value;
		thumbHolder.useHandCursor = value;
		redrawThumb();
		return _enabled;
	}

	private function clamp(v:Float):Float {
		if (v < _minimum) {
			return _minimum;
		}
		if (v > _maximum) {
			return _maximum;
		}
		return v;
	}

	private function snap(v:Float):Float {
		if (snapInterval <= 0) {
			return v;
		}
		return _minimum + Math.round((v - _minimum) / snapInterval) * snapInterval;
	}

	// --- interaction --------------------------------------------------------

	private function onThumbDown(event:MouseEvent):Void {
		if (!_enabled) {
			return;
		}
		dragging = true;
		redrawThumb();
		dispatchEvent(new FlSliderEvent(FlSliderEvent.THUMB_PRESS, _value));
		if (stage != null) {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onDrag);
			stage.addEventListener(MouseEvent.MOUSE_UP, onDragEnd);
		}
		event.stopPropagation();
	}

	private function onTrackDown(event:MouseEvent):Void {
		if (!_enabled || dragging) {
			return;
		}
		updateFromMouse();
	}

	private function onDrag(event:MouseEvent):Void {
		if (!dragging) {
			return;
		}
		updateFromMouse();
		dispatchEvent(new FlSliderEvent(FlSliderEvent.THUMB_DRAG, _value));
	}

	private function onDragEnd(event:MouseEvent):Void {
		if (!dragging) {
			return;
		}
		dragging = false;
		redrawThumb();
		if (stage != null) {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDrag);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onDragEnd);
		}
		dispatchEvent(new FlSliderEvent(FlSliderEvent.THUMB_RELEASE, _value));
	}

	private function updateFromMouse():Void {
		var travel = trackWidth;
		if (travel <= 0) {
			return;
		}
		var fraction = this.mouseX / travel;
		if (fraction < 0) {
			fraction = 0;
		}
		if (fraction > 1) {
			fraction = 1;
		}
		var next = clamp(snap(_minimum + fraction * (_maximum - _minimum)));
		if (next != _value) {
			_value = next;
			layoutThumb();
			dispatchEvent(new FlSliderEvent(FlSliderEvent.CHANGE, _value));
		}
	}

	// --- layout / skins -----------------------------------------------------

	private function layoutTrack():Void {
		while (trackHolder.numChildren > 0) {
			trackHolder.removeChildAt(0);
		}
		var skin = FlSkin.create(SKIN_PREFIX + "Track_skin");
		if (skin != null) {
			var bounds = FlSkin.nativeBounds(skin, TRACK_NOMINAL_WIDTH, TRACK_NOMINAL_HEIGHT);
			trackNativeWidth = bounds.width;
			trackNativeHeight = bounds.height;
			FlSkin.nineSlice(skin, TRACK_GRID, trackNativeWidth, trackNativeHeight, trackWidth, trackNativeHeight);
			trackHolder.addChild(skin);
		} else {
			var shape = new Shape();
			shape.graphics.beginFill(0xAAAAAA);
			shape.graphics.drawRect(0, 0, trackWidth, trackHeight);
			shape.graphics.endFill();
			trackHolder.addChild(shape);
		}
		trackHolder.y = 0;
	}

	private function thumbState():String {
		if (!_enabled) {
			return "Thumb_disabledSkin";
		}
		if (dragging) {
			return "Thumb_downSkin";
		}
		return mouseOver ? "Thumb_overSkin" : "Thumb_upSkin";
	}

	private function redrawThumb():Void {
		var thumb = thumbForState(thumbState());
		if (thumb == currentThumb) {
			return;
		}
		if (currentThumb != null && currentThumb.parent == thumbHolder) {
			thumbHolder.removeChild(currentThumb);
		}
		currentThumb = thumb;
		if (thumb != null) {
			thumbHolder.addChild(thumb);
		}
		layoutThumb();
	}

	private function thumbForState(state:String):Null<DisplayObject> {
		var cached = thumbCache.get(state);
		if (cached != null) {
			return cached;
		}
		var skin = FlSkin.create(SKIN_PREFIX + state);
		if (skin == null) {
			var shape = new Shape();
			shape.graphics.beginFill(0x6E7B88);
			shape.graphics.drawRect(-5, -8, 10, 16);
			shape.graphics.endFill();
			var holder = new Sprite();
			holder.addChild(shape);
			thumbCache.set(state, holder);
			return holder;
		}
		thumbCache.set(state, skin);
		return skin;
	}

	private function layoutThumb():Void {
		var range = _maximum - _minimum;
		var fraction = range <= 0 ? 0 : (_value - _minimum) / range;
		thumbHolder.x = fraction * trackWidth;
		var thumbH = currentThumb == null || currentThumb.height <= 0 ? 16 : currentThumb.height;
		thumbHolder.y = trackNativeHeight / 2 - thumbH / 2;
	}
}
