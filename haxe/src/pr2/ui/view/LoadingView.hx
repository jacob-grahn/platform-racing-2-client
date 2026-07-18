package pr2.ui.view;

import openfl.display.Shape;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;

/** Native replacement for the looping LoadingGraphic timeline. */
class LoadingView extends NativeView {
	public final spinner:Shape;
	private final label:TextField;
	public var currentFrame(default, null):Int = 1;
	private static final SPINNER_KEYS:Array<Array<Float>> = [
		[1, 0, 0, 1, 0, 0],
		[0.900680541992188, 0.43133544921875, -0.43133544921875, 0.900680541992188, 23, -14.4],
		[0.622573852539062, 0.780258178710938, -0.780258178710938, 0.622573852539062, 50.15, -17.45],
		[0.220962524414062, 0.9742431640625, -0.9742431640625, 0.220962524414062, 75.95, -8.45],
		[-0.221221923828125, 0.974090576171875, -0.974090576171875, -0.221221923828125, 95.1, 10.7],
		[-0.62261962890625, 0.779861450195312, -0.779861450195312, -0.62261962890625, 104.05, 36.45],
		[-0.900360107421875, 0.430892944335938, -0.430892944335938, -0.900360107421875, 100.9, 63.6],
		[-0.999298095703125, -0.00030517578125, 0.00030517578125, -0.999298095703125, 86.6, 86.55],
		[-0.898483276367188, -0.434280395507812, 0.434280395507812, -0.898483276367188, 63.45, 101],
		[-0.619369506835938, -0.781967163085938, 0.781967163085938, -0.619369506835938, 36.3, 103.95],
		[-0.220535278320312, -0.973648071289062, 0.973648071289062, -0.220535278320312, 10.75, 95],
		[0.22137451171875, -0.973358154296875, 0.973358154296875, 0.22137451171875, -8.4, 75.85],
		[0.622421264648438, -0.779129028320312, 0.779129028320312, 0.622421264648438, -17.35, 50.1],
		[0.900772094726562, -0.43133544921875, 0.43133544921875, 0.900772094726562, -14.4, 23]
	];

	public function new() {
		super();
		spinner = NativeAssets.svg(StaticSvg.LoadingSpinner);
		spinner.name = "spinner";
		applySpinnerFrame(0);
		addChild(spinner);

		label = new TextField();
		label.name = "label";
		label.x = -22.15;
		label.y = -6;
		label.width = 50;
		label.height = 12.15;
		label.selectable = false;
		label.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0x404040);
		label.text = "Loading...";
		addChild(label);
		listen(this, Event.ENTER_FRAME, onFrame);
	}

	private function onFrame(_:Event):Void {
		currentFrame = currentFrame % 574 + 1;
		// Symbol 1052 advances one of its 14 authored rotation keys each root frame.
		applySpinnerFrame((currentFrame - 1) % 14);
		// Symbol 1057 holds 10/10/10/11 frames, repeating independently of the spinner.
		var textFrame = (currentFrame - 1) % 41;
		label.text = textFrame < 10 ? "Loading..." : textFrame < 20 ? "Loading" : textFrame < 30 ? "Loading." : "Loading..";
	}

	private function applySpinnerFrame(index:Int):Void {
		var key = SPINNER_KEYS[index];
		var scale = 0.785232543945312;
		spinner.transform.matrix = new Matrix(key[0] * scale, key[1] * scale, key[2] * scale, key[3] * scale, -34 + key[4] * scale,
			-34.05 + key[5] * scale);
	}
}
