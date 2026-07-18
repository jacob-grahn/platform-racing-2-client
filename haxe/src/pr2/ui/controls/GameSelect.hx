package pr2.ui.controls;

import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.ui.Keyboard;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.StageFocus;

/** Typed collapsed select/list model with deterministic keyboard navigation. */
class GameSelect<T> extends NativeControl {
	public var selectedIndex(default, set):Int = -1;
	public var selectedOption(get, never):Null<SelectOption<T>>;
	public var selectedItem(get, never):Null<T>;
	public var prompt(default, set):String = "";
	public var open(default, null):Bool = false;
	public var rowCount:Int = 5;
	public var onChange:Null<SelectOption<T>->Void>;
	public final labelField:TextField;
	private var useAuthoredSkin:Bool = false;
	private var skinHolder:Null<Sprite>;
	private var options:Array<SelectOption<T>> = [];
	private var listHolder:Null<Sprite>;
	private var scrollBar:Null<GameScrollBar>;
	private var scrollOffset:Int = 0;

	public function new(?skin:ControlSkin) {
		super(100, 22, skin);
		useAuthoredSkin = skin == null;
		if (useAuthoredSkin) {
			graphics.clear();
			skinHolder = new Sprite();
			skinHolder.mouseEnabled = false;
			skinHolder.mouseChildren = false;
			addChild(skinHolder);
		}
		labelField = new TextField();
		labelField.mouseEnabled = false;
		labelField.selectable = false;
		labelField.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Body), 11, 0, false, false, false, null, null, TextFormatAlign.LEFT);
		labelField.x = 5;
		labelField.width = 76;
		labelField.height = 22;
		addChild(labelField);
		mouseChildren = true;
		useHandCursor = true;
		addEventListener(MouseEvent.CLICK, onClick);
		addEventListener(KeyboardEvent.KEY_DOWN, navigate);
		addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		redraw();
		layoutLabel();
	}

	public var length(get, never):Int;
	private function get_length():Int return options.length;
	public function addOption(label:String, value:T):SelectOption<T> { var option = new SelectOption(label, value); options.push(option); rebuildList(); return option; }
	public function addItem(item:T):SelectOption<T> {
		var label = item == null ? "" : (Reflect.hasField(item, "label") ? Std.string(Reflect.field(item, "label")) : Std.string(item));
		return addOption(label, item);
	}
	public function itemAt(index:Int):Null<T> return index < 0 || index >= options.length ? null : options[index].value;
	public function clear():Void { options = []; selectedIndex = -1; close(); }
	public function removeAll():Void clear();
	public function selectFromUser(index:Int):Void {
		if (!enabled || disposed || index < 0 || index >= options.length) return;
		if (index == selectedIndex) {
			close();
			return;
		}
		selectedIndex = index;
		var option = selectedOption;
		if (option != null && onChange != null) onChange(option);
		dispatchEvent(new Event(Event.CHANGE));
		close();
	}
	public function close():Void {
		if (!open) return;
		open = false;
		var ownerStage = listHolder == null ? null : listHolder.stage;
		if (ownerStage != null) {
			ownerStage.removeEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
			ownerStage.removeEventListener(KeyboardEvent.KEY_DOWN, navigate);
		}
		removeList();
		redraw();
		dispatchEvent(new Event(Event.CLOSE));
		StageFocus.reset();
	}
	override public function activate():Void {
		if (!enabled || disposed) return;
		if (open) close(); else openDropdown();
	}
	override public function setSize(width:Float, height:Float):Void {
		super.setSize(width, height);
		labelField.width = Math.max(0, width - 24);
		labelField.height = height;
		layoutLabel();
		if (open) rebuildList();
	}
	override public function dispose():Void { close(); removeEventListener(MouseEvent.CLICK, onClick); removeEventListener(KeyboardEvent.KEY_DOWN, navigate); removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage); onChange = null; options = []; removeList(); super.dispose(); }
	private function get_selectedOption():Null<SelectOption<T>> return selectedIndex < 0 ? null : options[selectedIndex];
	private function get_selectedItem():Null<T> { var option = selectedOption; return option == null ? null : option.value; }
	private function set_prompt(value:String):String { prompt = value == null ? "" : value; if (selectedIndex < 0) labelField.text = prompt; layoutLabel(); return prompt; }
	private function set_selectedIndex(value:Int):Int { selectedIndex = value < -1 ? -1 : (value >= options.length ? options.length - 1 : value); labelField.text = selectedIndex < 0 ? prompt : options[selectedIndex].label; layoutLabel(); return selectedIndex; }
	private function onClick(_):Void activate();
	private function removeList():Void {
		if (scrollBar != null) scrollBar.dispose();
		scrollBar = null;
		if (listHolder != null && listHolder.parent != null) listHolder.parent.removeChild(listHolder);
		listHolder = null;
	}
	private function rebuildList():Void {
		removeList();
		if (!open || options.length == 0) return;
		var holder = new Sprite();
		holder.name = "options";
		holder.x = 0;
		holder.y = controlHeight;
		var visibleRows = visibleRowCount();
		var listHeight = visibleRows * 22 + 4;
		var listSkin = new Sprite();
		listSkin.mouseEnabled = false;
		var listArt = NativeAssets.svg(StaticSvg.ListSkin);
		listArt.scale9Grid = new Rectangle(2, 2, 269, 187);
		listArt.width = controlWidth;
		listArt.height = listHeight;
		listSkin.addChild(listArt);
		holder.addChild(listSkin);
		var start = Std.int(Math.max(0, Math.min(maxScrollOffset(), scrollOffset)));
		var end = Std.int(Math.min(options.length, start + visibleRows));
		for (index in start...end) {
			var row = new Sprite();
			row.name = 'option_$index';
			row.buttonMode = true;
			row.useHandCursor = true;
			row.mouseChildren = false;
			row.x = 2;
			row.y = 2 + (index - start) * 22;
			drawRow(row, index, false);
			row.addEventListener(MouseEvent.ROLL_OVER, function(_:MouseEvent):Void drawRow(row, index, true));
			row.addEventListener(MouseEvent.ROLL_OUT, function(_:MouseEvent):Void drawRow(row, index, false));
			var optionIndex = index;
			row.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):Void {
				event.stopPropagation();
				selectFromUser(optionIndex);
			});
			holder.addChild(row);
		}
		if (options.length > visibleRows) {
			scrollBar = new GameScrollBar(0, maxScrollOffset(), visibleRows, 1);
			scrollBar.x = controlWidth - 16;
			scrollBar.y = 2;
			scrollBar.setSize(15, listHeight - 4);
			scrollBar.value = start;
			scrollBar.onScroll = function(value:Float):Void { scrollOffset = Std.int(value); rebuildList(); };
			holder.addChild(scrollBar);
		}
		holder.addEventListener(MouseEvent.MOUSE_WHEEL, onDropdownWheel);
		listHolder = holder;
		addChild(holder);
		if (stage != null) mountListOnStage();
	}
	private function drawRow(row:Sprite, index:Int, hovered:Bool):Void {
		while (row.numChildren > 0) row.removeChildAt(0);
		var selected = index == selectedIndex;
		var asset = selected ? (hovered ? StaticSvg.CellSelectedOver : StaticSvg.CellSelectedUp) : (hovered ? StaticSvg.CellOver : StaticSvg.CellUp);
		var skin = new Sprite();
		skin.mouseEnabled = false;
		var rowArt = NativeAssets.svg(asset);
		rowArt.scale9Grid = new Rectangle(1, 1, 150, 20);
		rowArt.width = Math.max(1, controlWidth - 4 - (options.length > visibleRowCount() ? 16 : 0));
		rowArt.height = 22;
		skin.addChild(rowArt);
		row.addChild(skin);
		var text = new TextField();
		text.mouseEnabled = false;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Body), 11, 0, false, false, false, null, null, TextFormatAlign.LEFT);
		text.x = 5;
		text.y = (22 - text.textHeight) / 2 - 2;
		text.width = Math.max(1, rowArt.width - 10);
		text.height = 22;
		text.text = options[index].label;
		row.addChild(text);
	}
	private function openDropdown():Void {
		if (!enabled || open || options.length == 0) return;
		open = true;
		scrollOffset = initialScrollOffset();
		rebuildList();
		if (stage != null) {
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, navigate);
		}
		redraw();
		dispatchEvent(new Event(Event.OPEN));
	}
	private function mountListOnStage():Void {
		if (stage == null || listHolder == null) return;
		var listHeight = visibleRowCount() * 22 + 4;
		var below = stage.globalToLocal(localToGlobal(new Point(0, controlHeight)));
		var above = stage.globalToLocal(localToGlobal(new Point(0, -listHeight)));
		var bottom = stage.globalToLocal(localToGlobal(new Point(0, controlHeight + listHeight)));
		var localY = below.y + Math.abs(bottom.y - below.y) <= stage.stageHeight || above.y < 0 ? controlHeight : -listHeight;
		var origin = stage.globalToLocal(localToGlobal(new Point(0, localY)));
		var right = stage.globalToLocal(localToGlobal(new Point(controlWidth, localY)));
		var lower = stage.globalToLocal(localToGlobal(new Point(0, localY + listHeight)));
		var matrix = new Matrix((right.x - origin.x) / controlWidth, (right.y - origin.y) / controlWidth,
			(lower.x - origin.x) / listHeight, (lower.y - origin.y) / listHeight);
		matrix.tx = Math.max(0, Math.min(origin.x, stage.stageWidth - Math.abs(right.x - origin.x)));
		matrix.ty = origin.y;
		stage.addChild(listHolder);
		listHolder.transform.matrix = matrix;
	}
	private function onStageMouseDown(event:MouseEvent):Void {
		if (!isDescendant(event.target, this) && !isDescendant(event.target, listHolder)) close();
	}
	private function onRemovedFromStage(_:Event):Void close();
	private function onDropdownWheel(event:MouseEvent):Void {
		if (options.length <= visibleRowCount()) return;
		scrollOffset = Std.int(Math.max(0, Math.min(maxScrollOffset(), scrollOffset + (event.delta < 0 ? 1 : -1))));
		rebuildList();
	}
	private function visibleRowCount():Int return Std.int(Math.max(1, Math.min(rowCount, options.length)));
	private function maxScrollOffset():Int return Std.int(Math.max(0, options.length - visibleRowCount()));
	private function initialScrollOffset():Int return selectedIndex < 0 ? 0 : Std.int(Math.min(maxScrollOffset(), Math.max(0, selectedIndex - visibleRowCount() + 1)));
	private static function isDescendant(target:Dynamic, ancestor:Null<DisplayObject>):Bool {
		if (ancestor == null) return false;
		var object = Std.downcast(target, DisplayObject);
		while (object != null) {
			if (object == ancestor) return true;
			object = object.parent;
		}
		return false;
	}
	override public function redraw():Void {
		if (!useAuthoredSkin || skinHolder == null) {
			super.redraw();
			return;
		}
		graphics.clear();
		graphics.beginFill(0x000000, 0.001);
		graphics.drawRect(0, 0, controlWidth, controlHeight);
		graphics.endFill();
		while (skinHolder.numChildren > 0) skinHolder.removeChildAt(0);
		var art = NativeAssets.svg(authoredAsset());
		art.scale9Grid = new Rectangle(4, 13.45, 120.75, 4.6);
		art.width = controlWidth;
		art.height = controlHeight;
		skinHolder.addChild(art);
	}
	private function authoredAsset():StaticSvg {
		if (!enabled) return StaticSvg.ComboBoxDisabled;
		if (open || pressed) return StaticSvg.ComboBoxDown;
		if (hovered) return StaticSvg.ComboBoxOver;
		return StaticSvg.ComboBoxUp;
	}
	private function layoutLabel():Void {
		if (labelField == null) return;
		var format = new TextFormat(NativeAssets.font(FontAsset.Body), 11, enabled ? 0x000000 : 0x999999, false, false, false, null, null,
			TextFormatAlign.LEFT);
		labelField.defaultTextFormat = format;
		labelField.setTextFormat(format);
		labelField.x = 5;
		labelField.width = Math.max(1, controlWidth - 24);
		labelField.height = controlHeight;
		labelField.y = (controlHeight - (labelField.textHeight + 4)) / 2;
	}
	override public function enabledChanged(value:Bool):Void {
		if (!value) close();
		layoutLabel();
	}
	private function navigate(event:KeyboardEvent):Void {
		if (event.currentTarget == this) event.stopPropagation();
		if (!enabled || options.length == 0) return;
		if (event.keyCode == Keyboard.DOWN) selectFromUser(Std.int(Math.min(options.length - 1, selectedIndex + 1)));
		if (event.keyCode == Keyboard.UP) selectFromUser(Std.int(Math.max(0, selectedIndex - 1)));
		if (event.keyCode == Keyboard.HOME) selectFromUser(0);
		if (event.keyCode == Keyboard.END) selectFromUser(options.length - 1);
		if (event.keyCode == Keyboard.ESCAPE) close();
	}
}
