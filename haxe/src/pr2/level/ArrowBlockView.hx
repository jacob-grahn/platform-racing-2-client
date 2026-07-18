package pr2.level;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.ColorTransform;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;

/** Native eight-frame brighten/fade cycle for ArrowBlockGraphic. */
class ArrowBlockView extends Sprite {
	private static final MULTIPLIERS:Array<Float> = [1, 0.671875, 0.328125, 0, 0.25, 0.5, 0.75, 1];
	private static final OFFSETS:Array<Float> = [0, 85, 170, 255, 191, 128, 64, 0];

	public var currentFrame(default, null):Int = 1;
	public var isPlaying(default, null):Bool = false;
	private final art:Shape;

	public function new() {
		super();
		art = NativeAssets.svg(StaticSvg.ArrowOverlay);
		var layer = new Sprite();
		layer.addChild(art);
		addChild(layer);
		renderFrame();
	}

	public function animateFromFrame(frame:Int):Void {
		currentFrame = Std.int(Math.max(1, Math.min(8, frame)));
		renderFrame();
		if (!isPlaying) {
			isPlaying = true;
			addEventListener(Event.ENTER_FRAME, advance);
		}
	}

	public function stop():Void {
		if (!isPlaying) return;
		isPlaying = false;
		removeEventListener(Event.ENTER_FRAME, advance);
	}

	private function advance(_:Event):Void {
		if (currentFrame >= 8) {
			currentFrame = 1;
			renderFrame();
			stop();
			return;
		}
		currentFrame++;
		renderFrame();
	}

	private function renderFrame():Void {
		var index = currentFrame - 1;
		var multiplier = MULTIPLIERS[index];
		var offset = OFFSETS[index];
		art.transform.colorTransform = new ColorTransform(multiplier, multiplier, multiplier, 1, offset, offset, 0, 0);
	}

	public function dispose():Void {
		stop();
		if (parent != null) parent.removeChild(this);
	}
}
