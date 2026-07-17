package pr2.gameplay;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;

/** Flash `CowboyMode`: plays the authored animation, then stops on frame 82. */
class CowboyMode extends Sprite {
	private var art:Null<Sprite>;
	private var stopped:Bool = false;
	private var frame:Int = 1;

	public var currentFrame(get, never):Int;

	public function new() {
		super();
		mouseEnabled = false;
		mouseChildren = false;
		art = new Sprite();
		art.graphics.beginFill(0x4A2A16, 0.88);
		art.graphics.lineStyle(2, 0xD5A45B);
		art.graphics.drawRoundRect(-105, -24, 210, 48, 10, 10);
		art.graphics.endFill();
		var text = new TextField();
		text.x = -100;
		text.y = -14;
		text.width = 200;
		text.height = 30;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 19, 0xFFF0C4, true, null, null, null, null,
			TextFormatAlign.CENTER);
		text.text = "Cowboy Mode";
		art.addChild(text);
		art.addEventListener(Event.ENTER_FRAME, onFrame);
		applyVisual();
		addChild(art);
	}

	public function advance():Void {
		step();
	}

	private function onFrame(_:Event):Void step();
	private function step():Void {
		if (art == null || stopped) return;
		frame++;
		applyVisual();
		if (frame >= 82) stopAnimation();
	}

	private function applyVisual():Void {
		if (art == null) return;
		var intro = Math.min(1, frame / 18);
		art.alpha = intro;
		art.rotation = (1 - intro) * -8;
		art.scaleX = art.scaleY = 0.75 + intro * 0.25;
	}

	private function stopAnimation():Void {
		stopped = true;
		if (art != null) art.removeEventListener(Event.ENTER_FRAME, onFrame);
	}

	public function remove():Void {
		if (art != null) {
			art.removeEventListener(Event.ENTER_FRAME, onFrame);
			if (art.parent != null) art.parent.removeChild(art);
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function get_currentFrame():Int {
		return art == null ? 0 : frame;
	}
}
