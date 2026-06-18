package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import pr2.app.AppStage;

/**
	Port of Flash `dialogs.InfoPopup`: a small non-modal popup placed beside a
	target display object (left of it when there's room, otherwise to the right),
	clamped to the 400px-tall stage. Tooltips (`HoverPopup`) extend this.

	Flash positioned in its constructor after the subclass had sized itself; Haxe
	requires `super()` first, so positioning is exposed as `positionNear`, which the
	subclass calls once its content is built.
**/
class InfoPopup extends Sprite {
	public function new() {
		super();
	}

	private function positionNear(d:DisplayObject):Void {
		if (AppStage.stage == null) {
			return;
		}
		var stage = AppStage.stage;
		var stageBounds = getBounds(stage);
		var boxBounds = d.getBounds(stage);
		var distToLeft = boxBounds.left > width ? boxBounds.left - width - 7 : boxBounds.right + 7;
		var distToTop = boxBounds.top;
		if (distToTop < 0) {
			distToTop = 0;
		}
		if ((distToTop + height) > 400) {
			distToTop = 400 - height;
		}
		x = Math.round(distToLeft - stageBounds.left);
		y = Math.round(distToTop - stageBounds.top);
		stage.addChild(this);
	}

	public function remove():Void {
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
