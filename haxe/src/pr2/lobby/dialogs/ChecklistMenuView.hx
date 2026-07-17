package pr2.lobby.dialogs;

import pr2.character.Parts;
import pr2.gameplay.Items;
import pr2.ui.controls.GameCheckBox;
import pr2.ui.view.NativeView;

/** Shared native checklist used by editable settings and read-only level details. */
class ChecklistMenuView extends NativeView {
	public function new(kind:String) {
		super();
		var hats = kind == "hats";
		var count = hats ? 15 : Items.getAllCodes().length;
		var rows = Math.ceil(count / 2);
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-145, -15, 290, rows * 26 + 30, 12, 12);
		graphics.endFill();
		if (hats) {
			for (hatId in 2...17) addCheck("hat" + hatId, Parts.getName("HAT", hatId), hatId - 2);
		} else {
			var codes = Items.getAllCodes();
			for (i in 0...codes.length) addCheck("check" + codes[i], Items.getNameFromCode(codes[i]), i);
		}
	}

	private function addCheck(name:String, label:String, index:Int):Void {
		var check = ownControl(new GameCheckBox(label));
		check.name = name;
		check.x = index < 8 ? -132 : 7;
		check.y = 0 + (index % 8) * 26;
		check.setSize(130, 22);
		addChild(check);
	}
}
