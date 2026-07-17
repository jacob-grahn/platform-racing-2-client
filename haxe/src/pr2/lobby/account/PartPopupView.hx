package pr2.lobby.account;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native part detail card with description, ownership, and Equip action. */
class PartPopupView extends NativeView {
	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-190, -155, 380, 310, 14, 14);
		graphics.endFill();
		field("titleBox", -165, -142, 330, 24, 16, true, TextFormatAlign.CENTER);
		var desc = field("descBox", -18, -102, 168, 72, 11, false, TextFormatAlign.LEFT);
		desc.multiline = true;
		desc.wordWrap = true;
		var obtain = field("obtainBox", -165, 48, 330, 48, 10, false, TextFormatAlign.LEFT);
		obtain.multiline = true;
		obtain.wordWrap = true;
		field("ownedBox", -165, 101, 200, 20, 10, true, TextFormatAlign.LEFT);
		field("epicBox", -165, 122, 220, 20, 10, true, TextFormatAlign.LEFT);
		button("equip_bt", "Equip", 67, 112, 78).enabled = false;
		button("close_bt", "Close", 67, 82, 78);
		var previewGuide = new Sprite();
		previewGuide.graphics.beginFill(0xE8EBEF);
		previewGuide.graphics.drawCircle(-92, -35, 58);
		previewGuide.graphics.endFill();
		addChildAt(previewGuide, 0);
	}

	private function button(name:String, value:String, x:Float, y:Float, width:Float):GameButton {
		var control = ownControl(new GameButton(value));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 24);
		addChild(control);
		return control;
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign):TextField {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		addChild(text);
		return text;
	}
}
