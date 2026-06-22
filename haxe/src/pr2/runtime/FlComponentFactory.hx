package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.generated.assets.AssetTypes.DisplayElementDef;

/**
	Builds the fl.controls component instances (TextInput, Button, ComboBox, ...)
	that a `DOMComponentInstance` element describes. Pulled out of PR2MovieClip:
	this is a pure DisplayElementDef -> DisplayObject factory with no dependency on
	the clip's timeline/frame state.
**/
class FlComponentFactory {
	public static function create(element:DisplayElementDef):DisplayObject {
		return switch (element.libraryItemName) {
			case "Components/TextInput":
				createTextInputComponent(element);
			case "Components/TextArea":
				createTextAreaComponent(element);
			case "Components/Button":
				createButtonComponent(element);
			case "Components/ComboBox":
				createComboBoxComponent(element);
			case "Components/CheckBox":
				createCheckBoxComponent(element);
			case "Components/Slider":
				createSliderComponent(element);
			case "Components/List":
				createListComponent(element);
			case "Components/UIScrollBar":
				createScrollBarComponent(element);
			default:
				createGenericComponent(element);
		}
	}

	private static function createTextInputComponent(element:DisplayElementDef):DisplayObject {
		var input = new FlTextInput(componentString(element, "text", ""));
		input.displayAsPassword = componentBool(element, "displayAsPassword", false);
		input.editable = componentBool(element, "editable", true);
		var restrict = componentString(element, "restrict", "");
		if (restrict != "") {
			input.restrict = restrict;
		}
		var maxChars = Std.parseInt(componentString(element, "maxChars", "0"));
		if (maxChars != null && maxChars > 0) {
			input.maxChars = maxChars;
		}
		var size = scaledComponentSize(element, 100, 22);
		input.setSize(size.width, size.height);
		input.enabled = componentBool(element, "enabled", true);
		return input;
	}

	private static function createTextAreaComponent(element:DisplayElementDef):DisplayObject {
		// Like the other fl.controls, an authored instance scale is the component's
		// box size, not a glyph transform. Bake scale * the fl TextArea default
		// (100x100) into the control here; applyElementProperties strips the scale
		// from the matrix so the text renders at its native size.
		var size = scaledComponentSize(element, 100, 100);
		var area = new FlTextArea(size.width, size.height);
		area.editable = componentBool(element, "editable", true);
		area.text = componentString(element, "text", "");
		area.enabled = componentBool(element, "enabled", true);
		return area;
	}

	private static function createButtonComponent(element:DisplayElementDef):DisplayObject {
		var button = new FlButton(componentString(element, "label", "Button"));
		// Flash components interpret an instance scale as component dimensions;
		// their labels remain unscaled. Bake that authored scale into the ported
		// button's layout before PR2MovieClip normalizes its display transform.
		var scale = componentScale(element);
		button.setSize(100 * scale.x, 22 * scale.y);
		button.toggle = componentBool(element, "toggle", false);
		button.selected = componentBool(element, "selected", false);
		button.emphasized = componentBool(element, "emphasized", false);
		// `enabled` last: a disabled button must end up greyed and inert even if
		// it was authored selected.
		button.enabled = componentBool(element, "enabled", true);
		return button;
	}

	private static function componentScale(element:DisplayElementDef):{x:Float, y:Float} {
		if (element.matrix == null) {
			return {x: 1, y: 1};
		}
		var matrix = element.matrix;
		var a = matrix.a == null ? 1 : matrix.a;
		var b = matrix.b == null ? 0 : matrix.b;
		var c = matrix.c == null ? 0 : matrix.c;
		var d = matrix.d == null ? 1 : matrix.d;
		return {
			x: Math.max(0.0001, Math.sqrt(a * a + b * b)),
			y: Math.max(0.0001, Math.sqrt(c * c + d * d))
		};
	}

	private static function createComboBoxComponent(element:DisplayElementDef):DisplayObject {
		var combo = new FlComboBox(componentString(element, "prompt", ""));
		var size = scaledComponentSize(element, 100, 22);
		combo.setSize(size.width, size.height);
		var rowCount = Std.parseInt(componentString(element, "rowCount", "5"));
		if (rowCount != null && rowCount > 0) {
			combo.rowCount = rowCount;
		}
		// Authored dropdown items come through as the Flash collection serialization.
		var items = FlDataProvider.fromCollectionString(componentString(element, "dataProvider", "")).toArray();
		for (item in items) {
			combo.addItem(item);
		}
		// A prompt-less ComboBox with data selects its first row, like fl.controls.
		if (combo.length > 0 && combo.prompt == "" && combo.selectedIndex < 0) {
			combo.selectedIndex = 0;
		}
		combo.enabled = componentBool(element, "enabled", true);
		return combo;
	}

	private static function createCheckBoxComponent(element:DisplayElementDef):DisplayObject {
		var checkBox = new FlCheckBox(
			componentString(element, "label", ""),
			componentBool(element, "selected", false)
		);
		checkBox.enabled = componentBool(element, "enabled", true);
		return checkBox;
	}

	private static function createSliderComponent(element:DisplayElementDef):DisplayObject {
		var size = componentSize(element, 100, 16);
		var slider = new FlSlider(size.width);
		var min = Std.parseFloat(componentString(element, "minimum", "0"));
		var max = Std.parseFloat(componentString(element, "maximum", "100"));
		slider.minimum = Math.isNaN(min) ? 0 : min;
		slider.maximum = Math.isNaN(max) ? 100 : max;
		var value = Std.parseFloat(componentString(element, "value", "0"));
		slider.value = Math.isNaN(value) ? 0 : value;
		slider.enabled = componentBool(element, "enabled", true);
		return slider;
	}

	private static function createListComponent(element:DisplayElementDef):DisplayObject {
		var size = componentSize(element, 150, 100);
		return new FlList(size.width, size.height);
	}

	private static function createScrollBarComponent(element:DisplayElementDef):DisplayObject {
		var size = componentSize(element, FlUIScrollBar.WIDTH, 100);
		return new FlUIScrollBar(size.height);
	}

	/** Authored on-stage size from the instance bounds, with component defaults. */
	private static function componentSize(element:DisplayElementDef, defaultWidth:Float, defaultHeight:Float):{width:Float, height:Float} {
		if (element.bounds != null) {
			var width = element.bounds.right - element.bounds.left;
			var height = element.bounds.bottom - element.bounds.top;
			if (width > 0 && height > 0) {
				return {width: width, height: height};
			}
		}
		return {width: defaultWidth, height: defaultHeight};
	}

	private static function scaledComponentSize(element:DisplayElementDef, defaultWidth:Float, defaultHeight:Float):{width:Float, height:Float} {
		var size = componentSize(element, defaultWidth, defaultHeight);
		var scale = componentScale(element);
		return {width: size.width * scale.x, height: size.height * scale.y};
	}

	private static function createGenericComponent(element:DisplayElementDef):DisplayObject {
		var label = element.name == null ? "component" : element.name;
		var holder = new Sprite();
		drawComponentBox(holder, 100, 22, 0xF2F2F2, 0x999999);
		var text = componentText(label, 100, 20, 0x555555, false, TextFormatAlign.CENTER);
		text.y = 3;
		holder.addChild(text);
		return holder;
	}

	private static function drawComponentBox(target:Sprite, width:Float, height:Float, fill:Int, stroke:Int):Void {
		target.graphics.beginFill(fill);
		target.graphics.lineStyle(1, stroke);
		target.graphics.drawRect(0, 0, width, height);
		target.graphics.endFill();
	}

	private static function componentText(label:String, width:Float, height:Float, color:Int, bold:Bool, align:TextFormatAlign):TextField {
		var text = new TextField();
		text.defaultTextFormat = new TextFormat("_sans", 11, color, bold, false, false, null, null, align);
		text.width = width;
		text.height = height;
		text.text = label;
		text.selectable = false;
		text.mouseEnabled = false;
		return text;
	}

	private static function componentString(element:DisplayElementDef, name:String, fallback:String):String {
		var params:Dynamic = element.componentParams;
		if (params == null) {
			return fallback;
		}
		var param:Dynamic = Reflect.field(params, name);
		if (param == null || !Reflect.hasField(param, "value")) {
			return fallback;
		}
		var value:Dynamic = Reflect.field(param, "value");
		return value == null ? fallback : Std.string(value);
	}

	private static function componentBool(element:DisplayElementDef, name:String, fallback:Bool):Bool {
		var params:Dynamic = element.componentParams;
		if (params == null) {
			return fallback;
		}
		var param:Dynamic = Reflect.field(params, name);
		if (param == null || !Reflect.hasField(param, "value")) {
			return fallback;
		}
		var value:Dynamic = Reflect.field(param, "value");
		if (Std.isOfType(value, Bool)) {
			return value;
		}
		var text = Std.string(value).toLowerCase();
		return text == "true" || text == "1" || text == "yes";
	}
}
