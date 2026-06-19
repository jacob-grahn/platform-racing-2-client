package pr2.page;

import openfl.display.Bitmap;
import openfl.display.PixelSnapping;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.ColorTransform;
import openfl.media.SoundMixer;
import openfl.media.SoundTransform;
import openfl.utils.Assets;

class LoginMuteButton extends Sprite {
	private static inline var MUTE_BUTTON_ASSET = "assets/login/mute_button@4x.png";
	private static inline var MUTE_BUTTON_SCALE = 4;
	private static inline var MUTE_BUTTON_TRIM_X = -57;
	private static inline var MUTE_BUTTON_TRIM_Y = -73;
	private static var muted:Bool = false;

	private var bitmap:Bitmap;

	public function new() {
		super();
		bitmap = new Bitmap(Assets.getBitmapData(MUTE_BUTTON_ASSET), PixelSnapping.AUTO, true);
		bitmap.x = MUTE_BUTTON_TRIM_X / MUTE_BUTTON_SCALE;
		bitmap.y = MUTE_BUTTON_TRIM_Y / MUTE_BUTTON_SCALE;
		bitmap.scaleX = 1 / MUTE_BUTTON_SCALE;
		bitmap.scaleY = 1 / MUTE_BUTTON_SCALE;
		addChild(bitmap);

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
		muted = !muted;
		applyMutedState();
	}

	private function onOver(_:MouseEvent):Void {
		transform.colorTransform = new ColorTransform(0.5, 0.5, 0.5, 1, 127, 127, 127, 0);
	}

	private function onOut(_:MouseEvent):Void {
		transform.colorTransform = new ColorTransform();
	}

	private function applyMutedState():Void {
		alpha = muted ? 0.7 : 1;
		SoundMixer.soundTransform = new SoundTransform(muted ? 0 : 1);
	}
}
