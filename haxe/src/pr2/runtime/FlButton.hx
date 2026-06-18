package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

/**
	A faithful port of the Flash `fl.controls.Button` component (library item
	`Components/Button`, linkage `fl.controls.Button`).

	The original is a toggle-capable push button skinned by the nine
	`Components/Component Assets/ButtonSkins/Button_*Skin` symbols. Callers in the
	PR2 source treat it as a plain interactive object plus four members:

	  - `label` — the centred caption; reassigned at runtime (the player popup
	    flips "Follow" ↔ "Unfollow", "Add to Friends" ↔ "Remove Friend", …).
	  - `enabled` — greys the button out and swallows mouse input (guests get
	    the social buttons disabled).
	  - `selected` / `toggle` — sticky on/off state for toggle buttons.
	  - `MouseEvent.CLICK` — dispatched natively because we extend `Sprite`.

	The skins are real library symbols, instantiated through `PR2MovieClip` and
	swapped per mouse state, then nine-sliced to the button size so the rounded
	corners stay crisp at the default 100×22 (the fl authoring default).
**/
class FlButton extends Sprite {
	// The skin symbols author at 82×22 with a 9-slice grid of left=7, right=75,
	// top=5, bottom=16 (see Button_upSkin.xml scaleGrid* attributes).
	private static inline final SKIN_NATIVE_WIDTH:Float = 82;
	private static inline final SKIN_NATIVE_HEIGHT:Float = 22;
	private static final SKIN_GRID = new Rectangle(7, 5, 68, 11);

	private static inline final SKIN_PREFIX:String = "Components/Component Assets/ButtonSkins/Button_";

	private var skinHolder:Sprite;
	private var textField:TextField;
	private var skinCache:Map<String, DisplayObject> = new Map();
	private var currentSkin:Null<DisplayObject>;

	private var buttonWidth:Float = 100;
	private var buttonHeight:Float = 22;

	private var mouseOver:Bool = false;
	private var mouseDown:Bool = false;

	private var _label:String;
	private var _enabled:Bool = true;
	private var _selected:Bool = false;

	/** When true the button keeps its pressed (`selected`) state after a click. */
	public var toggle:Bool = false;

	public var label(get, set):String;
	public var enabled(get, set):Bool;
	public var selected(get, set):Bool;

	public function new(label:String = "Button") {
		super();
		_label = label;

		skinHolder = new Sprite();
		addChild(skinHolder);

		textField = new TextField();
		textField.selectable = false;
		textField.mouseEnabled = false;
		textField.autoSize = TextFieldAutoSize.NONE;
		textField.multiline = false;
		textField.defaultTextFormat = new TextFormat(
			FontResolver.resolve("Arial"), 11, 0x000000, false, false, false, null, null, TextFormatAlign.CENTER
		);
		textField.text = _label;
		addChild(textField);

		mouseChildren = false;
		buttonMode = true;
		useHandCursor = true;

		addEventListener(MouseEvent.ROLL_OVER, onRollOver);
		addEventListener(MouseEvent.ROLL_OUT, onRollOut);
		addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		// Native CLICK still reaches external listeners; this one only maintains
		// the sticky toggle state, matching fl.controls.Button.
		addEventListener(MouseEvent.CLICK, onClick);

		redraw();
	}

	/** Resize the button; skins are nine-sliced to the new dimensions. */
	public function setSize(width:Float, height:Float):Void {
		buttonWidth = width;
		buttonHeight = height;
		// Force every cached skin to be re-laid-out at the new size.
		for (skin in skinCache) {
			layoutSkin(skin);
		}
		layoutLabel();
	}

	private function get_label():String {
		return _label;
	}

	private function set_label(value:String):String {
		_label = value == null ? "" : value;
		textField.text = _label;
		layoutLabel();
		return _label;
	}

	private function get_enabled():Bool {
		return _enabled;
	}

	private function set_enabled(value:Bool):Bool {
		if (_enabled == value) {
			return _enabled;
		}
		_enabled = value;
		// A disabled fl button shows no hand cursor and ignores the mouse.
		mouseEnabled = value;
		buttonMode = value;
		useHandCursor = value;
		if (!value) {
			mouseOver = false;
			mouseDown = false;
		}
		redraw();
		return _enabled;
	}

	private function get_selected():Bool {
		return _selected;
	}

	private function set_selected(value:Bool):Bool {
		if (_selected == value) {
			return _selected;
		}
		_selected = value;
		redraw();
		return _selected;
	}

	private function onRollOver(_):Void {
		mouseOver = true;
		redraw();
	}

	private function onRollOut(_):Void {
		mouseOver = false;
		mouseDown = false;
		redraw();
	}

	private function onMouseDown(_):Void {
		mouseDown = true;
		redraw();
	}

	private function onMouseUp(_):Void {
		mouseDown = false;
		redraw();
	}

	private function onClick(_):Void {
		if (toggle) {
			selected = !_selected;
		}
	}

	/** fl mouse-state -> skin-symbol suffix, accounting for selected/disabled. */
	private function currentStateName():String {
		if (!_enabled) {
			return _selected ? "selectedDisabledSkin" : "disabledSkin";
		}
		var phase = mouseDown ? "down" : (mouseOver ? "over" : "up");
		if (_selected) {
			return "selected" + phase.charAt(0).toUpperCase() + phase.substr(1) + "Skin";
		}
		return phase + "Skin";
	}

	private function redraw():Void {
		var skin = skinForState(currentStateName());
		if (skin == currentSkin) {
			return;
		}
		if (currentSkin != null && currentSkin.parent == skinHolder) {
			skinHolder.removeChild(currentSkin);
		}
		currentSkin = skin;
		if (skin != null) {
			skinHolder.addChild(skin);
		}
	}

	private function skinForState(state:String):Null<DisplayObject> {
		var cached = skinCache.get(state);
		if (cached != null) {
			return cached;
		}
		var symbol = AssetLibrary.getSymbol(SKIN_PREFIX + state);
		if (symbol == null) {
			return null;
		}
		var skin:DisplayObject = new PR2MovieClip(symbol);
		try {
			skin.scale9Grid = SKIN_GRID;
		} catch (_:Dynamic) {
			// Some targets reject scale9Grid on vector sprites; fall back to a
			// plain scale, which still fills the button (corners stretch a touch).
		}
		layoutSkin(skin);
		skinCache.set(state, skin);
		return skin;
	}

	private function layoutSkin(skin:DisplayObject):Void {
		skin.scaleX = buttonWidth / SKIN_NATIVE_WIDTH;
		skin.scaleY = buttonHeight / SKIN_NATIVE_HEIGHT;
	}

	private function layoutLabel():Void {
		textField.width = buttonWidth;
		textField.height = textField.textHeight + 4;
		textField.x = 0;
		textField.y = (buttonHeight - textField.height) / 2;
	}
}
