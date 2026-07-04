package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.ui.Keyboard;
import pr2.ui.StageFocus;

/**
	Behavioural coverage for the `fl.controls.*` component ports beyond FlButton:
	CheckBox, ComboBox, TextInput, TextArea, Slider, List, and UIScrollBar. Each
	check exercises the small slice of the fl API the PR2 source actually drives.
**/
class FlComponentsTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testCheckBox();
		testComboBoxModel();
		testComboBoxInteraction();
		testComboBoxCollectionString();
		testTextInput();
		testTextArea();
		testSlider();
		testList();
		testScrollBar();
		trace('FlComponentsTest passed $assertions assertions');
	}

	// --- CheckBox -----------------------------------------------------------

	private static function testCheckBox():Void {
		var box = new FlCheckBox("Mute", false);
		assertEquals(false, box.selected, "checkbox starts unselected");
		assertNotNull(findLabelField(box, "Mute"), "checkbox renders its label");

		// Programmatic set must NOT fire CHANGE (fl semantics).
		var changes = 0;
		box.addEventListener(Event.CHANGE, function(_) changes++);
		box.selected = true;
		assertEquals(true, box.selected, "selected setter updates state");
		assertEquals(0, changes, "programmatic selected change is silent");

		// A user click toggles and dispatches CHANGE.
		box.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(false, box.selected, "click toggles selected off");
		assertEquals(1, changes, "click dispatches CHANGE");
		box.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(true, box.selected, "click toggles selected on");
		assertEquals(2, changes, "second click dispatches CHANGE");

		box.enabled = false;
		assertEquals(false, box.mouseEnabled, "disabled checkbox ignores the mouse");

		box.label = "Music";
		assertNotNull(findLabelField(box, "Music"), "label setter updates the caption");
	}

	// --- ComboBox -----------------------------------------------------------

	private static function testComboBoxModel():Void {
		var combo = new FlComboBox("Loading...");
		assertEquals(-1, combo.selectedIndex, "combo starts with no selection");
		assertNotNull(findLabelField(combo, "Loading..."), "combo shows its prompt while empty");

		combo.addItem({label: "Alpha", token: "a"});
		combo.addItem({label: "Beta", token: "b"});
		assertEquals(2, combo.length, "addItem grows the data provider");

		combo.selectedItem = combo.dataProvider.getItemAt(1);
		assertEquals(1, combo.selectedIndex, "selectedItem maps to its index");
		assertNotNull(findLabelField(combo, "Beta"), "selection updates the visible caption");

		combo.selectedIndex = 0;
		assertEquals("a", combo.selectedItem.token, "selectedIndex exposes the item payload");

		combo.removeAll();
		assertEquals(0, combo.length, "removeAll clears items");
		assertEquals(-1, combo.selectedIndex, "removeAll clears the selection");
		assertNotNull(findLabelField(combo, "Loading..."), "prompt returns after removeAll");
	}

	private static function testComboBoxInteraction():Void {
		var combo = new FlComboBox("");
		combo.addItem("One");
		combo.addItem("Two");

		var changes = 0;
		var closes = 0;
		var focusResets = 0;
		combo.addEventListener(Event.CHANGE, function(_) changes++);
		combo.addEventListener(Event.CLOSE, function(_) closes++);
		StageFocus.resetHook = function():Void focusResets++;

		// Opening and closing the collapsed control never changes its value.
		combo.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		var dropdown = findOpenDropdown(combo);
		assertNotNull(dropdown, "clicking the combo opens its list");
		assertEquals(-1, combo.selectedIndex, "opening leaves selection unchanged");
		assertEquals(0, changes, "opening does not dispatch CHANGE");
		combo.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(null, findOpenDropdown(combo), "a repeated control click closes the list");
		assertEquals(-1, combo.selectedIndex, "closing by control click leaves selection unchanged");
		assertEquals(1, closes, "control close dispatches CLOSE");
		assertEquals(1, focusResets, "control close resets stage focus");

		combo.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		dropdown = findOpenDropdown(combo);
		var row = combo.rowsHolder == null ? null : Std.downcast(combo.rowsHolder.getChildAt(1), Sprite);
		assertNotNull(row, "the open list renders a row per item");
		assertEquals(22.0, combo.rowsHolder.getChildAt(1).y - combo.rowsHolder.getChildAt(0).y,
			"dropdown rows retain the authored CellRenderer spacing");
		assertEquals(48.0, combo.dropdownHeight(), "two rows plus the List skin inset determine dropdown height");
		row.dispatchEvent(new MouseEvent(MouseEvent.CLICK));

		assertEquals(1, combo.selectedIndex, "picking a row selects it");
		assertEquals(1, changes, "user selection dispatches CHANGE");
		assertNotNull(findLabelField(combo, "Two"), "caption follows the picked row");
		assertEquals(null, findOpenDropdown(combo), "picking a row closes the list");
		assertEquals(2, closes, "row selection close dispatches CLOSE");
		assertEquals(2, focusResets, "row selection close resets stage focus");

		// Picking the already-selected row is silent but still closes the list.
		combo.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		dropdown = findOpenDropdown(combo);
		row = Std.downcast(combo.rowsHolder.getChildAt(1), Sprite);
		row.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, changes, "picking the selected row does not dispatch CHANGE again");
		assertEquals(null, findOpenDropdown(combo), "picking the selected row closes the list");
		assertEquals(3, closes, "selected-row close dispatches CLOSE");

		combo.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		combo.onStageMouseDown(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertEquals(null, findOpenDropdown(combo), "an outside press closes the list");
		assertEquals(1, combo.selectedIndex, "outside-close leaves selection unchanged");
		assertEquals(4, focusResets, "outside close resets stage focus");

		combo.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		combo.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.ESCAPE));
		assertEquals(null, findOpenDropdown(combo), "Escape closes the list");
		assertEquals(1, combo.selectedIndex, "Escape-close leaves selection unchanged");
		assertEquals(5, closes, "Escape close dispatches CLOSE");

		combo.enabled = false;
		combo.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(null, findOpenDropdown(combo), "a disabled combo does not open");
		assertEquals(1, changes, "disabled clicks do not dispatch CHANGE");

		assertEquals(true, FlComboBox.chooseDropdownBelow(200, 40, -26, 60), "list opens below when it fits");
		assertEquals(false, FlComboBox.chooseDropdownBelow(100, 80, 20, 60), "list opens above near the bottom edge");
		assertEquals(true, FlComboBox.chooseDropdownBelow(50, 20, -40, 60), "list stays below near the top edge");
		assertEquals(0.0, FlComboBox.clampDropdownX(-10, 80, 200), "list stays inside the left stage edge");
		assertEquals(120.0, FlComboBox.clampDropdownX(150, 80, 200), "list stays inside the right stage edge");

		var scrolling = new FlComboBox("");
		scrolling.rowCount = 2;
		for (label in ["One", "Two", "Three", "Four"]) scrolling.addItem(label);
		scrolling.selectedIndex = 3;
		scrolling.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(2, scrolling.scrollOffset, "opening scrolls the selected row into view");
		assertEquals(true, scrolling.scrollBar.parent == scrolling.dropdown, "rowCount overflow shows the authored scrollbar");
		assertEquals(48.0, scrolling.dropdownHeight(), "rowCount caps dropdown height");
		scrolling.closeDropdown();
		StageFocus.resetHooks();
	}

	private static function testComboBoxCollectionString():Void {
		// The Flash IDE serializes a ComboBox dataProvider as a flat token list:
		// header, field descriptors (4 tokens each), item count, then values.
		var mode = FlDataProvider.fromCollectionString(
			"fl.data.DataProvider, fl.data.SimpleCollectionItem, item, 2, label, 5, , , data, 5, , , 3, User Name, user, Level Title, title, Level ID, id");
		assertEquals(3, mode.length, "search mode provider parses three rows");
		assertEquals("User Name", mode.getItemAt(0).label, "first label");
		assertEquals("user", mode.getItemAt(0).data, "first data");
		assertEquals("id", mode.getItemAt(2).data, "last data");

		// Empty data values (a blank `data` field) survive as empty strings.
		var dir = FlDataProvider.fromCollectionString(
			"fl.data.DataProvider, fl.data.SimpleCollectionItem, item, 2, label, 5, , , data, 5, , , 3, Choose..., , One Hour, 3600, One Day, 86400");
		assertEquals(3, dir.length, "provider with a blank value parses all rows");
		assertEquals("", dir.getItemAt(0).data, "blank data preserved");
		assertEquals("3600", dir.getItemAt(1).data, "value after a blank parses");

		// An empty collection yields no rows.
		assertEquals(0, FlDataProvider.fromCollectionString("fl.data.DataProvider, fl.data.SimpleCollectionItem, item, 0, 0").length,
			"empty collection has no rows");
		assertEquals(0, FlDataProvider.fromCollectionString("").length, "blank string yields no rows");
	}

	// --- TextInput ----------------------------------------------------------

	private static function testTextInput():Void {
		var input = new FlTextInput("hello");
		assertEquals("hello", input.text, "text getter reflects the field");
		input.text = "world";
		assertEquals("world", input.text, "text setter writes the field");

		assertEquals(true, input.editable, "text input defaults to editable");
		input.editable = false;
		assertEquals(false, input.editable, "editable toggles the field type");
		assertEquals(TextFieldType.DYNAMIC, input.textField.type, "non-editable input uses a dynamic field");
		input.editable = true;

		input.enabled = false;
		assertEquals(false, input.textField.selectable, "disabled input cannot select text");
		assertEquals(0x999999, input.textField.defaultTextFormat.color, "disabled input uses the Flash disabled text color");
		input.enabled = true;
		assertEquals(true, input.editable, "disabling and re-enabling preserves editable state");
		assertEquals(TextFieldType.INPUT, input.textField.type, "re-enabled editable input accepts text");
		assertEquals(0x000000, input.textField.defaultTextFormat.color, "enabled input restores black text");

		input.setSize(152, 22);
		assertEquals(5.0, input.textField.x, "text uses the Flash five-pixel left inset");
		assertEquals(142.0, input.textField.width, "text reserves five pixels on both sides");
		assertEquals(1.0, input.textField.y, "text baseline box starts below the top bevel");
		assertEquals(20.0, input.textField.height, "text box leaves both skin bevels visible");

		// The authored focusRectSkin sits between the background and editable field.
		input.textField.dispatchEvent(new FocusEvent(FocusEvent.FOCUS_IN));
		assertEquals(true, input.getChildAt(1).visible, "focus in shows the authored focus skin");
		input.textField.dispatchEvent(new FocusEvent(FocusEvent.FOCUS_OUT));
		assertEquals(false, input.getChildAt(1).visible, "focus out hides the authored focus skin");

		// The component re-broadcasts the inner field's CHANGE.
		var changes = 0;
		input.addEventListener(Event.CHANGE, function(_) changes++);
		input.textField.dispatchEvent(new Event(Event.CHANGE));
		assertEquals(1, changes, "inner CHANGE is re-dispatched by the component");
	}

	// --- TextArea -----------------------------------------------------------

	private static function testTextArea():Void {
		var area = new FlTextArea(200, 80);
		area.text = "line one";
		assertEquals("line one", area.text, "text setter writes the field");
		area.append("\nline two");
		assertEquals(true, StringTools.contains(area.text, "line two"), "append adds text");
		area.maxChars = 255;
		assertEquals(255, area.textField.maxChars, "text area forwards maxChars to the field");
		area.restrict = "^`";
		assertEquals("^`", area.textField.restrict, "text area forwards restrict to the field");
		assertNotNull(area.verticalScrollBar, "text area owns a vertical scrollbar");
	}

	// --- Slider -------------------------------------------------------------

	private static function testSlider():Void {
		var slider = new FlSlider(100);
		slider.minimum = 0;
		slider.maximum = 100;
		slider.value = 50;
		assertEquals(50.0, slider.value, "value setter stores within range");

		slider.value = 250;
		assertEquals(100.0, slider.value, "value clamps to maximum");
		slider.value = -10;
		assertEquals(0.0, slider.value, "value clamps to minimum");

		slider.snapInterval = 10;
		slider.value = 47;
		assertEquals(50.0, slider.value, "snapInterval quantises the value");

		// Pressing the thumb announces THUMB_PRESS (a SliderEvent == Event.CHANGE
		// family) even without a live stage.
		var pressed = false;
		slider.addEventListener(FlSliderEvent.THUMB_PRESS, function(_) pressed = true);
		thumbOf(slider).dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertEquals(true, pressed, "thumb press dispatches a SliderEvent");
	}

	// --- List ---------------------------------------------------------------

	private static function testList():Void {
		var list = new FlList(150, 60);
		list.addItem({label: "Red"});
		list.addItem({label: "Green"});
		list.addItem({label: "Blue"});
		assertEquals(3, list.length, "addItem grows the list");

		list.selectedIndex = 2;
		assertEquals("Blue", list.selectedItem.label, "selectedIndex exposes the item");

		var changes = 0;
		list.addEventListener(Event.CHANGE, function(_) changes++);
		var row = findFirstClickableRow(list);
		assertNotNull(row, "list renders clickable rows");
		row.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(0, list.selectedIndex, "clicking the first row selects it");
		assertEquals(1, changes, "row click dispatches CHANGE");
	}

	// --- UIScrollBar --------------------------------------------------------

	private static function testScrollBar():Void {
		var bar = new FlUIScrollBar(120);
		bar.setScrollProperties(5, 1, 10);
		bar.scrollPosition = 50;
		assertEquals(10.0, bar.scrollPosition, "scrollPosition clamps to max");
		bar.scrollPosition = -3;
		assertEquals(1.0, bar.scrollPosition, "scrollPosition clamps to min");

		// The down arrow steps the position and announces SCROLL.
		var scrolls = 0;
		bar.addEventListener(Event.SCROLL, function(_) scrolls++);
		bar.scrollPosition = 1;
		downArrowOf(bar).dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(2.0, bar.scrollPosition, "arrow click steps the position");
		assertEquals(1, scrolls, "arrow click dispatches SCROLL");
	}

	// --- helpers ------------------------------------------------------------

	private static function findOpenDropdown(combo:FlComboBox):Null<Sprite> {
		return combo.dropdown.visible ? combo.dropdown : null;
	}

	private static function thumbOf(slider:FlSlider):Sprite {
		// Children: trackHolder(0), thumbHolder(1).
		return cast slider.getChildAt(1);
	}

	private static function downArrowOf(bar:FlUIScrollBar):Sprite {
		// Children: trackHolder(0), upArrow(1), downArrow(2), thumb(3).
		return cast bar.getChildAt(2);
	}

	private static function findFirstClickableRow(container:DisplayObjectContainer):Null<Sprite> {
		for (i in 0...container.numChildren) {
			var child = container.getChildAt(i);
			var sprite = Std.downcast(child, Sprite);
			if (sprite != null && sprite.buttonMode) {
				return sprite;
			}
			var asContainer = Std.downcast(child, DisplayObjectContainer);
			if (asContainer != null) {
				var nested = findFirstClickableRow(asContainer);
				if (nested != null) {
					return nested;
				}
			}
		}
		return null;
	}

	private static function findLabelField(container:DisplayObjectContainer, text:String):Null<TextField> {
		for (i in 0...container.numChildren) {
			var field = Std.downcast(container.getChildAt(i), TextField);
			if (field != null && field.text == text) {
				return field;
			}
			var asContainer = Std.downcast(container.getChildAt(i), DisplayObjectContainer);
			if (asContainer != null) {
				var nested = findLabelField(asContainer, text);
				if (nested != null) {
					return nested;
				}
			}
		}
		return null;
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) {
			throw message;
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
