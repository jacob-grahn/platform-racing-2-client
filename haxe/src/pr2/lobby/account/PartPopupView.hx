package pr2.lobby.account;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Exact native composition of the authored PartPopupGraphic shell. */
class PartPopupView extends NativeView {
	public final panel:Sprite;

	public function new() {
		super();
		panel = new Sprite();
		panel.name = "panel";
		panel.x = -198.95;
		panel.y = -98.65;
		panel.scaleX = 1.47056579589844;
		panel.scaleY = 1.04719543457031;
		panel.addChild(NativeAssets.svg(StaticSvg.QuantityPanel));
		addChild(panel);
		field("titleBox", -175.95, -85, 354.95, 14.55, 12, true, TextFormatAlign.CENTER, 0x000000);
		field("descBox", -180.95, -66.45, 364.95, 14.5, 10, false, TextFormatAlign.CENTER, 0x666666);
		field("ownedBox", -46.3, -43.75, 144.95, 14.55, 11, false, TextFormatAlign.LEFT, 0x000000);
		field("epicBox", -46.3, -25.2, 230.3, 13.35, 11, false, TextFormatAlign.LEFT, 0x000000);
		var obtain = field("obtainBox", -46.3, -7.85, 221.3, 47.65, 11, false, TextFormatAlign.LEFT, 0x000000);
		obtain.multiline = true;
		obtain.wordWrap = true;
		button("equip_bt", "Equip", -103, false);
		button("close_bt", "Close", 7, true);
	}

	private function button(name:String, value:String, x:Float, enabled:Bool):GameButton {
		var control = ownControl(new GameButton(value));
		control.name = name;
		control.x = x;
		control.y = 61.5;
		control.setSize(100, 22);
		control.enabled = enabled;
		addChild(control);
		return control;
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign,
		color:Int):TextField {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, bold, null, null, null, null, align);
		addChild(text);
		return text;
	}
}
