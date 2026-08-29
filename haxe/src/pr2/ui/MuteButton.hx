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

	The vector pipeline exports the base and the nested `waves` instance as
	separate, registration-aligned SVGs. This preserves the original authored
	hairlines while allowing the port to toggle the same logical child.
**/
class MuteButton extends Sprite {
	private static inline var MUTE_BUTTON_BASE_ASSET = "assets/svg/login/mute_button_base.svg";
	private static inline var MUTE_BUTTON_WAVES_ASSET = "assets/svg/login/mute_button_waves.svg";
	public static var muted(default, null):Bool = false;

	public final backgroundPanel:Shape;
	private var buttonArtwork:Sprite;
	private var artworkBase:Shape;
	private var artworkWaves:Shape;

	public function new() {
		super();
		backgroundPanel = AuthoredScale9.squarePanel({x: -14, y: -18, scaleX: 0.56982421875, scaleY: 0.349990844726562});
		backgroundPanel.name = "backgroundPanel";
		addChild(backgroundPanel);
		buttonArtwork = new Sprite();
		buttonArtwork.name = "button";
		artworkBase = SvgAsset.create(MUTE_BUTTON_BASE_ASSET);
		artworkWaves = SvgAsset.create(MUTE_BUTTON_WAVES_ASSET);
		buttonArtwork.addChild(artworkBase);
		buttonArtwork.addChild(artworkWaves);
		addChild(buttonArtwork);

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
		buttonArtwork.transform.colorTransform = new ColorTransform(0.5, 0.5, 0.5, 1, 127, 127, 127, 0);
	}

	private function onOut(_:MouseEvent):Void {
		buttonArtwork.transform.colorTransform = new ColorTransform();
	}

	private function applyMutedState():Void {
		artworkWaves.visible = !muted;
		SoundMixer.soundTransform = new SoundTransform(muted ? 0 : 1);
	}

	public function toggle():Void doToggle(!muted);

	public function doToggle(value:Bool):Void {
		muted = value;
		applyMutedState();
	}

}
