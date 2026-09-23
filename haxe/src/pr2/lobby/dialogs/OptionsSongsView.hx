package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameCheckBox;
import pr2.ui.view.NativeView;
import pr2.lobby.account.OptionsSettings;

/** Native two-column song selection menu. */
class OptionsSongsView extends NativeView {
	public final checks:Map<Int, GameCheckBox> = new Map();
	public final panel:DisplayObject;
	public final title:TextField;

	public function new(disabled:Array<String>) {
		super();
		panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -137.5;
		panel.y = -125;
		panel.scaleX = 1.01100158691406;
		panel.scaleY = 1.30888366699219;
		addChild(panel);
		title = new TextField();
		title.x = -48.0031227111816;
		title.y = -113;
		title.width = 95.9;
		title.height = 14.55;
		title.scaleX = 1.00094604492188;
		title.selectable = false;
		title.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0, true, null, null, null, null, TextFormatAlign.CENTER);
		title.text = "-- Songs --";
		addChild(title);
		var names = OptionsSettings.SONGS;
		var leftIndex = 0;
		var rightIndex = 0;
		for (songId in 1...22) {
			if (!names.exists(songId)) continue;
			var right = songId >= 12;
			var row = right ? rightIndex++ : leftIndex++;
			var check = ownControl(new GameCheckBox(names.get(songId), disabled.indexOf(Std.string(songId)) < 0));
			check.name = "song" + songId;
			check.x = right ? ([14, 15, 17].indexOf(songId) >= 0 ? 5.55 : 5.65) : -127.95;
			check.y = -86 + row * 20;
			check.setSize(125, 13.7469787597656);
			checks.set(songId, check);
			addChild(check);
		}
	}
}
