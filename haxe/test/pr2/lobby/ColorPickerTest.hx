package pr2.lobby;

import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.events.MouseEvent;
import pr2.data.ColorUtil;
import pr2.lobby.account.ColorChoices;
import pr2.lobby.account.ColorPicker;
import pr2.lobby.account.ColorPickerPopup;
import pr2.lobby.account.CursorEyedropper;
import pr2.lobby.account.PartSelector;
import pr2.ui.CustomCursor;

class ColorPickerTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testColorUtilCompatibility();
		if (pr2.DeterministicTestMode.finishSmokeSuite("ColorPickerTest")) return;
		testColorChoicesPalette();
		testColorPickerEventsAndRecents();
		testAccountPartSelectorPickerSize();
		testPopupOrientationAndDirection();
		testPopupTextPaletteAndCancel();
		testPopupSpectrumAndHue();
		testAuthoredPickerArtRegistration();
		testExactPopupShell();
		testCursorEyedropperSamplingAndExclusions();
		testPopupRestoresPriorCustomCursor();
		trace('ColorPickerTest passed $assertions assertions');
	}

	private static function testAccountPartSelectorPickerSize():Void {
		var selector = new PartSelector(["1"], 1, 0x123456, ["1"], 0x654321);
		var primary:ColorPicker = @:privateAccess selector.cp;
		var secondary:ColorPicker = @:privateAccess selector.cp2;
		assertClose(20, primary.width, "account primary picker uses Flash width");
		assertClose(20, primary.height, "account primary picker uses Flash height");
		assertClose(20, secondary.width, "account epic picker uses Flash width");
		assertClose(20, secondary.height, "account epic picker uses Flash height");
		assertClose(primary.x, secondary.x, "account epic picker overlaps the primary picker");
		assertClose(primary.y, secondary.y, "account epic picker shares the primary picker y");
		assertEquals(@:privateAccess selector.epicMask, secondary.mask, "account epic picker uses the Flash triangular mask");
		selector.remove();
	}

	private static function testColorUtilCompatibility():Void {
		var cyan = ColorUtil.hsbToRGB(180, 100, 100);
		assertEquals(0, cyan.red, "hsbToRGB red");
		assertEquals(255, cyan.green, "hsbToRGB green");
		assertEquals(255, cyan.blue, "hsbToRGB blue");
		var hsb = ColorUtil.rgbToHSB(153, 0, 0);
		assertClose(0, hsb.hue, "rgbToHSB hue");
		assertClose(100, hsb.saturation, "rgbToHSB saturation");
		assertClose(60, hsb.brightness, "rgbToHSB brightness");
		assertEquals(0x112233, ColorUtil.rgbToHex24(0x11, 0x22, 0x33), "rgbToHex24");
		var rgb = ColorUtil.hex24ToRGB(0xABCDEF);
		assertEquals(0xAB, rgb.red, "hex24 red");
		assertEquals(0xCD, rgb.green, "hex24 green");
		assertEquals(0xEF, rgb.blue, "hex24 blue");
		assertEquals(0x78123456, ColorUtil.argbToHex32(0x12, 0x34, 0x56, 0x78), "argbToHex32");
		var argb = ColorUtil.hex32ToARGB(0x78123456);
		assertEquals(0x78, argb.alpha, "hex32 alpha");
		assertEquals(0x12, argb.red, "hex32 red");
		assertEquals(0x34, argb.green, "hex32 green");
		assertEquals(0x56, argb.blue, "hex32 blue");
		assertEquals(0x00FFFF, ColorUtil.hsbToHex24(180, 100, 100), "hsbToHex24");
		assertEquals("0x00BEEF", ColorUtil.decimalToHex(0xBEEF), "decimalToHex uppercase six digits");
	}

	private static function testColorChoicesPalette():Void {
		resetRecents();
		var grid = ColorChoices.populate(ColorPicker.recentColors);
		assertEquals(22, grid.length, "palette column count");
		assertEquals(12, grid[0].length, "palette row count");
		assertEquals(0x888888, grid[0][0], "recent first color");
		assertEquals(0x555555, grid[0][1], "recent second color");
		assertEquals(0x000000, grid[2][0], "suggested black");
		assertEquals(0xFFFFFF, grid[2][5], "suggested white");
		assertEquals(0xFF0000, grid[2][6], "suggested red");
		assertEquals(0x00FF00, grid[2][7], "suggested green");
		assertEquals(0x0000FF, grid[2][8], "suggested blue");
		assertEquals(0x000000, grid[4][0], "RGB cube first red block");
		assertEquals(0x00FFFF, grid[9][5], "RGB cube blue/green orientation");
		assertEquals(0x990000, grid[4][6], "RGB cube wraps red blocks down rows");
	}

	private static function testColorPickerEventsAndRecents():Void {
		resetRecents();
		var picker = new ColorPicker();
		assertEquals(0x0000FF, picker.getColor(), "default Flash picker color");
		assertClose(30, picker.width, "picker swatch keeps ColorPickerGraphic width");
		assertClose(30, picker.height, "picker swatch keeps ColorPickerGraphic height");
		assertEquals("swatchSkin", picker.getChildAt(1).name, "picker uses authored ColorPicker over-skin asset");
		var changes = 0;
		var opens = 0;
		var closes = 0;
		picker.addEventListener(Event.CHANGE, function(_:Event):Void changes++);
		picker.addEventListener(Event.OPEN, function(_:Event):Void opens++);
		picker.addEventListener(Event.CLOSE, function(_:Event):Void closes++);

		picker.setColor(0x0000FF);
		assertEquals(0, changes, "same color does not dispatch change");
		picker.setColor(0x123456);
		assertEquals(1, changes, "changed color dispatches change");

		@:privateAccess picker.openPopup();
		assertEquals(1, opens, "openPopup dispatches open");
		@:privateAccess picker.popup.setColor(0xABCDEF);
		@:privateAccess picker.closePopup();
		assertEquals(2, changes, "pick changed color dispatches once");
		assertEquals(1, closes, "pick closes popup");
		assertEquals(0xABCDEF, ColorPicker.recentColors[0], "new color records at front on close");
		var snapshot = ColorPicker.recentColors.copy();
		@:privateAccess picker.openPopup();
		@:privateAccess picker.closePopup();
		assertArrayEquals(snapshot, ColorPicker.recentColors, "existing recent color is not moved or duplicated");
		picker.remove();
	}

	private static function testPopupOrientationAndDirection():Void {
		resetRecents();
		var parent = new Sprite();
		var picker = new ColorPicker();
		picker.x = 100;
		picker.y = 40;
		parent.addChild(picker);
		picker.direction = ColorPicker.RIGHT;
		var swatchWidth = picker.width;
		@:privateAccess picker.openPopup();
		var popup:ColorPickerPopup = @:privateAccess picker.popup;
		assertEquals(22, @:privateAccess popup.colorChoices.length, "popup uses 22 palette columns");
		assertEquals(12, @:privateAccess popup.colorChoices[0].length, "popup uses 12 palette rows");
		assertEquals(15.0, @:privateAccess popup.palette.x, "authored palette x");
		assertEquals(15.0, @:privateAccess popup.palette.y, "authored palette y");
		assertEquals(Math.round(picker.x + swatchWidth + 5), popup.x, "right direction places popup to the right");
		@:privateAccess picker.closePopup();

		picker.direction = ColorPicker.LEFT;
		picker.x = 400;
		@:privateAccess picker.openPopup();
		popup = @:privateAccess picker.popup;
		assertEquals(Math.round(picker.x - popup.width - 5), popup.x, "left direction places popup to the left");
		picker.remove();
	}

	private static function testPopupTextPaletteAndCancel():Void {
		resetRecents();
		var popup = new ColorPickerPopup(0x0000FF);
		assertEquals("#0000FF", @:privateAccess popup.textBox.text, "initial text uses six-digit hex");
		var changes = 0;
		var closes = 0;
		popup.addEventListener(Event.CHANGE, function(_:Event):Void changes++);
		popup.addEventListener(Event.CLOSE, function(_:Event):Void closes++);
		@:privateAccess popup.textBox.text = "#123abc";
		@:privateAccess popup.setColorFromText(new Event(Event.CHANGE));
		assertEquals(0x123ABC, popup.getColor(), "text accepts # hex");
		assertEquals("#123ABC", @:privateAccess popup.textBox.text, "text normalizes to uppercase");
		@:privateAccess popup.textBox.text = "0x00ff00";
		@:privateAccess popup.setColorFromText(new Event(Event.CHANGE));
		assertEquals(0x00FF00, popup.getColor(), "text accepts 0x hex");
		@:privateAccess popup.textBox.text = "x";
		@:privateAccess popup.setColorFromText(new Event(Event.CHANGE));
		assertEquals(0, popup.getColor(), "invalid text falls back to black");
		@:privateAccess popup.hoverOverPalette(mouseEventAt(@:privateAccess popup.palette, 25, 65));
		assertEquals(0xFF0000, popup.getColor(), "palette hover previews color");
		@:privateAccess popup.hoverOutPalette(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals(0, popup.getColor(), "palette out restores current color");
		@:privateAccess popup.clickCancel(new MouseEvent(MouseEvent.CLICK));
		assertEquals(0x0000FF, popup.getColor(), "cancel restores initial color");
		assertEquals(1, closes, "cancel closes popup");
		assertEquals(true, changes > 0, "popup changes dispatch while editing");
	}

	private static function testPopupSpectrumAndHue():Void {
		var popup = new ColorPickerPopup(0xFF0000);
		@:privateAccess popup.previewColorAtMouse(mouseEventAt(@:privateAccess popup.spectrum, 60, 60));
		assertEquals(0x000000, popup.getColor(), "spectrum bottom-right is black");
		assertEquals(60.0, @:privateAccess popup.crosshairs.x, "spectrum drag clamps x");
		assertEquals(60.0, @:privateAccess popup.crosshairs.y, "spectrum drag clamps y");
		@:privateAccess popup.previewColorAtMouse(mouseEventAt(@:privateAccess popup.spectrum, 60, 0));
		assertEquals(0xFF0000, popup.getColor(), "spectrum top-right uses current hue");
		@:privateAccess popup.dragHueSlider(mouseEventAt(@:privateAccess popup.hueSlider, 1, 30));
		assertEquals(180, Math.round(@:privateAccess popup.hue), "hue slider maps midpoint to 180 degrees");
		assertEquals(0x00FFFF, popup.getColor(), "hue slider updates color");
		popup.remove();
	}

	private static function testAuthoredPickerArtRegistration():Void {
		var popup = new ColorPickerPopup(0xFF0000);
		var crosshairs = Std.downcast(@:privateAccess popup.crosshairs, Sprite);
		assertEquals(2, crosshairs.numChildren, "crosshairs preserve both authored Symbol 1202 layers");
		assertClose(0, crosshairs.getChildAt(0).transform.matrix.tx, "crosshairs keep the XFL origin");
		assertClose(0, crosshairs.getChildAt(1).transform.matrix.ty, "crosshairs front keeps the XFL origin");
		var hueRoot = Std.downcast(@:privateAccess popup.hueArrow, Sprite);
		var hueMatrix = hueRoot.getChildByName("hueArrowArt").transform.matrix;
		assertClose(0, hueMatrix.a, "hue arrow authored matrix a");
		assertClose(0.119796752929688, hueMatrix.b, "hue arrow authored matrix b");
		assertClose(-0.120452880859375, hueMatrix.c, "hue arrow authored matrix c");
		assertClose(4.5, hueMatrix.tx, "hue arrow authored registration x");
		assertClose(-4.5, hueMatrix.ty, "hue arrow authored registration y");
		assertEquals(60.0, @:privateAccess popup.hueArrow.y, "zero-degree hue uses the authored bottom endpoint");
		popup.setColor(0x0000FF);
		assertEquals(20.0, @:privateAccess popup.hueArrow.y, "240-degree hue tracks the authored slider range");
		popup.remove();

		var eyedropper = new CursorEyedropper(new Bitmap(new BitmapData(1, 1, false, 0)));
		var root = Std.downcast(eyedropper.getChildByName("eyedropperRoot"), Sprite);
		var art = Std.downcast(root.getChildByName("eyedropperArt"), Sprite);
		assertClose(6.4, art.x, "eyedropper retains the authored child registration x after root centering");
		assertClose(-8.4, art.y, "eyedropper retains the authored child registration y after root centering");
		assertClose(0.681365966796875, art.scaleX, "eyedropper retains the authored child scale");
		assertEquals(2, art.numChildren, "eyedropper preserves both authored Symbol 1302 layers");
		eyedropper.remove();
	}

	private static function testExactPopupShell():Void {
		var popup = new ColorPickerPopup(0x123456);
		var art = @:privateAccess popup.art;
		assertClose(0, art.panel.x, "color picker ShadowBG keeps XFL X");
		assertClose(0, art.panel.y, "color picker ShadowBG keeps XFL Y");
		assertClose(0.919113159179688, art.panel.scaleX, "color picker ShadowBG keeps XFL horizontal scale");
		assertClose(1.36125183105469, art.panel.scaleY, "color picker ShadowBG keeps XFL vertical scale");
		assertClose(115, art.textInput.x, "color input keeps XFL X");
		assertClose(150, art.textInput.y, "color input keeps XFL Y");
		assertClose(100 * 1.19999694824219, art.textInput.controlWidth, "color input keeps authored horizontal scale");
		assertClose(22, art.textInput.controlHeight, "color input keeps authored height");
		assertClose(74, art.okButton.x, "OK keeps XFL X");
		assertClose(225, art.okButton.y, "OK keeps XFL Y");
		assertClose(100 * 0.750152587890625, art.okButton.controlWidth, "OK keeps authored horizontal scale");
		assertClose(162, art.cancelButton.x, "Cancel keeps XFL X");
		assertClose(225, art.cancelButton.y, "Cancel keeps XFL Y");
		assertClose(100 * 0.750152587890625, art.cancelButton.controlWidth, "Cancel keeps authored horizontal scale");
		popup.remove();
	}

	private static function testCursorEyedropperSamplingAndExclusions():Void {
		var stageRoot = new Sprite();
		var source = new Sprite();
		var pixels = new BitmapData(40, 20, false, 0xFF0000);
		pixels.fillRect(new openfl.geom.Rectangle(20, 0, 20, 20), 0x00FF00);
		var bitmap = new Bitmap(pixels);
		source.addChild(bitmap);
		stageRoot.addChild(source);
		var eyedropper = new CursorEyedropper(bitmap);
		var changes = 0;
		var completes = 0;
		eyedropper.addEventListener(Event.CHANGE, function(_:Event):Void changes++);
		eyedropper.addEventListener(Event.COMPLETE, function(_:Event):Void completes++);
		source.addEventListener(MouseEvent.MOUSE_MOVE, @:privateAccess eyedropper.mouseMoveHandler);

		source.dispatchEvent(mouseEventAt(source, 5, 5));
		@:privateAccess eyedropper.maybeUpdate(new Event(Event.ENTER_FRAME));
		assertEquals(0xFF0000, eyedropper.color, "eyedropper samples red pixel");
		assertEquals(true, eyedropper.visible, "eyedropper shows over included targets");
		source.dispatchEvent(mouseEventAt(source, 25, 5));
		@:privateAccess eyedropper.maybeUpdate(new Event(Event.ENTER_FRAME));
		assertEquals(0x00FF00, eyedropper.color, "eyedropper samples green pixel");
		assertEquals(2, changes, "eyedropper dispatches preview changes");

		eyedropper.addExclusion(source);
		@:privateAccess eyedropper.maybeUpdate(new Event(Event.ENTER_FRAME));
		assertEquals(false, eyedropper.visible, "eyedropper hides over excluded ancestors");
		assertEquals(-1, eyedropper.color, "eyedropper clears color over exclusions");

		var second = new CursorEyedropper(bitmap);
		source.addEventListener(MouseEvent.MOUSE_MOVE, @:privateAccess second.mouseMoveHandler);
		source.dispatchEvent(mouseEventAt(source, 5, 5));
		@:privateAccess second.maybeUpdate(new Event(Event.ENTER_FRAME));
		@:privateAccess second.mouseDownHandler(mouseEventAt(source, 5, 5));
		assertEquals(0, completes, "first eyedropper does not receive second complete");
		var secondCompletes = 0;
		second.addEventListener(Event.COMPLETE, function(_:Event):Void secondCompletes++);
		@:privateAccess second.mouseDownHandler(mouseEventAt(source, 5, 5));
		assertEquals(1, secondCompletes, "visible eyedropper dispatches complete on click");
		second.remove();
		assertEquals(null, @:privateAccess second.cursorContainer, "eyedropper disposes sampling bitmap");
		eyedropper.remove();
		pixels.dispose();
	}

	private static function testPopupRestoresPriorCustomCursor():Void {
		CustomCursor.unsetInstance();
		var prior = new CustomCursor();
		prior.disposable = false;
		CustomCursor.change(prior);
		assertEquals(true, prior.isActive(), "prior cursor starts active");
		var popup = new ColorPickerPopup(0x0000FF);
		popup.init();
		assertEquals(false, prior.isActive(), "popup pauses prior cursor");
		assertEquals(true, Std.isOfType(CustomCursor.instance, CursorEyedropper), "popup installs eyedropper cursor");
		popup.remove();
		assertEquals(prior, CustomCursor.instance, "popup restores prior cursor instance");
		assertEquals(true, prior.isActive(), "popup restores prior cursor active state");
		CustomCursor.unsetInstance();
	}

	private static function resetRecents():Void {
		for (i in 0...ColorPicker.recentColors.length) {
			ColorPicker.recentColors[i] = i % 2 == 0 ? 0x888888 : 0x555555;
		}
	}

	private static function assertArrayEquals(expected:Array<Int>, actual:Array<Int>, message:String):Void {
		assertions++;
		if (expected.length != actual.length) {
			throw '$message: expected length ${expected.length}, got ${actual.length}';
		}
		for (i in 0...expected.length) {
			if (expected[i] != actual[i]) {
				throw '$message at $i: expected ${expected[i]}, got ${actual[i]}';
			}
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertClose(expected:Float, actual:Float, message:String, tolerance:Float = 0.0001):Void {
		assertions++;
		if (Math.abs(expected - actual) > tolerance) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function mouseEventAt(target:Sprite, localX:Float, localY:Float):MouseEvent {
		return new MouseEvent(MouseEvent.MOUSE_MOVE, true, false, localX, localY);
	}
}
