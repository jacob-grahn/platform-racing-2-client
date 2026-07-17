package pr2.ui.view;

import openfl.display.Shape;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;

/** Native replacement for the looping LoadingGraphic timeline. */
class LoadingView extends NativeView {
	private final spinner:Shape;
	private final label:TextField;
	private var frame:Int = 0;

	public function new() {
		super();
		spinner = new Shape();
		for (index in 0...12) {
			var angle = index * Math.PI / 6;
			var alpha = 0.2 + index * 0.065;
			spinner.graphics.beginFill(0x555555, alpha);
			spinner.graphics.drawCircle(Math.cos(angle) * 20, Math.sin(angle) * 20, 3.5);
			spinner.graphics.endFill();
		}
		spinner.x = 0;
		spinner.y = 0;
		addChild(spinner);

		label = new TextField();
		label.x = -24;
		label.y = 27;
		label.width = 70;
		label.height = 19;
		label.selectable = false;
		label.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 11, 0x404040, true);
		label.text = "Loading...";
		addChild(label);
		listen(this, Event.ENTER_FRAME, onFrame);
	}

	private function onFrame(_:Event):Void {
		frame++;
		spinner.rotation = (frame % 14) * (360 / 14);
		var phase = Std.int(frame / 10) % 4;
		label.text = "Loading" + (phase == 0 ? "..." : phase == 1 ? "" : phase == 2 ? "." : "..");
	}
}
