package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.filters.DropShadowFilter;
import pr2.lobby.LobbyArt;
import pr2.runtime.PR2MovieClip;

/** Flash `ui.ProgressBar`, backed by the authored `ProgressBarGraphic`. */
class ProgressBar extends Sprite {
	private var art:Null<PR2MovieClip>;
	private var fill:Null<DisplayObject>;
	private var totalPx:Float;
	private var targetPx:Float = 0;
	private var widthPx:Float = 0;
	private var lerpFactor:Float;

	public function new(px:Float = 200, lerpFactor:Float = 0.3) {
		super();
		this.lerpFactor = lerpFactor;
		art = PR2MovieClip.fromLinkage("ProgressBarGraphic", {maxNestedDepth: 3});
		art.filters = [new DropShadowFilter(2, 45, 0, 1, 2, 2)];
		addChild(art);
		art.width = px;
		fill = LobbyArt.findByName(art, "bar");
		totalPx = px - 4;
		if (fill != null) fill.width = 0;
		addEventListener(Event.ENTER_FRAME, update);
	}

	public function setProgress(value:Float):Void {
		targetPx = totalPx * Math.max(0, Math.min(1, value));
	}

	private function update(_:Event):Void {
		widthPx += (targetPx - widthPx) * lerpFactor;
		if (fill != null) fill.width = widthPx;
	}

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, update);
		if (art != null) {
			art.dispose();
			art = null;
		}
		fill = null;
		if (parent != null) parent.removeChild(this);
	}
}
