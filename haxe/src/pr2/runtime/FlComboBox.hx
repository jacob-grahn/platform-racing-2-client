package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

/**
	A faithful port of the Flash `fl.controls.ComboBox` component (library item
	`Components/ComboBox`, linkage `fl.controls.ComboBox`).

	PR2 source (server/user select, search mode/order/dir, editor menus) drives
	the non-editable variant through:

	  - `prompt` — placeholder shown while nothing is selected.
	  - `enabled` — greys the control and swallows input.
	  - `addItem` / `removeAll` / `dataProvider` / `length` — the item model.
	  - `selectedItem` / `selectedIndex` — current selection (get/set).
	  - `Event.CHANGE` — dispatched when the selection changes.

	The collapsed box uses the real `ComboBox_*Skin` background (which includes
	the dropdown arrow), nine-sliced to size like `FlButton`. The open list is a
	scrollless column of rows drawn over everything else.
**/
class FlComboBox extends Sprite {
	private static inline final SKIN_PREFIX:String = "Components/Component Assets/ComboBoxSkins/ComboBox_";
	private static inline final SKIN_NOMINAL_WIDTH:Float = 130;
	private static inline final SKIN_NOMINAL_HEIGHT:Float = 22;
	private static final SKIN_GRID = new Rectangle(4, 13.45, 120.75, 4.6);

	private var skinHolder:Sprite;
	private var captionField:TextField;
	private var dropdown:Sprite;
	private var skinCache:Map<String, DisplayObject> = new Map();
	private var currentSkin:Null<DisplayObject>;

	private var boxWidth:Float = 100;
	private var boxHeight:Float = 22;
	private var nativeWidth:Float = SKIN_NOMINAL_WIDTH;
	private var nativeHeight:Float = SKIN_NOMINAL_HEIGHT;

	private var mouseOver:Bool = false;
	private var open:Bool = false;

	private var _enabled:Bool = true;
	private var _prompt:Null<String> = null;
	private var _selectedIndex:Int = -1;

	/** Field read off each item object to produce its caption. */
	public var labelField:String = "label";
	/** Max rows shown before the open list would normally scroll (fl default 5). */
	public var rowCount:Int = 5;

	public var dataProvider(default, null):FlDataProvider = new FlDataProvider();

	public var enabled(get, set):Bool;
	public var prompt(get, set):String;
	public var selectedIndex(get, set):Int;
	public var selectedItem(get, set):Dynamic;
	public var length(get, never):Int;

	public function new(prompt:String = "") {
		super();
		_prompt = prompt == "" ? null : prompt;

		skinHolder = new Sprite();
		addChild(skinHolder);

		captionField = new TextField();
		captionField.selectable = false;
		captionField.mouseEnabled = false;
		captionField.autoSize = TextFieldAutoSize.NONE;
		captionField.multiline = false;
		captionField.defaultTextFormat = new TextFormat(
			FontResolver.resolve("Arial"), 11, 0x000000, false, false, false, null, null, TextFormatAlign.LEFT
		);
		addChild(captionField);

		dropdown = new Sprite();
		dropdown.visible = false;
		addChild(dropdown);

		mouseChildren = true;
		buttonMode = true;
		useHandCursor = true;

		addEventListener(MouseEvent.ROLL_OVER, onRollOver);
		addEventListener(MouseEvent.ROLL_OUT, onRollOut);
		addEventListener(MouseEvent.CLICK, onClick);

		redraw();
		layoutLabel();
		refreshLabel();
	}

	public function setSize(width:Float, height:Float):Void {
		boxWidth = width;
		boxHeight = height;
		for (skin in skinCache) {
			FlSkin.nineSlice(skin, SKIN_GRID, nativeWidth, nativeHeight, boxWidth, boxHeight);
		}
		layoutLabel();
		if (open) {
			buildDropdown();
		}
	}

	// --- item model ---------------------------------------------------------

	public function addItem(item:Dynamic):Void {
		dataProvider.addItem(item);
	}

	public function addItemAt(item:Dynamic, index:Int):Void {
		dataProvider.addItemAt(item, index);
	}

	public function removeAll():Void {
		dataProvider.removeAll();
		_selectedIndex = -1;
		refreshLabel();
	}

	private function get_length():Int {
		return dataProvider.length;
	}

	// --- selection ----------------------------------------------------------

	private function get_selectedIndex():Int {
		return _selectedIndex;
	}

	private function set_selectedIndex(value:Int):Int {
		if (value < -1 || value >= dataProvider.length) {
			value = -1;
		}
		_selectedIndex = value;
		refreshLabel();
		return _selectedIndex;
	}

	private function get_selectedItem():Dynamic {
		return _selectedIndex < 0 ? null : dataProvider.getItemAt(_selectedIndex);
	}

	private function set_selectedItem(item:Dynamic):Dynamic {
		_selectedIndex = dataProvider.getItemIndex(item);
		refreshLabel();
		return item;
	}

	// --- prompt / enabled ---------------------------------------------------

	private function get_prompt():String {
		return _prompt == null ? "" : _prompt;
	}

	private function set_prompt(value:String):String {
		_prompt = value == null || value == "" ? null : value;
		refreshLabel();
		return get_prompt();
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
		buttonMode = value;
		useHandCursor = value;
		if (!value) {
			mouseOver = false;
			closeDropdown();
		}
		redraw();
		return _enabled;
	}

	// --- interaction --------------------------------------------------------

	private function onRollOver(_):Void {
		mouseOver = true;
		redraw();
	}

	private function onRollOut(_):Void {
		mouseOver = false;
		redraw();
	}

	private function onClick(event:MouseEvent):Void {
		// Clicks inside the open list are handled by the row listeners; only the
		// collapsed box toggles the dropdown.
		if (!_enabled || dropdown.visible && event.target != this && isDropdownChild(event.target)) {
			return;
		}
		if (open) {
			closeDropdown();
		} else {
			openDropdown();
		}
	}

	private function isDropdownChild(target:Dynamic):Bool {
		var obj = Std.downcast(target, DisplayObject);
		while (obj != null) {
			if (obj == dropdown) {
				return true;
			}
			obj = obj.parent;
		}
		return false;
	}

	private function openDropdown():Void {
		if (dataProvider.length == 0) {
			return;
		}
		open = true;
		buildDropdown();
		dropdown.visible = true;
		setChildIndex(dropdown, numChildren - 1);
	}

	private function closeDropdown():Void {
		open = false;
		dropdown.visible = false;
	}

	private function buildDropdown():Void {
		while (dropdown.numChildren > 0) {
			dropdown.removeChildAt(0);
		}
		var rowHeight = boxHeight;
		var bg = new Shape();
		bg.graphics.beginFill(0xFFFFFF);
		bg.graphics.lineStyle(1, 0x7C8EA0);
		bg.graphics.drawRect(0, 0, boxWidth, rowHeight * dataProvider.length);
		bg.graphics.endFill();
		dropdown.addChild(bg);

		for (i in 0...dataProvider.length) {
			var row = makeRow(i, rowHeight);
			row.y = i * rowHeight;
			dropdown.addChild(row);
		}
		dropdown.y = boxHeight;
	}

	private function makeRow(index:Int, rowHeight:Float):Sprite {
		var row = new Sprite();
		row.buttonMode = true;
		row.useHandCursor = true;
		row.mouseChildren = false;

		var bg = new Shape();
		var selectedRow = index == _selectedIndex;
		bg.graphics.beginFill(selectedRow ? 0x2A5A8C : 0xFFFFFF, selectedRow ? 1 : 0.01);
		bg.graphics.drawRect(0, 0, boxWidth, rowHeight);
		bg.graphics.endFill();
		row.addChild(bg);

		var text = new TextField();
		text.selectable = false;
		text.mouseEnabled = false;
		text.autoSize = TextFieldAutoSize.NONE;
		text.width = boxWidth - 8;
		text.height = rowHeight;
		text.defaultTextFormat = new TextFormat(
			FontResolver.resolve("Arial"), 11, selectedRow ? 0xFFFFFF : 0x000000, false, false, false, null, null, TextFormatAlign.LEFT
		);
		text.text = itemToLabel(dataProvider.getItemAt(index));
		text.x = 4;
		text.y = (rowHeight - text.textHeight) / 2 - 2;
		row.addChild(text);

		row.addEventListener(MouseEvent.CLICK, function(_) selectFromList(index));
		return row;
	}

	private function selectFromList(index:Int):Void {
		closeDropdown();
		var changed = index != _selectedIndex;
		_selectedIndex = index;
		refreshLabel();
		if (changed) {
			dispatchEvent(new Event(Event.CHANGE));
		}
	}

	// --- rendering ----------------------------------------------------------

	private function currentStateName():String {
		if (!_enabled) {
			return "disabledSkin";
		}
		if (open) {
			return "downSkin";
		}
		return mouseOver ? "overSkin" : "upSkin";
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

	private function refreshLabel():Void {
		captionField.text = _selectedIndex < 0
			? (_prompt == null ? "" : _prompt)
			: itemToLabel(dataProvider.getItemAt(_selectedIndex));
	}

	private function itemToLabel(item:Dynamic):String {
		if (item == null) {
			return "";
		}
		if (Std.isOfType(item, String)) {
			return item;
		}
		if (Reflect.hasField(item, labelField)) {
			var value = Reflect.field(item, labelField);
			return value == null ? "" : Std.string(value);
		}
		return Std.string(item);
	}

	private function layoutLabel():Void {
		captionField.x = 5;
		captionField.width = Math.max(1, boxWidth - 24); // leave room for the arrow
		captionField.height = boxHeight;
		captionField.y = (boxHeight - (captionField.textHeight + 4)) / 2;
	}
}
