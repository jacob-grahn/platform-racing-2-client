package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;

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
		testComboBoxUserSelectionDispatchesChange();
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

	private static function testComboBoxUserSelectionDispatchesChange():Void {
		var combo = new FlComboBox("");
		combo.addItem("One");
		combo.addItem("Two");

		var changes = 0;
		combo.addEventListener(Event.CHANGE, function(_) changes++);

		// Open the list, then click the second row like a user would.
		combo.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		var dropdown = findOpenDropdown(combo);
		assertNotNull(dropdown, "clicking the combo opens its list");
		// Row sprites follow the background shape (child 0); pick the second row.
		var row = Std.downcast(dropdown.getChildAt(2), Sprite);
		assertNotNull(row, "the open list renders a row per item");
		row.dispatchEvent(new MouseEvent(MouseEvent.CLICK));

		assertEquals(1, combo.selectedIndex, "picking a row selects it");
		assertEquals(1, changes, "user selection dispatches CHANGE");
		assertNotNull(findLabelField(combo, "Two"), "caption follows the picked row");
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
		for (i in 0...combo.numChildren) {
			var child = Std.downcast(combo.getChildAt(i), Sprite);
			if (child != null && child.visible && child.numChildren > 1) {
				return child;
			}
		}
		return null;
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
