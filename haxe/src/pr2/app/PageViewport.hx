package pr2.app;

import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import pr2.Constants;

/** Apply the active page's coordinate system on every root transition. */
@:access(openfl.display.Stage)
class PageViewport {
	public static function apply(fullViewport:Bool):Void {
		var stage = AppStage.stage;
		if (stage == null) return;
		#if (js && html5)
		js.Browser.document.body.classList.toggle("pr2-fixed-stage", !fullViewport);
		if (fullViewport) {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
		} else {
			stage.__setLogicalSize(Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
			stage.align = null;
			stage.scaleMode = StageScaleMode.SHOW_ALL;
		}
		#end
	}
}
