package pr2.mobile;

import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import pr2.app.AppStage;
import pr2.data.ColorUtil;
import pr2.lobby.account.ColorPickerSurface;
import pr2.mobile.MobileAuthControls.AuthInput;

/** Touch-sized HSV controls and a one-tap sample from the visible game frame. */
class MobileAdvancedColorPopup extends ColorPickerSurface {
	public var onSamplingChange:Null<Bool->Void>;
	public var sampleAt:Null<Float->Float->Null<Int>>;
	private final view = new LobbyView();
	private final initialColor:Int;
	private var color:Int;
	private var hue:Float;
	private var saturation:Float;
	private var brightness:Float;
	private var w:Float = 844;
	private var h:Float = 390;
	private var inset:Float = 44;
	private var sampling = false;
	private var removed = false;
	private var hueLabel:Null<TextField>;
	private var saturationLabel:Null<TextField>;
	private var brightnessLabel:Null<TextField>;
	private var hexInput:Null<AuthInput>;
	private var preview:Null<Shape>;
	private var error:Null<TextField>;

	public function new(initialColor:Int) {
		super();
		fullViewport = true;
		this.initialColor = initialColor & 0xFFFFFF;
		color = this.initialColor;
		var hsb = ColorUtil.hex24ToHSB(color);
		hue = hsb.hue; saturation = hsb.saturation; brightness = hsb.brightness;
		addChild(view);
	}

	override public function init():Void {
		if (AppStage.stage != null) AppStage.stage.addEventListener(Event.RESIZE, layout);
		layout();
	}

	override public function setColor(value:Int):Void {
		color = value & 0xFFFFFF;
		var hsb = ColorUtil.hex24ToHSB(color);
		hue = hsb.hue; saturation = hsb.saturation; brightness = hsb.brightness;
		dispatchEvent(new Event(Event.CHANGE));
		render();
	}

	override public function getColor():Int return color;
	override public function addExclusion(_:DisplayObject):Void {}

	private function layout(?_:Event):Void {
		w = AppStage.stage == null ? 844 : AppStage.stage.stageWidth;
		h = AppStage.stage == null ? 390 : AppStage.stage.stageHeight;
		inset = w >= 760 ? 44 : 16;
		render();
	}

	private function render():Void {
		if (removed) return;
		view.clear();
		if (sampling) {
			view.graphics.beginFill(0x10283C, .95);
			view.graphics.drawRoundRect(inset, 8, w - inset * 2, 52, 16, 16);
			view.graphics.endFill();
			view.singleLine("TAP A COLOR ON THE SCREEN", inset + 16, 20, w - inset * 2 - 150, 30, 21, true, 0xFFFFFF);
			view.button("CANCEL", w - inset - 120, 12, 112, stopSampling, false, 44);
			return;
		}
		view.graphics.beginFill(0x10283C, .98); view.graphics.drawRect(0, 0, w, h); view.graphics.endFill();
		if (h > w) {
			view.label("Turn your device sideways to choose a color", 24, h / 2 - 60, w - 48, 120, 25, true, 0xFFFFFF);
			return;
		}
		view.singleLine("ADVANCED COLOR", inset, 16, w - inset * 2 - 260, 40, 28, true, 0xFFFFFF);
		view.button("CANCEL", w - inset - 238, 13, 108, cancel, false, 44);
		view.button("DONE", w - inset - 122, 13, 122, remove, true, 44);
		view.panel(inset, 67, w - inset * 2, h - 83);
		var left = inset + 18, panelWidth = w - inset * 2;
		var sliderWidth = Math.max(235, panelWidth * .53);
		var right = left + sliderWidth + 24;
		var rightWidth = w - inset - right - 18;
		var specs = [
			{label:"HUE", maximum:360.0, value:hue, y:82.0},
			{label:"SATURATION", maximum:100.0, value:saturation, y:163.0},
			{label:"BRIGHTNESS", maximum:100.0, value:brightness, y:244.0}
		];
		for (i in 0...specs.length) {
			var spec = specs[i];
			var label = view.label(spec.label + "  " + Math.round(spec.value), left, spec.y, sliderWidth, 25, 16, true, 0x18334B);
			if (i == 0) hueLabel = label; else if (i == 1) saturationLabel = label; else brightnessLabel = label;
			var slider = view.own(new MobileValueSlider(spec.maximum, spec.value));
			slider.x = left; slider.y = spec.y + 27; slider.setSize(sliderWidth, 44);
			slider.onChange = function(value) {
				if (i == 0) hue = value; else if (i == 1) saturation = value; else brightness = value;
				updateFromHsv();
			};
		}
		view.label("PREVIEW", right, 82, rightWidth, 24, 14, true, 0x0B519E);
		preview = new Shape(); view.addChild(preview);
		view.label("HEX COLOR", right, 157, rightWidth, 24, 14, true, 0x0B519E);
		hexInput = view.own(new AuthInput(StringTools.hex(color, 6)));
		hexInput.x = right; hexInput.y = 181; hexInput.setSize(rightWidth, 44);
		hexInput.textField.maxChars = 6; hexInput.textField.restrict = "0-9a-fA-F";
		view.button("APPLY HEX", right, 234, rightWidth, applyHex, false, 44);
		view.button("EYEDROPPER", right, 286, rightWidth, startSampling, true, 44);
		error = view.label("", right, h - 39, rightWidth, 25, 12, false, 0xA52735);
		updatePreview();
	}

	private function updateFromHsv():Void {
		color = ColorUtil.hsbToHex24(hue, saturation, brightness);
		if (hueLabel != null) hueLabel.text = "HUE  " + Math.round(hue);
		if (saturationLabel != null) saturationLabel.text = "SATURATION  " + Math.round(saturation);
		if (brightnessLabel != null) brightnessLabel.text = "BRIGHTNESS  " + Math.round(brightness);
		if (hexInput != null) hexInput.text = StringTools.hex(color, 6);
		updatePreview();
		dispatchEvent(new Event(Event.CHANGE));
	}
	private function updatePreview():Void {
		if (preview == null) return;
		var right = inset + 18 + Math.max(235, (w - inset * 2) * .53) + 24;
		var width = w - inset - right - 18;
		preview.graphics.clear(); preview.graphics.lineStyle(3, 0x18334B); preview.graphics.beginFill(color);
		preview.graphics.drawRoundRect(right, 108, width, 44, 12, 12); preview.graphics.endFill();
	}
	private function applyHex():Void {
		if (hexInput == null || !~/^[0-9a-fA-F]{6}$/.match(hexInput.text)) {
			if (error != null) error.text = "Enter six hex digits.";
			return;
		}
		var next = Std.parseInt("0x" + hexInput.text);
		if (next != null) setColor(next);
	}
	private function cancel():Void {
		color = initialColor;
		dispatchEvent(new Event(Event.CHANGE));
		remove();
	}
	private function startSampling():Void {
		sampling = true;
		if (onSamplingChange != null) onSamplingChange(true);
		render();
		if (AppStage.stage != null) AppStage.stage.addEventListener(MouseEvent.MOUSE_DOWN, captureSample, true, 2000);
	}
	private function stopSampling():Void {
		sampling = false;
		if (AppStage.stage != null) AppStage.stage.removeEventListener(MouseEvent.MOUSE_DOWN, captureSample, true);
		if (onSamplingChange != null) onSamplingChange(false);
		render();
	}
	private function captureSample(e:MouseEvent):Void {
		if (!sampling || e.stageY < 66) return;
		e.stopImmediatePropagation();
		var sampled = samplePixel(e.stageX, e.stageY);
		stopSampling();
		if (sampled != null) setColor(sampled);
		else if (error != null) error.text = "Could not sample this point. Try another.";
	}
	private function samplePixel(stageX:Float, stageY:Float):Null<Int> {
		if (sampleAt != null) return sampleAt(stageX, stageY);
		if (AppStage.stage == null) return null;
		var data:Null<BitmapData> = null;
		try {
			var root = pr2.page.PageHolder.getRootHolder();
			var source:DisplayObject = root == null || root.getCurrentPage() == null ? AppStage.stage : root.getCurrentPage();
			var local = source.globalToLocal(new Point(stageX, stageY));
			var matrix = new Matrix(); matrix.translate(-local.x, -local.y);
			data = new BitmapData(1, 1, false, 0);
			visible = false;
			data.draw(source, matrix, null, null, new Rectangle(0, 0, 1, 1));
			visible = true;
			var sampled = data.getPixel(0, 0);
			data.dispose();
			return sampled;
		} catch (_:Dynamic) {
			visible = true;
			if (data != null) data.dispose();
			return null;
		}
	}

	override public function remove():Void {
		if (removed) return;
		removed = true;
		if (sampling && onSamplingChange != null) onSamplingChange(false);
		if (AppStage.stage != null) AppStage.stage.removeEventListener(Event.RESIZE, layout);
		if (AppStage.stage != null) AppStage.stage.removeEventListener(MouseEvent.MOUSE_DOWN, captureSample, true);
		view.remove();
		super.remove();
		dispatchEvent(new Event(Event.CLOSE));
	}
}
