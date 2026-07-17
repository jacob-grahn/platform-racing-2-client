package pr2.lobby.dialogs;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native button panel shared by the player moderation menus. */
class ModerationMenuView extends NativeView {
	public final buttons:Map<String, GameButton> = new Map();

	public function new(title:String, specs:Array<{name:String, label:String, press:Void->Void}>) {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -105;
		panel.y = -58;
		panel.scaleX = 0.78;
		panel.scaleY = 0.68;
		addChild(panel);

		var heading = new TextField();
		heading.x = -90;
		heading.y = -48;
		heading.width = 180;
		heading.height = 18;
		heading.selectable = false;
		heading.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 13, 0, true, null, null, null, null,
			TextFormatAlign.CENTER);
		heading.text = title;
		addChild(heading);

		for (index in 0...specs.length) {
			var spec = specs[index];
			var button = ownControl(new GameButton(spec.label));
			button.name = spec.name;
			button.x = index % 2 == 0 ? -88 : 4;
			button.y = -20 + Std.int(index / 2) * 29;
			button.setSize(84, 23);
			button.onPress = spec.press;
			buttons.set(spec.name, button);
			addChild(button);
		}
	}

	override public function dispose():Void {
		buttons.clear();
		super.dispose();
	}
}
