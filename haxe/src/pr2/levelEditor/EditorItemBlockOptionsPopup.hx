package pr2.levelEditor;

import pr2.gameplay.Items;
import pr2.page.EditorBlockOptions;
import pr2.runtime.FlCheckBox;
import pr2.util.DisplayUtil;

class EditorItemBlockOptionsPopup extends EditorBlockOptionsPopup {
	private final checks:Map<Int, FlCheckBox> = new Map();

	public function new(editor:LevelEditor, block:EditorBlockObject) {
		super(editor, block, "ItemBlockOptionsGraphic");
		var selected = EditorBlockOptions.selectedItems(block.options, editor.allowedItems);
		for (itemId in Items.getAllCodes()) {
			var check = Std.downcast(DisplayUtil.findByName(art, "check" + itemId), FlCheckBox);
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
		for (itemId in Items.getAllCodes()) {
			var check = checks.get(itemId);
			if (check != null && check.selected) {
				selected.push(itemId);
			}
		}
		block.setOptions(EditorBlockOptions.applyItemOptions(selected, editor.allowedItems));
		super.remove();
	}
}
