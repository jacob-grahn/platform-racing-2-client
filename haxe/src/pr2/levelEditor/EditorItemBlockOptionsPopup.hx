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
			var check:Null<FlCheckBox> = Std.downcast(DisplayUtil.findByName(art, "check" + itemId), FlCheckBox);
			if (check == null && itemId == Items.SNAKE) {
				check = new FlCheckBox("Snake");
				check.name = "check" + itemId;
				var previous = Std.downcast(DisplayUtil.findByName(art, "check" + Items.ICE_WAVE), FlCheckBox);
				check.x = previous == null ? 8 : previous.x;
				check.y = previous == null ? 142 : previous.y + 18;
				art.addChild(check);
			}
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
