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
	A faithful port of the Flash `fl.controls.TextArea` component (library item
	`Components/TextArea`, linkage `fl.controls.TextArea`). Used by RaceChat and
	the OutfitPopup.

	A multiline, word-wrapping `TextField` drawn over the `TextArea_upSkin`
	background with an attached `FlUIScrollBar` down the right edge. Mirrors the
	bits of the fl API the source touches: `text`, `htmlText`, `editable`,
	`append`, `setSize`, and `Event.CHANGE`. Replaces the generic grey
	placeholder.
**/
class FlTextArea extends Sprite {
	private static inline final SKIN_PREFIX:String = "Components/Component Assets/TextAreaSkins/TextArea_";
	private static inline final SKIN_NOMINAL_WIDTH:Float = 152;
	private static inline final SKIN_NOMINAL_HEIGHT:Float = 22;
	private static final SKIN_GRID = new Rectangle(1.55, 1.55, 148.5, 18.4);

	private var skinHolder:Sprite;
	private var skinCache:Map<String, DisplayObject> = new Map();
	private var currentSkin:Null<DisplayObject>;
	private var field:TextField;
	private var scrollBar:FlUIScrollBar;

	private var boxWidth:Float = 160;
	private var boxHeight:Float = 100;
	private var nativeWidth:Float = SKIN_NOMINAL_WIDTH;
	private var nativeHeight:Float = SKIN_NOMINAL_HEIGHT;

	private var _enabled:Bool = true;

	public var text(get, set):String;
	public var htmlText(get, set):String;
	public var editable(get, set):Bool;
	public var enabled(get, set):Bool;
	public var textField(get, never):TextField;
	public var verticalScrollBar(get, never):FlUIScrollBar;

	public function new(width:Float = 160, height:Float = 100) {
		super();
		boxWidth = width;
		boxHeight = height;

		skinHolder = new Sprite();
		addChild(skinHolder);

		field = new TextField();
		field.type = TextFieldType.DYNAMIC;
		field.multiline = true;
		field.wordWrap = true;
		field.selectable = true;
		field.mouseEnabled = true;
		field.autoSize = TextFieldAutoSize.NONE;
		field.defaultTextFormat = new TextFormat(
			FontResolver.resolve("Arial"), 11, 0x111111, false, false, false, null, null, TextFormatAlign.LEFT
		);
		field.addEventListener(Event.CHANGE, onFieldChange);
		field.addEventListener(Event.SCROLL, function(_) scrollBar.syncFromTarget());
		addChild(field);

		scrollBar = new FlUIScrollBar(height);
		scrollBar.scrollTarget = field;
		addChild(scrollBar);

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

	public function append(value:String):Void {
		field.appendText(value);
		afterTextChange();
	}

	private function onFieldChange(_):Void {
		afterTextChange();
		dispatchEvent(new Event(Event.CHANGE));
	}

	private function afterTextChange():Void {
		scrollBar.syncFromTarget();
	}

	private function get_text():String {
		return field.text;
	}

	private function set_text(value:String):String {
		field.text = value == null ? "" : value;
		afterTextChange();
		return field.text;
	}

	private function get_htmlText():String {
		return field.htmlText;
	}

	private function set_htmlText(value:String):String {
		field.htmlText = value == null ? "" : value;
		afterTextChange();
		return field.htmlText;
	}

	private function get_editable():Bool {
		return field.type == TextFieldType.INPUT;
	}

	private function set_editable(value:Bool):Bool {
		field.type = value ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
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
		redraw();
		return _enabled;
	}

	private function get_textField():TextField {
		return field;
	}

	private function get_verticalScrollBar():FlUIScrollBar {
		return scrollBar;
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
		field.x = 3;
		field.y = 3;
		field.width = Math.max(1, boxWidth - FlUIScrollBar.WIDTH - 6);
		field.height = Math.max(1, boxHeight - 6);

		scrollBar.x = boxWidth - FlUIScrollBar.WIDTH - 1;
		scrollBar.y = 1;
		scrollBar.setSize(boxHeight - 2);
		scrollBar.syncFromTarget();
	}
}
