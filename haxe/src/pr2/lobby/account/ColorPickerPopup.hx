package pr2.lobby.account;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import pr2.app.AppStage;
import pr2.data.ColorUtil;
import pr2.runtime.FlButton;
import pr2.runtime.FlTextInput;
import pr2.runtime.PR2MovieClip;
import pr2.ui.CustomCursor;

/**
	HSV colour popup ported from `com.jiggmin.ColorPicker.ColorPickerPopup`.
**/
class ColorPickerPopup extends Sprite {
	private static inline var PALETTE_CELL:Int = 10;
	private static inline var SPECTRUM_SIZE:Int = 60;
	private static inline var HUE_WIDTH:Int = 15;
	private static inline var PREVIEW_NONE:Int = -1;

	private var palette:Sprite;
	private var colorChoices:Array<Array<Int>>;
	private var outlineCC:Sprite;
	private var outlinePC:Sprite;
	private var initialColor:Int;
	private var previewColor:Int = PREVIEW_NONE;
	private var color:Int = PREVIEW_NONE;
	private var hue:Float = 0;
	private var saturation:Float = 0;
	private var brightness:Float = 50;
	private var spectrum:Sprite;
	private var hueSlider:Sprite;
	private var colorPreviewBox:Sprite;
	private var eyedropper:Null<CursorEyedropper>;
	private var spectrumBG:BitmapData;
	private var hueArrow:DisplayObject;
	private var crosshairs:DisplayObject;
	private var priorCursor:Null<CustomCursor>;
	private var priorCursorActive:Bool = false;
	private var art:PR2MovieClip;
	private var okButton:FlButton;
	private var cancelButton:FlButton;
	private var textBox:FlTextInput;
	private var removed:Bool = false;

	public function new(initialColor:Int) {
		super();
		art = PR2MovieClip.fromLinkage("ColorPickerPopupGraphic");
		addChild(art);
		okButton = requireChild("ok_bt", FlButton);
		cancelButton = requireChild("cancel_bt", FlButton);
		textBox = requireChild("textBox", FlTextInput);
		okButton.addEventListener(MouseEvent.CLICK, clickOK);
		cancelButton.addEventListener(MouseEvent.CLICK, clickCancel);
		textBox.restrict = "0123456789abcdefABCDEF#x";
		textBox.addEventListener(Event.CHANGE, setColorFromText);

		spectrum = initSpectrum(SPECTRUM_SIZE, SPECTRUM_SIZE);
		spectrum.x = 15;
		spectrum.y = 150;
		addChild(spectrum);
		showOutline(spectrum);
		hueSlider = initHueSlider(HUE_WIDTH, SPECTRUM_SIZE);
		hueSlider.x = spectrum.x + spectrum.width + 10;
		hueSlider.y = spectrum.y;
		addChild(hueSlider);
		var outlineHS = makeOutline(HUE_WIDTH, SPECTRUM_SIZE);
		outlineHS.x = hueSlider.x;
		outlineHS.y = hueSlider.y;
		addChild(outlineHS);

		outlineCC = makePickedColorBox();
		outlineCC.visible = false;
		outlinePC = makePickedColorBox();
		outlinePC.visible = false;
		palette = new Sprite();
		palette.x = 15;
		palette.y = 15;
		palette.mouseChildren = false;
		palette.addChild(outlineCC);
		palette.addChild(outlinePC);
		initPalette();
		addChild(palette);

		colorPreviewBox = new Sprite();
		colorPreviewBox.graphics.beginFill(0);
		colorPreviewBox.graphics.drawRect(0, 0, 120, 25);
		colorPreviewBox.graphics.endFill();
		colorPreviewBox.x = 115;
		colorPreviewBox.y = 185;
		addChild(colorPreviewBox);
		var outlineCPB = makeOutline(120, 25);
		outlineCPB.x = colorPreviewBox.x;
		outlineCPB.y = colorPreviewBox.y;
		addChild(outlineCPB);

		setColor(initialColor);
		this.initialColor = initialColor;
		highlightCurrentColorIfInPalette();
		hueSlider.addEventListener(MouseEvent.MOUSE_DOWN, clickHueSlider);
		spectrum.addEventListener(MouseEvent.MOUSE_DOWN, onSpectrumDown);
		palette.addEventListener(MouseEvent.MOUSE_MOVE, hoverOverPalette);
		palette.addEventListener(MouseEvent.MOUSE_DOWN, clickPalette);
		palette.addEventListener(MouseEvent.MOUSE_OUT, hoverOutPalette);
	}

	public function init():Void {
		eyedropper = new CursorEyedropper();
		eyedropper.addExclusion(this);
		eyedropper.addEventListener(Event.CHANGE, onEyedropperMove);
		eyedropper.addEventListener(Event.COMPLETE, applyColor);
		if (CustomCursor.instance != null) {
			priorCursor = CustomCursor.instance;
			priorCursorActive = priorCursor.isActive();
			priorCursor.pause();
		}
		CustomCursor.change(eyedropper);
		var stage = AppStage.stage != null ? AppStage.stage : this.stage;
		if (stage != null) {
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			if (x + width > stage.stageWidth) {
				x = stage.stageWidth - width;
			}
			if (y + height > stage.stageHeight) {
				y = stage.stageHeight - height;
			}
		}
		if (x < 0) {
			x = 0;
		}
		if (y < 0) {
			y = 0;
		}
	}

	public function setColor(c:Int):Void {
		c &= 0xFFFFFF;
		if (color != c) {
			color = c;
			var newColor = ColorUtil.hex24ToHSB(c);
			hue = newColor.hue;
			hueArrow.y = Math.round(SPECTRUM_SIZE - hue / 360 * SPECTRUM_SIZE);
			updateSpectrumGradient();
			saturation = newColor.saturation;
			crosshairs.x = Math.round(saturation / 100 * SPECTRUM_SIZE);
			brightness = newColor.brightness;
			crosshairs.y = Math.round(SPECTRUM_SIZE - brightness / 100 * SPECTRUM_SIZE);
			updateColorPreview();
		}
	}

	public function getColor():Int {
		return previewColor != PREVIEW_NONE ? previewColor : color;
	}

	public function addExclusion(d:DisplayObject):Void {
		if (eyedropper != null) {
			eyedropper.addExclusion(d);
		}
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		var stage = AppStage.stage != null ? AppStage.stage : this.stage;
		if (stage != null) {
			stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, previewColorAtMouse);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragHueSlider);
		}
		spectrum.removeEventListener(MouseEvent.MOUSE_DOWN, onSpectrumDown);
		hueSlider.removeEventListener(MouseEvent.MOUSE_DOWN, clickHueSlider);
		palette.removeEventListener(MouseEvent.MOUSE_MOVE, hoverOverPalette);
		palette.removeEventListener(MouseEvent.MOUSE_DOWN, clickPalette);
		palette.removeEventListener(MouseEvent.MOUSE_OUT, hoverOutPalette);
		if (eyedropper != null) {
			eyedropper.removeEventListener(Event.CHANGE, onEyedropperMove);
			eyedropper.removeEventListener(Event.COMPLETE, applyColor);
		}
		okButton.removeEventListener(MouseEvent.CLICK, clickOK);
		cancelButton.removeEventListener(MouseEvent.CLICK, clickCancel);
		textBox.removeEventListener(Event.CHANGE, setColorFromText);
		if (spectrumBG != null) {
			spectrumBG.dispose();
		}
		restorePriorCursor();
		if (parent != null) {
			parent.removeChild(this);
		}
		dispatchEvent(new Event(Event.CLOSE));
	}

	private function updateColorPreview(c:Int = PREVIEW_NONE):Void {
		if (c == PREVIEW_NONE) {
			c = ColorUtil.hsbToHex24(hue, saturation, brightness);
		}
		var stage = AppStage.stage != null ? AppStage.stage : this.stage;
		if (stage == null || stage.focus != textBox.textField) {
			textBox.text = "#" + ColorUtil.decimalToHex(c).substr(2);
		}
		changePreviewBoxColor(colorPreviewBox, c);
		dispatchEvent(new Event(Event.CHANGE));
	}

	private function changePreviewBoxColor(d:DisplayObject, c:Int):Void {
		var newColor = ColorUtil.hex24ToRGB(c);
		d.transform.colorTransform = new ColorTransform(0, 0, 0, 1, newColor.red, newColor.green, newColor.blue, 0);
	}

	private function highlightCurrentColorIfInPalette():Void {
		for (j in 0...colorChoices.length) {
			for (k in 0...colorChoices[j].length) {
				if (colorChoices[j][k] == color) {
					outlineCC.visible = true;
					outlineCC.x = j * PALETTE_CELL;
					outlineCC.y = k * PALETTE_CELL;
				}
			}
		}
	}

	private function mouseUpHandler(_:MouseEvent):Void {
		Mouse.show();
		Mouse.cursor = MouseCursor.ARROW;
		Mouse.cursor = MouseCursor.AUTO;
		var stage = AppStage.stage != null ? AppStage.stage : this.stage;
		if (stage != null) {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, previewColorAtMouse);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragHueSlider);
		}
	}

	private function onSpectrumDown(e:MouseEvent):Void {
		Mouse.hide();
		previewColorAtMouse(e);
		var stage = AppStage.stage != null ? AppStage.stage : this.stage;
		if (stage != null) {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, previewColorAtMouse);
		}
	}

	private function clickHueSlider(e:MouseEvent):Void {
		Mouse.hide();
		dragHueSlider(e);
		var stage = AppStage.stage != null ? AppStage.stage : this.stage;
		if (stage != null) {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, dragHueSlider);
		}
	}

	private function previewColorAtMouse(e:MouseEvent):Void {
		var mousePt = eventPoint(spectrum, e);
		var targetX = clamp(Math.round(mousePt.x), 0, SPECTRUM_SIZE);
		var targetY = clamp(Math.round(mousePt.y), 0, SPECTRUM_SIZE);
		crosshairs.x = targetX;
		crosshairs.y = targetY;
		saturation = 100 * (targetX / SPECTRUM_SIZE);
		brightness = 100 - 100 * (targetY / SPECTRUM_SIZE);
		color = ColorUtil.hsbToHex24(hue, saturation, brightness);
		updateColorPreview();
		outlineCC.visible = false;
	}

	private function dragHueSlider(e:MouseEvent):Void {
		var mousePt = eventPoint(hueSlider, e);
		var targetY = clamp(Math.round(mousePt.y), 0, SPECTRUM_SIZE);
		hueArrow.y = targetY;
		hue = 360 - 360 * (targetY / SPECTRUM_SIZE);
		color = ColorUtil.hsbToHex24(hue, saturation, brightness);
		updateSpectrumGradient();
		updateColorPreview();
		outlineCC.visible = false;
	}

	private function hoverOverPalette(e:MouseEvent):Void {
		var mousePos = eventPoint(palette, e);
		var gridX = clamp(Math.floor(mousePos.x / PALETTE_CELL), 0, ColorChoices.COLS - 1);
		var gridY = clamp(Math.floor(mousePos.y / PALETTE_CELL), 0, ColorChoices.ROWS - 1);
		outlinePC.x = gridX * PALETTE_CELL;
		outlinePC.y = gridY * PALETTE_CELL;
		outlinePC.visible = true;
		previewColor = colorChoices[gridX][gridY];
		updateColorPreview(previewColor);
	}

	private function clickPalette(e:MouseEvent):Void {
		e.stopImmediatePropagation();
		var choiceX = Std.int(outlinePC.x / PALETTE_CELL);
		var choiceY = Std.int(outlinePC.y / PALETTE_CELL);
		setColor(colorChoices[choiceX][choiceY]);
		outlineCC.x = choiceX * PALETTE_CELL;
		outlineCC.y = choiceY * PALETTE_CELL;
		outlineCC.visible = true;
		remove();
	}

	private function hoverOutPalette(_:MouseEvent):Void {
		previewColor = PREVIEW_NONE;
		outlinePC.visible = false;
		updateColorPreview();
	}

	private function onEyedropperMove(_:Event):Void {
		if (eyedropper != null) {
			previewColor = eyedropper.color;
			updateColorPreview(previewColor);
		}
	}

	private function applyColor(_:Event):Void {
		if (eyedropper != null) {
			previewColor = PREVIEW_NONE;
			setColor(eyedropper.color);
			updateColorPreview();
			remove();
		}
	}

	private function setColorFromText(_:Event):Void {
		var stage = AppStage.stage != null ? AppStage.stage : this.stage;
		if (stage == null || stage.focus == textBox.textField) {
			var hex = textBox.text;
			var c = 0;
			if (hex != "") {
				hex = StringTools.replace(hex, "#", "");
				hex = StringTools.replace(hex, "0x", "");
				var parsed = Std.parseInt("0x" + hex);
				c = parsed == null ? 0 : parsed;
			}
			setColor(c);
		}
	}

	private function clickOK(_:MouseEvent):Void {
		remove();
	}

	private function clickCancel(_:MouseEvent):Void {
		color = initialColor;
		previewColor = PREVIEW_NONE;
		dispatchEvent(new Event(Event.CHANGE));
		remove();
	}

	private function initPalette():Void {
		palette.graphics.clear();
		palette.graphics.lineStyle(1, 0, 1, true);
		colorChoices = ColorChoices.populate(ColorPicker.recentColors);
		for (col in 0...colorChoices.length) {
			for (row in 0...colorChoices[col].length) {
				var choice = colorChoices[col][row];
				if (choice == color) {
					outlineCC.visible = true;
					outlineCC.x = col * PALETTE_CELL;
					outlineCC.y = row * PALETTE_CELL;
				}
				palette.graphics.beginFill(choice);
				palette.graphics.drawRect(col * PALETTE_CELL, row * PALETTE_CELL, PALETTE_CELL, PALETTE_CELL);
				palette.graphics.endFill();
			}
		}
	}

	private function makePickedColorBox():Sprite {
		var box = new Sprite();
		box.graphics.lineStyle(1, 0xFFFFFF, 1, true);
		box.graphics.drawRect(0, 0, PALETTE_CELL, PALETTE_CELL);
		return box;
	}

	private function initHueSlider(w:Int, h:Int):Sprite {
		var data = new BitmapData(w, h, false, 0xFFFFFF);
		for (y in 0...h) {
			var hue = 360 - 360 * y / h;
			data.fillRect(new Rectangle(0, y, w, 1), ColorUtil.hsbToHex24(hue, 100, 100));
		}
		hueArrow = PR2MovieClip.fromLinkage("ColorPickerHueArrowGraphic");
		hueArrow.x = w + 1;
		hueArrow.y = h;
		var interactiveHueArrow = Std.downcast(hueArrow, InteractiveObject);
		if (interactiveHueArrow != null) {
			interactiveHueArrow.mouseEnabled = false;
		}
		var hit = new Sprite();
		hit.graphics.beginFill(0, 0);
		hit.graphics.drawRect(0, 0, w + 10, h);
		hit.graphics.endFill();
		var slider = new Sprite();
		slider.addChild(new Bitmap(data));
		slider.addChild(hueArrow);
		slider.addChild(hit);
		return slider;
	}

	private function initSpectrum(w:Int, h:Int):Sprite {
		spectrumBG = new BitmapData(w, h, false, 0);
		crosshairs = PR2MovieClip.fromLinkage("ColorPickerCrosshairsGraphic");
		var interactiveCrosshairs = Std.downcast(crosshairs, InteractiveObject);
		if (interactiveCrosshairs != null) {
			interactiveCrosshairs.mouseEnabled = false;
		}
		crosshairs.x = 20;
		crosshairs.y = 20;
		var spectrum = new Sprite();
		spectrum.addChild(new Bitmap(spectrumBG));
		spectrum.addChild(crosshairs);
		return spectrum;
	}

	private function updateSpectrumGradient():Void {
		for (x in 0...spectrumBG.width) {
			var saturation = x / spectrumBG.width * 100;
			for (y in 0...spectrumBG.height) {
				var brightness = 100 - y / spectrumBG.height * 100;
				spectrumBG.setPixel(x, y, ColorUtil.hsbToHex24(hue, saturation, brightness));
			}
		}
	}

	private function showOutline(d:DisplayObject):Void {
		var outline = makeOutline(Math.round(d.width), Math.round(d.height));
		outline.x = d.x;
		outline.y = d.y;
		addChild(outline);
	}

	private function makeOutline(width:Int, height:Int):Sprite {
		var outline = new Sprite();
		outline.graphics.lineStyle(1, 0x333333, 1, true);
		outline.graphics.moveTo(0, height);
		outline.graphics.lineTo(0, 0);
		outline.graphics.lineTo(width, 0);
		outline.graphics.lineStyle(1, 0xFFFFFF, 1, true);
		outline.graphics.lineTo(width, height);
		outline.graphics.lineTo(0, height);
		return outline;
	}

	private function requireChild<T:DisplayObject>(name:String, cls:Class<T>):T {
		var child = art.getChildByTimelineName(name);
		var typed = Std.downcast(child, cls);
		if (typed == null) {
			throw 'ColorPickerPopupGraphic missing $name';
		}
		return typed;
	}

	private function restorePriorCursor():Void {
		if (CustomCursor.instance != null) {
			CustomCursor.unsetInstance();
			if (priorCursor != null) {
				CustomCursor.change(priorCursor);
				priorCursor.init();
				if (!priorCursorActive) {
					priorCursor.pause();
				}
			}
		} else if (priorCursor != null) {
			priorCursor.remove();
		}
		eyedropper = null;
		priorCursor = null;
	}

	private static function eventPoint(target:DisplayObject, e:MouseEvent):Point {
		if (target.stage == null) {
			return new Point(e.localX, e.localY);
		}
		return target.globalToLocal(new Point(e.stageX, e.stageY));
	}

	private static function clamp(value:Float, minimum:Int, maximum:Int):Int {
		return Std.int(Math.max(minimum, Math.min(maximum, value)));
	}
}
