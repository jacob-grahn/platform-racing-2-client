package pr2.mobile;

import openfl.events.MouseEvent;
import pr2.ui.controls.GameSlider;

/** Shared slider behavior with a 44px touch target and landscape-game styling. */
class MobileValueSlider extends GameSlider {
	public function new(maximum:Float, value:Float) {
		super(0, maximum, value, 1);
		setSize(160, 44);
		addEventListener(MouseEvent.MOUSE_DOWN, ownDrag);
	}
	private function ownDrag(e:MouseEvent):Void e.stopPropagation();
	override public function redraw():Void {
		super.redraw();
		// Focus/hover/value redraws must retain the full touch target too.
		drawTrack(); drawThumb();
	}
	override private function drawTrack():Void {
		if (track == null) return;
		graphics.clear(); graphics.beginFill(0, .001); graphics.drawRect(0, 0, controlWidth, 44); graphics.endFill();
		track.graphics.clear(); track.graphics.lineStyle(2, 0x18334B); track.graphics.beginFill(0xD5E2E9);
		track.graphics.drawRoundRect(5, 18, controlWidth - 10, 8, 8, 8); track.graphics.endFill();
	}
	override private function drawThumb():Void {
		if (thumb == null) return;
		thumb.graphics.clear(); thumb.graphics.lineStyle(3, 0x18334B); thumb.graphics.beginFill(enabled ? 0xD1ED62 : 0xD5E2E9);
		thumb.graphics.drawCircle(0, 0, 13); thumb.graphics.endFill();
		thumb.x = 5 + (value / maximum) * Math.max(1, controlWidth - 10); thumb.y = 22;
	}
	override public function dispose():Void { removeEventListener(MouseEvent.MOUSE_DOWN, ownDrag); super.dispose(); }
}
