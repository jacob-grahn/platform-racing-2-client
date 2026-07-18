package pr2.levelEditor;

import pr2.gameplay.Items;
import pr2.page.EditorBlockOptions;
import pr2.ui.controls.GameCheckBox;

class EditorItemBlockOptionsPopup extends EditorBlockOptionsPopup {
	private final checks:Map<Int, GameCheckBox> = new Map();

	public function new(editor:LevelEditor, block:EditorBlockObject) {
		super(editor, block, "ItemBlockOptionsGraphic");
		var selected = EditorBlockOptions.selectedItems(block.options, editor.allowedItems);
		for (itemId in flashItemCodes()) {
			var check:Null<GameCheckBox> = Std.downcast(art.childNamed("check" + itemId), GameCheckBox);
			if (check != null) {
				check.selected = selected.indexOf(itemId) >= 0;
				checks.set(itemId, check);
			}
		}
	}

	public function setItemSelected(itemId:Int, selected:Bool):Void {
		var check = checks.get(itemId);
		if (check != null) {
			check.selected = selected;
		}
	}

	override public function remove():Void {
		var selected:Array<Int> = [];
		for (itemId in flashItemCodes()) {
			var check = checks.get(itemId);
			if (check != null && check.selected) {
				selected.push(itemId);
			}
		}
		block.setOptions(EditorBlockOptions.applyItemOptions(selected, editor.allowedItems));
		super.remove();
	}

	private static function flashItemCodes():Array<Int> {
		return [Items.LASER_GUN, Items.MINE, Items.LIGHTNING, Items.TELEPORT, Items.SUPER_JUMP, Items.JET_PACK, Items.SPEED_BURST, Items.SWORD,
			Items.ICE_WAVE];
	}
}
