package pr2.page;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.Constants;
import pr2.app.DebugSignal;
import pr2.character.CharacterDisplay;

/** Side-by-side, motionless comparison of stand frame 1 with explicit caches off/on. */
class CharacterPartCachePreview extends Sprite {
	private static inline var PANEL_WIDTH:Float = 245;
	private static inline var ANCHOR_Y:Float = 250;

	public function new() {
		super();
		graphics.beginFill(0xD9E0E8);
		graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		graphics.endFill();

		addPanel(20, "UNCACHED", false);
		addPanel(285, "EXPLICIT PART CACHE", true);
		DebugSignal.set("character-part-cache", "ready");
	}

	private function addPanel(panelX:Float, title:String, cached:Bool):Void {
		graphics.beginFill(0xF8FAFC);
		graphics.lineStyle(1, 0x8A96A3);
		graphics.drawRect(panelX, 24, PANEL_WIDTH, 350);
		graphics.endFill();

		var anchorX = panelX + PANEL_WIDTH / 2;
		graphics.lineStyle(1, 0xB7C0CA, 0.8);
		graphics.moveTo(anchorX - 18, ANCHOR_Y);
		graphics.lineTo(anchorX + 18, ANCHOR_Y);
		graphics.moveTo(anchorX, ANCHOR_Y - 18);
		graphics.lineTo(anchorX, ANCHOR_Y + 18);

		var label = new TextField();
		label.defaultTextFormat = new TextFormat("_sans", 13, 0x263442, true);
		label.selectable = false;
		label.width = PANEL_WIDTH;
		label.height = 24;
		label.text = title;
		label.x = panelX;
		label.y = 38;
		label.autoSize = openfl.text.TextFieldAutoSize.CENTER;
		label.x = anchorX - label.width / 2;
		addChild(label);

		var character = new CharacterDisplay(
			{hat: 5, head: 1, body: 1, feet: 1},
			{primary: 0x3399FF, secondary: 0xFFD24A},
			cached
		);
		character.x = anchorX;
		character.y = ANCHOR_Y;
		character.scaleX = character.scaleY = 3;
		addChild(character);
	}
}
