package pr2.effects;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.runtime.SvgAsset;

/** Exact source-derived SVG frame player shared by short native presentation timelines. */
class NativeEffectAnimation extends Sprite {
	public var currentFrame(default, null):Int = 1;
	public var currentAssetPath(default, null):String;
	public final totalFrames:Int;
	private final kind:String;

	public function new(kind:String, totalFrames:Int) {
		super();
		this.kind = kind;
		this.totalFrames = totalFrames;
		mouseEnabled = false;
		mouseChildren = false;
		addEventListener(Event.ENTER_FRAME, advance);
		redraw();
	}

	private function advance(_:Event):Void {
		advanceOneFrame();
	}

	public function advanceOneFrame():Void {
		if (currentFrame < totalFrames) currentFrame++;
		redraw();
		if (currentFrame >= totalFrames) removeEventListener(Event.ENTER_FRAME, advance);
	}

	private function redraw():Void {
		while (numChildren > 0) removeChildAt(0);
		currentAssetPath = 'assets/svg/effects/${kind}_${StringTools.lpad(Std.string(currentFrame), "0", 2)}.svg';
		var art = SvgAsset.create(currentAssetPath);
		art.name = currentAssetPath;
		addChild(art);
	}

	public function dispose():Void {
		removeEventListener(Event.ENTER_FRAME, advance);
	}
}
