package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.ui.Keyboard;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.ui.StageFocus;

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
	the dropdown arrow), nine-sliced to size like `FlButton`. The open list uses
	the authored List, CellRenderer, and scrollbar skins above the stage content.
**/
@:allow(pr2.runtime.FlComponentsTest)
class FlComboBox extends Sprite {
	private static inline final SKIN_PREFIX:String = "Components/Component Assets/ComboBoxSkins/ComboBox_";
	private static inline final SKIN_NOMINAL_WIDTH:Float = 130;
	private static inline final SKIN_NOMINAL_HEIGHT:Float = 22;
	private static final SKIN_GRID = new Rectangle(4, 13.45, 120.75, 4.6);
	private static inline final LIST_SKIN:String = "Components/Component Assets/ListSkins/List_skin";
	private static inline final CELL_SKIN_PREFIX:String = "Components/Component Assets/CellRendererSkins/CellRenderer_";
	private static inline final CELL_NOMINAL_WIDTH:Float = 152;
	private static inline final CELL_NOMINAL_HEIGHT:Float = 22;
	private static inline final LIST_INSET:Float = 2;
	private static final LIST_GRID = new Rectangle(2, 2, 146, 18);
	private static final CELL_GRID = new Rectangle(1, 1, 150, 20);

	private var skinHolder:Sprite;
	private var captionField:TextField;
	private var dropdown:Sprite;
	private var rowsHolder:Sprite;
	private var rowsClip:Sprite;
	private var rowsMask:Shape;
	private var scrollBar:FlUIScrollBar;
	private var skinCache:Map<String, DisplayObject> = new Map();
	private var currentSkin:Null<DisplayObject>;

	private var boxWidth:Float = 100;
	private var boxHeight:Float = 22;
	private var nativeWidth:Float = SKIN_NOMINAL_WIDTH;
	private var nativeHeight:Float = SKIN_NOMINAL_HEIGHT;

	private var mouseOver:Bool = false;
	private var open:Bool = false;
	private var scrollOffset:Int = 0;
	private var hoveredIndex:Int = -1;

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
		rowsClip = new Sprite();
		rowsHolder = new Sprite();
		rowsClip.addChild(rowsHolder);
		rowsMask = new Shape();
		rowsClip.mask = rowsMask;
		scrollBar = new FlUIScrollBar(100);
		scrollBar.addEventListener(Event.SCROLL, onDropdownScroll);
		dropdown.addEventListener(MouseEvent.MOUSE_WHEEL, onDropdownWheel);
		addChild(dropdown);

		mouseChildren = true;
		buttonMode = true;
		useHandCursor = true;

		addEventListener(MouseEvent.ROLL_OVER, onRollOver);
		addEventListener(MouseEvent.ROLL_OUT, onRollOut);
		addEventListener(MouseEvent.CLICK, onClick);
		addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);

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
		updateCaptionFormat();
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
		if (!_enabled || event.target != this && isDropdownChild(event.target)) {
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
		if (!_enabled || open || dataProvider.length == 0) {
			return;
		}
		open = true;
		scrollOffset = initialScrollOffset();
		buildDropdown();
		dropdown.visible = true;
		if (stage != null) {
			var listHeight = dropdownHeight();
			var below = localToGlobal(new Point(0, boxHeight));
			var above = localToGlobal(new Point(0, -listHeight));
			var bottom = localToGlobal(new Point(0, boxHeight + listHeight));
			var localY = chooseDropdownBelow(stage.stageHeight, below.y, above.y, Math.abs(bottom.y - below.y)) ? boxHeight : -listHeight;
			var origin = localToGlobal(new Point(0, localY));
			var right = localToGlobal(new Point(dropdownWidth(), localY));
			var matrix = transform.concatenatedMatrix.clone();
			matrix.tx = clampDropdownX(origin.x, Math.abs(right.x - origin.x), stage.stageWidth);
			matrix.ty = origin.y;
			stage.addChild(dropdown);
			dropdown.transform.matrix = matrix;
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		} else {
			dropdown.y = boxHeight;
			setChildIndex(dropdown, numChildren - 1);
		}
		redraw();
		dispatchEvent(new Event(Event.OPEN));
	}

	private function closeDropdown():Void {
		if (!open) {
			return;
		}
		open = false;
		dropdown.visible = false;
		var ownerStage = dropdown.stage;
		if (ownerStage != null) {
			ownerStage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
			ownerStage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		if (dropdown.parent != this) {
			if (dropdown.parent != null) {
				dropdown.parent.removeChild(dropdown);
			}
			addChild(dropdown);
			dropdown.transform.matrix = new Matrix();
		}
		redraw();
		dispatchEvent(new Event(Event.CLOSE));
		StageFocus.reset();
	}

	private function onStageMouseDown(event:MouseEvent):Void {
		if (!isControlChild(event.target) && !isDropdownChild(event.target)) {
			closeDropdown();
		}
	}

	private function onKeyDown(event:KeyboardEvent):Void {
		if (open && event.keyCode == Keyboard.ESCAPE) {
			closeDropdown();
		}
	}

	private function onRemovedFromStage(_):Void {
		closeDropdown();
	}

	private function isControlChild(target:Dynamic):Bool {
		var obj = Std.downcast(target, DisplayObject);
		while (obj != null) {
			if (obj == this) {
				return true;
			}
			obj = obj.parent;
		}
		return false;
	}

	private static function chooseDropdownBelow(stageHeight:Float, belowY:Float, aboveY:Float, listHeight:Float):Bool {
		return belowY + listHeight <= stageHeight || aboveY < 0;
	}

	private static function clampDropdownX(x:Float, listWidth:Float, stageWidth:Float):Float {
		return Math.max(0, Math.min(x, stageWidth - listWidth));
	}

	private function buildDropdown():Void {
		while (dropdown.numChildren > 0) {
			dropdown.removeChildAt(0);
		}
		var height = dropdownHeight();
		var listSkin = FlSkin.create(LIST_SKIN);
		if (listSkin != null) {
			var bounds = FlSkin.nativeBounds(listSkin, 150, 100);
			FlSkin.nineSlice(listSkin, LIST_GRID, bounds.width, bounds.height, dropdownWidth(), height);
			dropdown.addChild(listSkin);
		} else {
			var bg = new Shape();
			bg.graphics.beginFill(0xFFFFFF);
			bg.graphics.lineStyle(1, 0x7C8EA0);
			bg.graphics.drawRect(0, 0, dropdownWidth(), height);
			bg.graphics.endFill();
			dropdown.addChild(bg);
		}

		rowsClip = new Sprite();
		rowsHolder = new Sprite();
		rowsClip.addChild(rowsHolder);
		rowsClip.x = LIST_INSET;
		rowsClip.y = LIST_INSET;
		dropdown.addChild(rowsClip);

		rowsMask = new Shape();
		rowsMask.graphics.beginFill(0xFFFFFF);
		rowsMask.graphics.drawRect(LIST_INSET, LIST_INSET, contentWidth(), visibleRowCount() * CELL_NOMINAL_HEIGHT);
		rowsMask.graphics.endFill();
		dropdown.addChild(rowsMask);
		rowsClip.mask = rowsMask;

		for (i in 0...dataProvider.length) {
			rowsHolder.addChild(makeRow(i));
		}
		layoutRows();

		if (needsScrollBar()) {
			scrollBar = new FlUIScrollBar(height - LIST_INSET * 2);
			scrollBar.x = dropdownWidth() - FlUIScrollBar.WIDTH - 1;
			scrollBar.y = LIST_INSET;
			scrollBar.setScrollProperties(visibleRowCount(), 1, maxScrollOffset() + 1);
			scrollBar.scrollPosition = scrollOffset + 1;
			scrollBar.addEventListener(Event.SCROLL, onDropdownScroll);
			dropdown.addChild(scrollBar);
		}
	}

	private function makeRow(index:Int):Sprite {
		var row = new Sprite();
		row.buttonMode = true;
		row.useHandCursor = true;
		row.mouseChildren = false;

		drawRow(row, index, false);
		row.addEventListener(MouseEvent.ROLL_OVER, function(_) {
			hoveredIndex = index;
			drawRow(row, index, true);
		});
		row.addEventListener(MouseEvent.ROLL_OUT, function(_) {
			if (hoveredIndex == index) hoveredIndex = -1;
			drawRow(row, index, false);
		});
		row.addEventListener(MouseEvent.CLICK, function(_) selectFromList(index));
		return row;
	}

	private function drawRow(row:Sprite, index:Int, hovered:Bool):Void {
		while (row.numChildren > 0) row.removeChildAt(0);
		var selectedRow = index == _selectedIndex;
		var state = selectedRow ? (hovered ? "selectedOverSkin" : "selectedUpSkin") : (hovered ? "overSkin" : "upSkin");
		var skin = FlSkin.create(CELL_SKIN_PREFIX + state);
		if (skin != null) {
			var bounds = FlSkin.nativeBounds(skin, CELL_NOMINAL_WIDTH, CELL_NOMINAL_HEIGHT);
			FlSkin.nineSlice(skin, CELL_GRID, bounds.width, bounds.height, contentWidth(), CELL_NOMINAL_HEIGHT);
			row.addChild(skin);
		} else {
			var bg = new Shape();
			bg.graphics.beginFill(hovered ? 0xDAF1FF : selectedRow ? 0x9AD8FF : 0xFFFFFF);
			bg.graphics.drawRect(0, 0, contentWidth(), CELL_NOMINAL_HEIGHT);
			bg.graphics.endFill();
			row.addChild(bg);
		}
		var text = new TextField();
		text.selectable = false;
		text.mouseEnabled = false;
		text.autoSize = TextFieldAutoSize.NONE;
		text.width = Math.max(1, contentWidth() - 10);
		text.height = CELL_NOMINAL_HEIGHT;
		text.defaultTextFormat = new TextFormat(FontResolver.resolve("Arial"), 11, 0x000000, false, false, false, null, null, TextFormatAlign.LEFT);
		text.text = itemToLabel(dataProvider.getItemAt(index));
		text.x = 5;
		text.y = (CELL_NOMINAL_HEIGHT - text.textHeight) / 2 - 2;
		row.addChild(text);
	}

	private function visibleRowCount():Int {
		return Std.int(Math.max(1, Math.min(rowCount, dataProvider.length)));
	}

	private function needsScrollBar():Bool {
		return dataProvider.length > visibleRowCount();
	}

	private function contentWidth():Float {
		return Math.max(1, dropdownWidth() - LIST_INSET * 2 - (needsScrollBar() ? FlUIScrollBar.WIDTH : 0));
	}

	private function dropdownWidth():Float {
		// Some authored instances shrink below the ComboBox skin's scale-grid
		// minimum. Flash lets the skin retain that minimum visual width, and its
		// List follows the rendered control rather than the nominal component box.
		return Math.max(boxWidth, skinHolder == null ? 0 : skinHolder.width);
	}

	private function dropdownHeight():Float {
		return visibleRowCount() * CELL_NOMINAL_HEIGHT + LIST_INSET * 2;
	}

	private function maxScrollOffset():Int {
		return Std.int(Math.max(0, dataProvider.length - visibleRowCount()));
	}

	private function initialScrollOffset():Int {
		if (_selectedIndex < 0) return 0;
		return Std.int(Math.min(maxScrollOffset(), Math.max(0, _selectedIndex - visibleRowCount() + 1)));
	}

	private function layoutRows():Void {
		for (i in 0...rowsHolder.numChildren) {
			rowsHolder.getChildAt(i).y = (i - scrollOffset) * CELL_NOMINAL_HEIGHT;
		}
	}

	private function onDropdownScroll(_):Void {
		scrollOffset = Std.int(Math.max(0, Math.min(maxScrollOffset(), scrollBar.scrollPosition - 1)));
		layoutRows();
	}

	private function onDropdownWheel(event:MouseEvent):Void {
		if (!needsScrollBar()) return;
		scrollOffset = Std.int(Math.max(0, Math.min(maxScrollOffset(), scrollOffset + (event.delta < 0 ? 1 : -1))));
		scrollBar.scrollPosition = scrollOffset + 1;
		layoutRows();
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
		layoutLabel();
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

	private function updateCaptionFormat():Void {
		captionField.defaultTextFormat = new TextFormat(
			FontResolver.resolve("Arial"), 11, _enabled ? 0x000000 : 0x999999, false, false, false, null, null, TextFormatAlign.LEFT
		);
		captionField.setTextFormat(captionField.defaultTextFormat);
	}
}
