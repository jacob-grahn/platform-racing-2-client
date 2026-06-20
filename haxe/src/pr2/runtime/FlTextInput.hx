package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

/**
	A faithful port of the Flash `fl.controls.TextInput` component (library item
	`Components/TextInput`, linkage `fl.controls.TextInput`).

	The original is a single-line editable `TextField` drawn over the
	`TextInput_upSkin` / `TextInput_disabledSkin` background. Callers read/write
	`text`, set `displayAsPassword`, `restrict`, `maxChars`, toggle `editable`,
	and listen for `Event.CHANGE`. We forward those onto an inner `TextField`
	and nine-slice the real skin behind it, replacing the old fixed 100x22
	borderless placeholder.
**/
class FlTextInput extends Sprite {
	private static inline final SKIN_PREFIX:String = "Components/Component Assets/TextInputSkins/TextInput_";
	private static inline final SKIN_NOMINAL_WIDTH:Float = 152;
	private static inline final SKIN_NOMINAL_HEIGHT:Float = 22;
	// The TextInput skins are one-pixel bevels. Only their white centre should
	// stretch; scaling the bevel itself makes narrow authored controls blurry.
	private static final SKIN_GRID = new Rectangle(1, 1, 150, 20);
	private static inline final FOCUS_SKIN:String = "Components/Component Assets/Shared/focusRectSkin";
	private static inline final FOCUS_NATIVE_WIDTH:Float = 82;
	private static inline final FOCUS_NATIVE_HEIGHT:Float = 22;
	private static final FOCUS_GRID = new Rectangle(4, 2, 74, 18);

	private var skinHolder:Sprite;
	private var focusSkin:Null<DisplayObject>;
	private var skinCache:Map<String, DisplayObject> = new Map();
	private var currentSkin:Null<DisplayObject>;
	private var field:TextField;

	private var boxWidth:Float = 100;
	private var boxHeight:Float = 22;
	private var nativeWidth:Float = SKIN_NOMINAL_WIDTH;
	private var nativeHeight:Float = SKIN_NOMINAL_HEIGHT;

	private var _enabled:Bool = true;
	private var _editable:Bool = true;
	private var _focused:Bool = false;

	public var text(get, set):String;
	public var displayAsPassword(get, set):Bool;
	public var editable(get, set):Bool;
	public var restrict(get, set):String;
	public var maxChars(get, set):Int;
	public var enabled(get, set):Bool;
	public var textField(get, never):TextField;

	public function new(text:String = "") {
		super();

		skinHolder = new Sprite();
		skinHolder.mouseEnabled = false;
		skinHolder.mouseChildren = false;
		addChild(skinHolder);

		focusSkin = FlSkin.create(FOCUS_SKIN);
		if (focusSkin != null) {
			focusSkin.visible = false;
			var interactiveFocusSkin = Std.downcast(focusSkin, InteractiveObject);
			if (interactiveFocusSkin != null) {
				interactiveFocusSkin.mouseEnabled = false;
			}
			addChild(focusSkin);
		}

		field = new TextField();
		field.type = TextFieldType.INPUT;
		field.multiline = false;
		field.wordWrap = false;
		field.selectable = true;
		field.mouseEnabled = true;
		field.autoSize = TextFieldAutoSize.NONE;
		field.defaultTextFormat = textFormatForState();
		field.text = text;
		// Re-broadcast the inner field's CHANGE so external listeners can bind to
		// the component itself, like fl does.
		field.addEventListener(Event.CHANGE, function(_) dispatchEvent(new Event(Event.CHANGE)));
		field.addEventListener(FocusEvent.FOCUS_IN, onFocusIn);
		field.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
		addChild(field);

		redraw();
		layout();
	}

	public function setSize(width:Float, height:Float):Void {
		boxWidth = width;
		boxHeight = height;
		for (skin in skinCache) {
			FlSkin.nineSlice(skin, SKIN_GRID, nativeWidth, nativeHeight, boxWidth, boxHeight);
		}
		layoutFocusSkin();
		layout();
	}

	private function get_text():String {
		return field.text;
	}

	private function set_text(value:String):String {
		field.text = value == null ? "" : value;
		return field.text;
	}

	private function get_displayAsPassword():Bool {
		return field.displayAsPassword;
	}

	private function set_displayAsPassword(value:Bool):Bool {
		field.displayAsPassword = value;
		return value;
	}

	private function get_editable():Bool {
		return _editable;
	}

	private function set_editable(value:Bool):Bool {
		_editable = value;
		updateFieldInteraction();
		return _editable;
	}

	private function get_restrict():String {
		return field.restrict;
	}

	private function set_restrict(value:String):String {
		field.restrict = value;
		return value;
	}

	private function get_maxChars():Int {
		return field.maxChars;
	}

	private function set_maxChars(value:Int):Int {
		field.maxChars = value;
		return value;
	}

	private function get_enabled():Bool {
		return _enabled;
	}

	private function set_enabled(value:Bool):Bool {
		if (_enabled == value) {
			return _enabled;
		}
		_enabled = value;
		if (!value) {
			_focused = false;
		}
		updateFieldInteraction();
		applyTextFormat();
		redraw();
		updateFocusSkin();
		return _enabled;
	}

	private function get_textField():TextField {
		return field;
	}

	private function redraw():Void {
		var skin = skinForState(_enabled ? "upSkin" : "disabledSkin");
		if (skin == currentSkin) {
			return;
		}
		if (currentSkin != null && currentSkin.parent == skinHolder) {
			skinHolder.removeChild(currentSkin);
		}
		currentSkin = skin;
		if (skin != null) {
			skinHolder.addChildAt(skin, 0);
		}
	}

	private function skinForState(state:String):Null<DisplayObject> {
		var cached = skinCache.get(state);
		if (cached != null) {
			return cached;
		}
		var skin = FlSkin.create(SKIN_PREFIX + state);
		if (skin == null) {
			return null;
		}
		var bounds = FlSkin.nativeBounds(skin, SKIN_NOMINAL_WIDTH, SKIN_NOMINAL_HEIGHT);
		nativeWidth = bounds.width;
		nativeHeight = bounds.height;
		FlSkin.nineSlice(skin, SKIN_GRID, nativeWidth, nativeHeight, boxWidth, boxHeight);
		skinCache.set(state, skin);
		return skin;
	}

	private function textFormatForState():TextFormat {
		return new TextFormat(
			FontResolver.resolve("Arial"), 11, _enabled ? 0x000000 : 0x999999,
			false, false, false, null, null, TextFormatAlign.LEFT
		);
	}

	private function applyTextFormat():Void {
		var format = textFormatForState();
		field.defaultTextFormat = format;
		field.setTextFormat(format);
	}

	private function updateFieldInteraction():Void {
		field.mouseEnabled = _enabled;
		field.selectable = _enabled;
		field.type = _enabled && _editable ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
	}

	private function onFocusIn(_):Void {
		_focused = _enabled;
		updateFocusSkin();
	}

	private function onFocusOut(_):Void {
		_focused = false;
		updateFocusSkin();
	}

	private function updateFocusSkin():Void {
		if (focusSkin != null) {
			focusSkin.visible = _focused && _enabled;
		}
	}

	private function layoutFocusSkin():Void {
		if (focusSkin != null) {
			FlSkin.nineSlice(focusSkin, FOCUS_GRID, FOCUS_NATIVE_WIDTH, FOCUS_NATIVE_HEIGHT, boxWidth, boxHeight);
		}
	}

	private function layout():Void {
		// fl.controls.TextInput uses UIComponent.TEXT_FIELD_PADDING (5px)
		// horizontally and leaves one pixel for the top/bottom skin bevel. This
		// also gives OpenFL's native selection and caret the same clipping bounds.
		field.x = 5;
		field.y = 1;
		field.width = Math.max(1, boxWidth - 10);
		field.height = Math.max(1, boxHeight - 2);
	}
}
