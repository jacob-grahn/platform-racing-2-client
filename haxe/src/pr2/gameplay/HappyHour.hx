package pr2.gameplay;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;

/** Flash `HappyHour`: plays the authored animation, then removes itself. */
class HappyHour extends Sprite {
	private var art:Null<Sprite>;
	private var frame:Int = 1;
	private var removed:Bool = false;
	private var onRemoved:Null<HappyHour->Void>;

	public var currentFrame(get, never):Int;

	public function new(?onRemoved:HappyHour->Void) {
		super();
		this.onRemoved = onRemoved;
		mouseEnabled = false;
		mouseChildren = false;
		art = announcement("Happy Hour!", 0xFFD447);
		art.addEventListener(Event.ENTER_FRAME, onFrame);
		applyVisual();
		addChild(art);
	}

	public function advance():Void {
		step();
	}

	private function onFrame(_:Event):Void step();
	private function step():Void {
		if (art == null || removed) return;
		frame++;
		applyVisual();
		if (frame >= 100) finishAnimation();
	}

	private function applyVisual():Void {
		if (art == null) return;
		var intro = Math.min(1, frame / 15);
		var outro = frame > 75 ? Math.max(0, (100 - frame) / 25) : 1;
		art.alpha = intro * outro;
		art.scaleX = art.scaleY = 0.7 + 0.3 * intro;
		art.y = -12 * (1 - outro);
	}

	private static function announcement(label:String, color:Int):Sprite {
		var root = new Sprite();
		root.graphics.beginFill(0x222222, 0.82);
		root.graphics.lineStyle(2, color);
		root.graphics.drawRoundRect(-95, -22, 190, 44, 12, 12);
		root.graphics.endFill();
		var text = new TextField();
		text.x = -90;
		text.y = -13;
		text.width = 180;
		text.height = 28;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 20, color, true, null, null, null, null,
			TextFormatAlign.CENTER);
		text.text = label;
		root.addChild(text);
		return root;
	}

	private function finishAnimation():Void {
		remove();
	}

	public function remove():Void {
		if (removed) {
			return;
		}
		removed = true;
		if (art != null) {
			art.removeEventListener(Event.ENTER_FRAME, onFrame);
			if (art.parent != null) art.parent.removeChild(art);
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
		if (onRemoved != null) {
			onRemoved(this);
			onRemoved = null;
		}
	}

	private function get_currentFrame():Int {
		return art == null ? 0 : frame;
	}
}
