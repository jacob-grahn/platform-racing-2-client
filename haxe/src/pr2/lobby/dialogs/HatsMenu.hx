package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import pr2.character.Parts;
import pr2.runtime.FlCheckBox;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/** Read-only level-info hat hover menu, ported from Flash `dialogs.HatsMenu`. */
class HatsMenu extends InfoPopup {
	private static inline var LOWEST_HAT_ID:Int = 2;
	private static final HIGHEST_HAT_ID:Int = Parts.getPartArray("HAT").length + 1;
	private static inline var ARTIFACT_HAT_ID:Int = 14;

	private var art:Null<PR2MovieClip>;
	private var checks:Map<Int, FlCheckBox> = new Map();

	public function new(hatsStr:Null<String>, gameMode:Null<String>, target:DisplayObject) {
		super();
		art = PR2MovieClip.fromLinkage("HatsMenuGraphic", {maxNestedDepth: 6});
		addChild(art);
		var allowed = parseHats(hatsStr, gameMode);
		for (hatId in LOWEST_HAT_ID...HIGHEST_HAT_ID + 1) {
			var check = Std.downcast(DisplayUtil.findByName(art, "hat" + hatId), FlCheckBox);
			if (check != null) {
				check.selected = allowed.indexOf(hatId) >= 0;
				check.enabled = false;
				checks.set(hatId, check);
			}
		}
		positionNear(target);
	}

	public function isHatAllowed(hatId:Int):Bool {
		var check = checks.get(hatId);
		return check != null && check.selected;
	}

	public function isHatEnabled(hatId:Int):Bool {
		var check = checks.get(hatId);
		return check != null && check.enabled;
	}

	override public function remove():Void {
		checks.clear();
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private static function parseHats(hatsStr:Null<String>, gameMode:Null<String>):Array<Int> {
		var allowed = [for (hatId in LOWEST_HAT_ID...HIGHEST_HAT_ID + 1) hatId];
		if (gameMode == "Hat Attack") {
			allowed.remove(ARTIFACT_HAT_ID);
		}
		if (hatsStr == null || hatsStr == "") {
			return allowed;
		}
		for (hatText in hatsStr.split(",")) {
			var hatId = Std.parseInt(hatText);
			if (hatId != null && !Math.isNaN(hatId) && hatId > 1 && hatId <= HIGHEST_HAT_ID) {
				allowed.remove(hatId);
			}
		}
		return allowed;
	}
}
