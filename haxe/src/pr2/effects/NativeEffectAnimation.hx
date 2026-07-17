package pr2.effects;

import openfl.display.Sprite;
import openfl.events.Event;

/** Deterministic native frame animation for the short mine and teleport bursts. */
class NativeEffectAnimation extends Sprite {
	public var currentFrame(default, null):Int = 1;
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
		if (currentFrame < totalFrames) currentFrame++;
		redraw();
	}

	private function redraw():Void {
		graphics.clear();
		var progress = (currentFrame - 1) / Math.max(1, totalFrames - 1);
		if (kind == "mine") drawMine(progress); else if (kind == "slash") drawSlash(progress); else drawTeleport(progress);
	}

	private function drawMine(progress:Float):Void {
		var fade = 1 - progress;
		var radius = 9 + progress * 30;
		graphics.beginFill(0xFFCC00, fade * 0.9);
		drawStar(radius, radius * 0.45, 12);
		graphics.endFill();
		graphics.beginFill(0xFFFFFF, fade);
		graphics.drawCircle(0, 0, Math.max(1, 9 * fade));
		graphics.endFill();
	}

	private function drawTeleport(progress:Float):Void {
		var fade = 1 - progress;
		var radius = 5 + progress * 27;
		graphics.lineStyle(3 * fade + 0.5, 0xBDEEFF, fade);
		graphics.drawCircle(0, 0, radius);
		graphics.lineStyle(2 * fade + 0.5, 0xFFFFFF, fade * 0.9);
		graphics.drawCircle(0, 0, radius * 0.62);
		for (index in 0...8) {
			var angle = index * Math.PI / 4 + progress * 0.8;
			var inner = radius * 0.25;
			var outer = radius * 1.25;
			graphics.moveTo(Math.cos(angle) * inner, Math.sin(angle) * inner);
			graphics.lineTo(Math.cos(angle) * outer, Math.sin(angle) * outer);
		}
	}

	private function drawSlash(progress:Float):Void {
		var fade = 1 - progress;
		var sweep = 0.25 + progress * 0.75;
		graphics.lineStyle(8 * fade + 1, 0xFFFFFF, fade);
		graphics.moveTo(-8, 18);
		graphics.curveTo(24 * sweep, -30 * sweep, 58 * sweep, -8);
		graphics.lineStyle(3 * fade + 0.5, 0xBDEEFF, fade);
		graphics.moveTo(-5, 22);
		graphics.curveTo(29 * sweep, -22 * sweep, 62 * sweep, -3);
	}

	private function drawStar(outer:Float, inner:Float, points:Int):Void {
		for (index in 0...(points * 2)) {
			var radius = index % 2 == 0 ? outer : inner;
			var angle = -Math.PI / 2 + index * Math.PI / points;
			var x = Math.cos(angle) * radius;
			var y = Math.sin(angle) * radius;
			if (index == 0) graphics.moveTo(x, y); else graphics.lineTo(x, y);
		}
		graphics.lineTo(0, -outer);
	}

	public function dispose():Void {
		removeEventListener(Event.ENTER_FRAME, advance);
	}
}
