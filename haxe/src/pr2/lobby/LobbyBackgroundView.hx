package pr2.lobby;

import openfl.display.Shape;
import pr2.ui.view.NativeView;

/** Native lobby backdrop framing the left navigation and right content panes. */
class LobbyBackgroundView extends NativeView {
	public function new() {
		super();
		graphics.beginFill(0xC9DDEB);
		graphics.drawRect(0, 0, 550, 412);
		graphics.endFill();
		graphics.beginFill(0xEAF2F7, 0.97);
		graphics.lineStyle(1, 0x668296);
		graphics.drawRoundRect(8, 8, 170, 358, 14, 14);
		graphics.drawRoundRect(186, 8, 356, 358, 14, 14);
		graphics.endFill();
		var horizon = new Shape();
		horizon.graphics.beginFill(0xA8C8DB, 0.55);
		horizon.graphics.drawRect(0, 325, 550, 87);
		horizon.graphics.endFill();
		addChild(horizon);
		mouseEnabled = false;
		mouseChildren = false;
	}
}
