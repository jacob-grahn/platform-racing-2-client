package pr2.lobby.dialogs;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.filters.DropShadowFilter;

/** Native composition of Flash's 200 x 9px `ProgressBarGraphic`. */
class ProgressBar extends Sprite {
	private var fill:Null<Shape>;
	private var totalPx:Float;
	private var targetPx:Float = 0;
	private var widthPx:Float = 0;
	private var lerpFactor:Float;

	public function new(px:Float = 200, lerpFactor:Float = 0.3) {
		super();
		this.lerpFactor = lerpFactor;
		filters = [new DropShadowFilter(2, 45, 0, 1, 2, 2)];
		addChild(createBorder(px));
		fill = createFill();
		addChild(fill);
		totalPx = px - 4;
		fill.width = 0;
		addEventListener(Event.ENTER_FRAME, update);
	}

	public function setProgress(value:Float):Void {
		targetPx = totalPx * Math.max(0, Math.min(1, value));
	}

	public function tickForTests():Void {
		update(null);
	}

	public function displayedWidthForTests():Float {
		return widthPx;
	}

	public function targetWidthForTests():Float {
		return targetPx;
	}

	private function update(_:Event):Void {
		widthPx += (targetPx - widthPx) * lerpFactor;
		if (fill != null) fill.width = widthPx;
	}

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, update);
		fill = null;
		if (parent != null) parent.removeChild(this);
	}

	private static function createBorder(width:Float):Shape {
		var border = new Shape();
		border.graphics.lineStyle(0.05, 0xFFFFFF);
		border.graphics.drawRoundRect(0, 0, width, 9, 6, 6);
		return border;
	}

	private static function createFill():Shape {
		var result = new Shape();
		result.x = 2;
		result.y = 2;
		result.graphics.beginFill(0xFFFFFF);
		// The source 100px square has 3px corners, then the authored instance
		// scales only its y axis to 0.05999755859375.
		result.graphics.drawRoundRect(0, 0, 100, 6, 6, 0.3599853515625);
		result.graphics.endFill();
		return result;
	}
}
