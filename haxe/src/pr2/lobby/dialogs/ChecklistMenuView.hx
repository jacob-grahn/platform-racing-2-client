package pr2.lobby.dialogs;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.runtime.SvgAsset;
import pr2.ui.controls.GameCheckBox;
import pr2.ui.view.NativeView;

/** Shared native checklist used by editable settings and read-only level details. */
class ChecklistMenuView extends NativeView {
	public function new(kind:String) {
		super();
		var hats = kind == "hats";
		if (hats) {
			buildHats();
			return;
		}
		buildItems();
	}

	private function buildHats():Void {
		var background = SvgAsset.createNormalized("assets/svg/ui/shadow_bg.svg");
		background.name = "background";
		background.x = -145;
		background.y = -85;
		background.scaleX = 1.066162109375;
		background.scaleY = 0.890045166015625;
		addChild(background);
		var title = new TextField();
		title.name = "title";
		title.x = -60.5;
		title.y = -72.8;
		title.width = 120.95;
		title.height = 14.55;
		title.scaleX = 1.00047302246094;
		title.selectable = false;
		title.mouseEnabled = false;
		title.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0x000000, true, null, null, null, null,
			TextFormatAlign.CENTER);
		title.text = "-- Hats Allowed --";
		addChild(title);
		var labels = ["EXP", "Kong", "Propeller", "Cowboy", "Crown", "Santa", "Party", "Top", "Jump-Start", "Moon", "Thief", "Jigg",
			"Artifact", "Jellyfish", "Cheese"];
		for (index in 0...labels.length) {
			var column = Std.int(index / 5);
			var row = index % 5;
			var x = column == 0 ? (index == 1 || index == 2 ? -130.8 : -130.85) : column == 1 ? (index == 6 ? -40.8 : -40.85) : (index == 11 ? 49.15 : 49.1);
			var scale = column == 0 ? (index == 0 ? 0.899398803710938 : 0.899429321289062) : 0.899993896484375;
			addAuthoredCheck("hat" + (index + 2), labels[index], x, -48.8 + row * 25, scale * 100);
		}
	}

	private function addAuthoredCheck(name:String, label:String, x:Float, y:Float, width:Float):Void {
		var check = ownControl(new GameCheckBox(label));
		check.name = name;
		check.x = x;
		check.y = y;
		check.setSize(width, 22);
		check.selected = true;
		addChild(check);
	}

	private function buildItems():Void {
		var background = SvgAsset.createNormalized("assets/svg/ui/shadow_bg.svg");
		background.name = "background";
		background.x = -118.9;
		background.y = -61.4;
		background.scaleX = 0.8673095703125;
		background.scaleY = 0.984298706054688;
		addChild(background);
		var title = new TextField();
		title.name = "title";
		title.x = -35.6;
		title.y = -49;
		title.width = 70.55;
		title.height = 14.55;
		title.scaleX = 1.00047302246094;
		title.selectable = false;
		title.mouseEnabled = false;
		title.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0x000000, true);
		title.text = "-- Items --";
		addChild(title);
		addAuthoredCheck("check1", "Laser Gun", -102, -19, 100);
		addAuthoredCheck("check6", "Jet Pack", -102, 6, 100);
		addAuthoredCheck("check3", "Lightning", -102, 31, 100);
		addAuthoredCheck("check4", "Teleport", -102, 56, 100);
		addAuthoredCheck("check9", "Ice Wave", -102, 81, 100);
		addAuthoredCheck("check7", "Speed Burst", 6, -19, 100);
		addAuthoredCheck("check5", "Super Jump", 6, 6, 100);
		addAuthoredCheck("check8", "Sword", 6, 31, 100);
		addAuthoredCheck("check2", "Mine", 6, 56, 100);
	}

}
