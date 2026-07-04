package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import pr2.gameplay.Items;
import pr2.runtime.FlCheckBox;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/** Read-only level-info item hover menu, ported from Flash `dialogs.ItemMenu`. */
class ItemMenu extends InfoPopup {
	private var art:Null<PR2MovieClip>;
	private var checks:Map<Int, FlCheckBox> = new Map();

	public function new(itemsStr:Null<String>, target:DisplayObject) {
		super();
		art = PR2MovieClip.fromLinkage("ItemMenuGraphic", {maxNestedDepth: 6});
		addChild(art);
		var selected = parseItems(itemsStr);
		for (itemId in Items.getAllCodes()) {
			var check = Std.downcast(DisplayUtil.findByName(art, "check" + itemId), FlCheckBox);
			if (check != null) {
				check.selected = selected.indexOf(itemId) >= 0;
				check.enabled = false;
				checks.set(itemId, check);
			}
		}
		positionNear(target);
	}

	public function isItemSelected(itemId:Int):Bool {
		var check = checks.get(itemId);
		return check != null && check.selected;
	}

	public function isItemEnabled(itemId:Int):Bool {
		var check = checks.get(itemId);
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

	private static function parseItems(itemsStr:Null<String>):Array<Int> {
		if (itemsStr == null || itemsStr == "all") {
			return Items.getAllCodes();
		}
		if (itemsStr == "") {
			return [];
		}
		var out:Array<Int> = [];
		for (itemName in itemsStr.split("`")) {
			var itemCode = itemName.length > 1 ? Items.getCodeFromName(itemName) : Std.parseInt(itemName);
			if (itemCode != null && Items.getAllCodes().indexOf(itemCode) >= 0 && out.indexOf(itemCode) < 0) {
				out.push(itemCode);
			}
		}
		return out;
	}
}
