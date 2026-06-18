package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
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
	private static final SKIN_GRID = new Rectangle(2.25, 1.45, 147.8, 18.6);

	private var skinHolder:Sprite;
	private var skinCache:Map<String, DisplayObject> = new Map();
	private var currentSkin:Null<DisplayObject>;
	private var field:TextField;

	private var boxWidth:Float = 100;
	private var boxHeight:Float = 22;
	private var nativeWidth:Float = SKIN_NOMINAL_WIDTH;
	private var nativeHeight:Float = SKIN_NOMINAL_HEIGHT;

	private var _enabled:Bool = true;

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
		addChild(skinHolder);

		field = new TextField();
		field.type = TextFieldType.INPUT;
		field.multiline = false;
		field.wordWrap = false;
		field.selectable = true;
		field.mouseEnabled = true;
		field.autoSize = TextFieldAutoSize.NONE;
		field.defaultTextFormat = new TextFormat(
			FontResolver.resolve("Arial"), 11, 0x111111, false, false, false, null, null, TextFormatAlign.LEFT
		);
		field.text = text;
		// Re-broadcast the inner field's CHANGE so external listeners can bind to
		// the component itself, like fl does.
		field.addEventListener(Event.CHANGE, function(_) dispatchEvent(new Event(Event.CHANGE)));
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
		return field.type == TextFieldType.INPUT;
	}

	private function set_editable(value:Bool):Bool {
		field.type = value ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
		return value;
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
		field.mouseEnabled = value;
		field.selectable = value;
		field.type = value && get_editable() ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
		redraw();
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

	private function layout():Void {
		field.x = 4;
		field.width = Math.max(1, boxWidth - 8);
		field.height = boxHeight - 4;
		field.y = (boxHeight - field.height) / 2;
	}
}
