package pr2.lobby.tabs;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.view.NativeView;

/** Native account-tab background and named information/action controls. */
class AccountInfoView extends NativeView {
	public function new() {
		super();
		field("nameBox", 2, 0, 156.05, 14.55);
		field("rankBox", 2, 18, 176.05, 14.55);
		field("hatBox", 2, 36, 176.05, 14.55);
		field("guildBox", 2, 54, 176.05, 14.55);
		addButton(new RankTokenButton("rankTokenUp_bt"), 66, 18);
		addButton(new RankTokenButton("rankTokenDown_bt"), 101, 18);
		addButton(new LoadoutsIconButton(), 169, 2);
	}

	private function addButton(button:Sprite, x:Float, y:Float):Void {
		button.x = x;
		button.y = y;
		addChild(button);
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float):Void {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.multiline = true;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0x000000, false, null, null, null, null,
			TextFormatAlign.LEFT);
		addChild(text);
	}
}

private class RankTokenButton extends Sprite {
	public function new(buttonName:String) {
		super();
		name = buttonName;
		buttonMode = useHandCursor = true;
		graphics.beginFill(0xFFFFFF, 0);
		graphics.drawRect(0, 0, 40, 20);
		graphics.endFill();
		graphics.lineStyle(1, 0xFFFF00);
		graphics.beginFill(0x8C9254);
		graphics.drawRoundRect(0, 4, 12.15, 12.15, 4, 4);
		graphics.endFill();
		graphics.lineStyle(1, 0xFFFF00);
		graphics.beginFill(0xFF0000, 0.662745098039216);
		graphics.moveTo(6.2, 5.15);
		graphics.lineTo(2, 9.4);
		graphics.lineTo(5.1, 9.4);
		graphics.lineTo(5.1, 14.75);
		graphics.lineTo(7.3, 14.75);
		graphics.lineTo(7.3, 9.4);
		graphics.lineTo(10.4, 9.4);
		graphics.lineTo(6.2, 5.15);
		graphics.endFill();
		var text = new TextField();
		text.name = "textBox";
		text.x = 16;
		text.y = 2;
		text.width = 23;
		text.height = 14.55;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0x737373);
		addChild(text);
	}
}

private class LoadoutsIconButton extends Sprite {
	public function new() {
		super();
		name = "loadouts_bt";
		buttonMode = useHandCursor = true;
		var text = new TextField();
		text.x = 2;
		text.y = 2;
		text.width = 15.2;
		text.height = 16.75;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Icons), 14, 0x000000);
		text.text = "";
		addChild(text);
	}
}
