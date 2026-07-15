package pr2.ui;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.ColorTransform;
import openfl.media.SoundMixer;
import openfl.media.SoundTransform;
import pr2.runtime.SvgAsset;

/**
	Global mute toggle ported from the Flash `ui.MuteButton`. In the original
	game this lives at the document root (`Main`) and stays on screen across
	every page, so it is owned by `Main` here rather than any single page.

	The artwork is the `UI/Global/MuteButton` symbol baked through the vector
	pipeline; the sprite's local origin matches the symbol registration point,
	so positioning the sprite at the Flash coordinates places it identically.
**/
class MuteButton extends Sprite {
	private static inline var MUTE_BUTTON_ASSET = "assets/svg/login/mute_button.svg";
	public static var muted(default, null):Bool = false;

	private var artwork:Shape;
	private var waves:Shape;

	public function new() {
		super();
		artwork = SvgAsset.create(MUTE_BUTTON_ASSET);
		addChild(artwork);

		waves = createWaves();
		addChild(waves);

		buttonMode = true;
		useHandCursor = true;
		mouseChildren = false;

		addEventListener(MouseEvent.CLICK, onClick);
		addEventListener(MouseEvent.MOUSE_OVER, onOver);
		addEventListener(MouseEvent.MOUSE_OUT, onOut);
		applyMutedState();
	}

	public function remove():Void {
		removeEventListener(MouseEvent.CLICK, onClick);
		removeEventListener(MouseEvent.MOUSE_OVER, onOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onOut);
	}

	private function onClick(_:MouseEvent):Void {
		doToggle(!muted);
	}

	private function onOver(_:MouseEvent):Void {
		transform.colorTransform = new ColorTransform(0.5, 0.5, 0.5, 1, 127, 127, 127, 0);
	}

	private function onOut(_:MouseEvent):Void {
		transform.colorTransform = new ColorTransform();
	}

	private function applyMutedState():Void {
		waves.visible = !muted;
		SoundMixer.soundTransform = new SoundTransform(muted ? 0 : 1);
	}

	public function toggle():Void doToggle(!muted);

	public function doToggle(value:Bool):Void {
		muted = value;
		applyMutedState();
	}

	private function createWaves():Shape {
		var shape = new Shape();
		var graphics = shape.graphics;

		graphics.lineStyle(1, 0x333333, 1);
		graphics.moveTo(15.1, -6.15);
		graphics.curveTo(17.6, -3.6, 17.8, -0.6);
		graphics.lineTo(17.8, -0.05);
		graphics.curveTo(17.8, 3.4, 15.15, 6.25);

		graphics.lineStyle(1, 0x333333, 0.66);
		graphics.moveTo(21.15, -8.05);
		graphics.curveTo(22.3, -6.9, 23.05, -5.55);
		graphics.lineTo(23.6, -4.55);
		graphics.curveTo(24.6, -2.45, 24.6, -0.05);
		graphics.curveTo(24.6, 1.9, 24, 3.65);
		graphics.curveTo(23.1, 6, 21.15, 8.15);

		graphics.lineStyle(1, 0x333333, 0.33);
		graphics.moveTo(27.1, -9.95);
		graphics.lineTo(28.7, -8.15);
		graphics.curveTo(31.5, -4.4, 31.5, -0.1);
		graphics.curveTo(31.5, 3.85, 29.35, 7.3);
		graphics.lineTo(27.1, 10.05);

		return shape;
	}
}
