package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.display.Shape;
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
	public final panel:DisplayObject;
	public final heading:TextField;

	public function new(layout:ModerationMenuLayout, title:String, specs:Array<{name:String, label:String, press:Void->Void}>) {
		super();
		panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = layout == Admin ? -50 : -86;
		panel.y = layout == Admin ? -75 : -99;
		panel.scaleX = layout == Admin ? 0.367599487304688 : 0.632369995117188;
		panel.scaleY = layout == Admin ? 0.785232543945312 : 1.03675842285156;
		addChild(panel);

		heading = new TextField();
		heading.x = layout == Admin ? -38 : -32.2;
		heading.y = layout == Admin ? -67 : -88.1;
		heading.width = layout == Admin ? 76 : 64.3;
		heading.height = layout == Admin ? 14.55 : 17.05;
		heading.selectable = false;
		heading.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), layout == Admin ? 12 : 14, 0, false, null, null, null, null,
			layout == Admin ? TextFormatAlign.CENTER : TextFormatAlign.LEFT);
		heading.text = title;
		addChild(heading);
		if (layout == TempMod) {
			var separator = new Shape();
			separator.name = "separator";
			separator.graphics.lineStyle(1, 0xCCCCCC);
			separator.graphics.moveTo(-66.5, 35.5);
			separator.graphics.lineTo(66.5, 35.5);
			addChild(separator);
		}

		for (spec in specs) {
			var button = ownControl(new GameButton(spec.label));
			button.name = spec.name;
			button.x = -35;
			button.y = adminY(spec.name);
			button.setSize(70.0164794921875, 22);
			if (layout == TempMod) {
				button.x = -50;
				button.y = tempY(spec.name);
				button.setSize(100, 22);
			}
			button.onPress = spec.press;
			buttons.set(spec.name, button);
			addChild(button);
		}
	}

	private static function adminY(name:String):Float return switch (name) {
		case "tempMod_bt": -43;
		case "trialMod_bt": -16;
		case "permaMod_bt": 11;
		default: 38;
	}

	private static function tempY(name:String):Float return switch (name) {
		case "warning1Button": -60;
		case "warning2Button": -34;
		case "warning3Button": -8;
		default: 55;
	}

	override public function dispose():Void {
		buttons.clear();
		super.dispose();
	}
}

enum ModerationMenuLayout {
	Admin;
	TempMod;
}
