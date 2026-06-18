package pr2.runtime;

import openfl.events.Event;

/**
	Port of `fl.events.SliderEvent`, dispatched by `FlSlider`. The fl type
	strings are reused verbatim — notably `CHANGE == "change"`, the same string
	as `openfl.events.Event.CHANGE`, so a listener bound to either name receives
	the event (the source binds both `Event.CHANGE` and `SliderEvent.CHANGE`).
**/
class FlSliderEvent extends Event {
	public static inline final CHANGE:String = "change";
	public static inline final THUMB_PRESS:String = "thumbPress";
	public static inline final THUMB_DRAG:String = "thumbDrag";
	public static inline final THUMB_RELEASE:String = "thumbRelease";

	public var value:Float;

	public function new(type:String, value:Float, bubbles:Bool = false, cancelable:Bool = false) {
		super(type, bubbles, cancelable);
		this.value = value;
	}

	override public function clone():Event {
		return new FlSliderEvent(type, value, bubbles, cancelable);
	}
}
