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
	A faithful port of the Flash `fl.controls.List` component (library item
	`Components/List`, linkage `fl.controls.List`). Only one instance exists in
	the source (`level_browser/ListingPage`); the lobby listing was custom-ported
	instead, so this is the general-purpose fallback for any screen that wants the
	real List.

	Rows render the `dataProvider` items over the `List_skin` border with a
	`CellRenderer`-style selection highlight, an attached `FlUIScrollBar` when the
	content overflows, `selectedIndex` / `selectedItem`, and `Event.CHANGE` on a
	user pick.
**/
class FlList extends Sprite {
	private static inline final SKIN_NAME:String = "Components/Component Assets/ListSkins/List_skin";
	private static final SKIN_GRID = new Rectangle(2, 2, 146, 18);

	private var skinHolder:Sprite;
	private var rowsHolder:Sprite;
	private var rowsClip:Sprite;
	private var scrollBar:FlUIScrollBar;
	private var clipMask:Shape;

	private var boxWidth:Float = 150;
	private var boxHeight:Float = 100;
	private var scrollOffset:Int = 0;

	private var _selectedIndex:Int = -1;

	public var rowHeight:Float = 20;
	public var labelField:String = "label";
	public var dataProvider(default, null):FlDataProvider = new FlDataProvider();

	public var selectedIndex(get, set):Int;
	public var selectedItem(get, set):Dynamic;
	public var length(get, never):Int;

	public function new(width:Float = 150, height:Float = 100) {
		super();
		boxWidth = width;
		boxHeight = height;

		skinHolder = new Sprite();
		addChild(skinHolder);

		rowsClip = new Sprite();
		addChild(rowsClip);
		rowsHolder = new Sprite();
		rowsClip.addChild(rowsHolder);

		clipMask = new Shape();
		addChild(clipMask);
		rowsClip.mask = clipMask;

		scrollBar = new FlUIScrollBar(height);
		scrollBar.addEventListener(Event.SCROLL, onScroll);
		addChild(scrollBar);

		buildSkin();
		refresh();
	}

	public function setSize(width:Float, height:Float):Void {
		boxWidth = width;
		boxHeight = height;
		buildSkin();
		refresh();
	}

	// --- item model ---------------------------------------------------------

	public function addItem(item:Dynamic):Void {
		dataProvider.addItem(item);
		refresh();
	}

	public function removeAll():Void {
		dataProvider.removeAll();
		_selectedIndex = -1;
		scrollOffset = 0;
		refresh();
	}

	private function get_length():Int {
		return dataProvider.length;
	}

	private function get_selectedIndex():Int {
		return _selectedIndex;
	}

	private function set_selectedIndex(value:Int):Int {
		if (value < -1 || value >= dataProvider.length) {
			value = -1;
		}
		_selectedIndex = value;
		refresh();
		return _selectedIndex;
	}

	private function get_selectedItem():Dynamic {
		return _selectedIndex < 0 ? null : dataProvider.getItemAt(_selectedIndex);
	}

	private function set_selectedItem(item:Dynamic):Dynamic {
		_selectedIndex = dataProvider.getItemIndex(item);
		refresh();
		return item;
	}

	// --- scrolling ----------------------------------------------------------

	private function visibleRows():Int {
		return Std.int(Math.max(1, Math.floor(boxHeight / rowHeight)));
	}

	private function maxOffset():Int {
		return Std.int(Math.max(0, dataProvider.length - visibleRows()));
	}

	private function onScroll(_):Void {
		scrollOffset = Std.int(Math.min(maxOffset(), Math.max(0, scrollBar.scrollPosition - 1)));
		layoutRows();
	}

	// --- rendering ----------------------------------------------------------

	private function buildSkin():Void {
		while (skinHolder.numChildren > 0) {
			skinHolder.removeChildAt(0);
		}
		var skin = FlSkin.create(SKIN_NAME);
		if (skin != null) {
			var bounds = FlSkin.nativeBounds(skin, 150, 100);
			FlSkin.nineSlice(skin, SKIN_GRID, bounds.width, bounds.height, boxWidth, boxHeight);
			skinHolder.addChild(skin);
		} else {
			var shape = new Shape();
			shape.graphics.beginFill(0xFFFFFF);
			shape.graphics.lineStyle(1, 0x7C8EA0);
			shape.graphics.drawRect(0, 0, boxWidth, boxHeight);
			shape.graphics.endFill();
			skinHolder.addChild(shape);
		}

		clipMask.graphics.clear();
		clipMask.graphics.beginFill(0xFFFFFF);
		clipMask.graphics.drawRect(2, 2, contentWidth(), boxHeight - 4);
		clipMask.graphics.endFill();
	}

	private function contentWidth():Float {
		var needsBar = dataProvider.length > visibleRows();
		return boxWidth - 4 - (needsBar ? FlUIScrollBar.WIDTH : 0);
	}

	private function refresh():Void {
		var needsBar = dataProvider.length > visibleRows();
		scrollBar.visible = needsBar;
		if (needsBar) {
			scrollBar.x = boxWidth - FlUIScrollBar.WIDTH - 1;
			scrollBar.y = 1;
			scrollBar.setSize(boxHeight - 2);
			scrollBar.setScrollProperties(visibleRows(), 1, maxOffset() + 1);
		}
		scrollOffset = Std.int(Math.min(scrollOffset, maxOffset()));
		buildRows();
		layoutRows();
	}

	private function buildRows():Void {
		while (rowsHolder.numChildren > 0) {
			rowsHolder.removeChildAt(0);
		}
		for (i in 0...dataProvider.length) {
			rowsHolder.addChild(makeRow(i));
		}
	}

	private function makeRow(index:Int):Sprite {
		var row = new Sprite();
		row.buttonMode = true;
		row.useHandCursor = true;
		row.mouseChildren = false;

		var selected = index == _selectedIndex;
		var bg = new Shape();
		bg.graphics.beginFill(selected ? 0x2A5A8C : 0xFFFFFF, selected ? 1 : 0.01);
		bg.graphics.drawRect(0, 0, contentWidth(), rowHeight);
		bg.graphics.endFill();
		row.addChild(bg);

		var text = new TextField();
		text.selectable = false;
		text.mouseEnabled = false;
		text.autoSize = TextFieldAutoSize.NONE;
		text.width = contentWidth() - 8;
		text.height = rowHeight;
		text.defaultTextFormat = new TextFormat(
			FontResolver.resolve("Arial"), 11, selected ? 0xFFFFFF : 0x000000, false, false, false, null, null, TextFormatAlign.LEFT
		);
		text.text = itemToLabel(dataProvider.getItemAt(index));
		text.x = 4;
		text.y = (rowHeight - text.textHeight) / 2 - 2;
		row.addChild(text);

		row.addEventListener(MouseEvent.CLICK, function(_) selectFromList(index));
		return row;
	}

	private function selectFromList(index:Int):Void {
		var changed = index != _selectedIndex;
		_selectedIndex = index;
		refresh();
		if (changed) {
			dispatchEvent(new Event(Event.CHANGE));
		}
	}

	private function layoutRows():Void {
		rowsClip.x = 2;
		rowsClip.y = 2;
		for (i in 0...rowsHolder.numChildren) {
			rowsHolder.getChildAt(i).y = (i - scrollOffset) * rowHeight;
		}
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
}
