package pr2.lobby.dialogs;

import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameCheckBox;
import pr2.ui.view.NativeView;

/** Native two-column song selection menu. */
class OptionsSongsView extends NativeView {
	public final checks:Map<Int, GameCheckBox> = new Map();

	public function new(disabled:Array<String>) {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -150;
		panel.y = -22;
		panel.scaleX = 1.1;
		panel.scaleY = 1.18;
		addChild(panel);
		var names = [
			1 => "Orbital Trance", 2 => "Code", 3 => "Paradise on E", 4 => "Crying Soul", 5 => "My Vision", 6 => "Switchblade",
			7 => "The Wires", 8 => "Before Mydnite", 10 => "Broked It", 11 => "Hello?", 12 => "Pyrokinesis", 13 => "Flowers 'n' Herbs",
			14 => "Instrumental #4", 15 => "Prismatic", 17 => "Toodaloo", 18 => "Night Shade", 19 => "Blizzard!", 20 => "Pasture",
			21 => "Sunset Raiders"
		];
		var leftIndex = 0;
		var rightIndex = 0;
		for (songId in 1...22) {
			if (!names.exists(songId)) continue;
			var right = songId >= 12;
			var row = right ? rightIndex++ : leftIndex++;
			var check = ownControl(new GameCheckBox(names.get(songId), disabled.indexOf(Std.string(songId)) < 0));
			check.name = "song" + songId;
			check.x = right ? 5 : -135;
			check.y = -5 + row * 20;
			check.setSize(132, 20);
			checks.set(songId, check);
			addChild(check);
		}
	}
}
