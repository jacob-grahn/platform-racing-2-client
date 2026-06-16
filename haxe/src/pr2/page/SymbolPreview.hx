package pr2.page;

import openfl.display.Sprite;
import openfl.geom.Rectangle;
import pr2.runtime.PR2MovieClip;

/**
	Debug screen that renders a single library symbol through the vector
	renderer so its OpenFL output can be screenshotted and compared against the
	Adobe-exported PNG. Driven by `?screen=symbol&symbol=<name>&scale=<n>`.

	The symbol is drawn at `scale` (default 4, matching the `@4x` reference
	rasters) and its drawing bounds are aligned to a fixed inset so the capture
	rectangle is deterministic.
**/
class SymbolPreview extends Sprite {
	public static inline var INSET:Float = 10;

	public function new(symbolName:Null<String>, scale:Float, background:Int) {
		super();

		graphics.beginFill(background);
		graphics.drawRect(0, 0, 550, 400);
		graphics.endFill();

		if (symbolName == null || symbolName == "") {
			return;
		}

		var holder = new Sprite();
		holder.addChild(PR2MovieClip.fromSymbolName(symbolName));
		holder.scaleX = scale;
		holder.scaleY = scale;
		addChild(holder);

		var bounds:Rectangle = holder.getBounds(this);
		holder.x = INSET - bounds.x;
		holder.y = INSET - bounds.y;
	}
}
