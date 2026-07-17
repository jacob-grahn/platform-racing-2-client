package pr2.lobby.tabs;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native account-tab background and named information/action controls. */
class AccountInfoView extends NativeView {
	public function new() {
		super();
		graphics.beginFill(0xF1F1F1, 0.95);
		graphics.lineStyle(1, 0x777777);
		graphics.drawRoundRect(8, 8, 266, 342, 12, 12);
		graphics.endFill();
		field("nameBox", 21, 18, 238, 24, 15, true, TextFormatAlign.LEFT);
		field("guildBox", 21, 45, 238, 20, 11, false, TextFormatAlign.LEFT);
		field("rankBox", 21, 68, 115, 20, 11, true, TextFormatAlign.LEFT);
		field("hatBox", 145, 68, 112, 20, 11, false, TextFormatAlign.RIGHT);
		button("rankTokenUp_bt", "+", 65, 91, 27);
		button("rankTokenDown_bt", "-", 95, 91, 27);
		button("loadouts_bt", "Loadouts", 174, 91, 82);
		var divider = new openfl.display.Shape();
		divider.graphics.lineStyle(1, 0xAAAAAA);
		divider.graphics.moveTo(20, 125);
		divider.graphics.lineTo(260, 125);
		addChild(divider);
	}

	private function button(name:String, label:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 23);
		addChild(control);
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign):Void {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		addChild(text);
	}
}
