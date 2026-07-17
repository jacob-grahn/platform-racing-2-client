package pr2.gameplay;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native spectating selector with explicit controls and dual-layer name text. */
class SpectatePickerView extends NativeView {
	public final nameTop:TextField;
	public final nameBg:TextField;
	public final spectatingText:TextField;

	public function new() {
		super();
		graphics.beginFill(0xEEEEEE, 0.92);
		graphics.lineStyle(1, 0x555555);
		graphics.drawRoundRect(0, 0, 258, 52, 9, 9);
		graphics.endFill();
		var left = ownControl(new GameButton("<"));
		left.name = "arrowLeft";
		left.x = 7;
		left.y = 14;
		left.setSize(30, 28);
		addChild(left);
		var right = ownControl(new GameButton(">"));
		right.name = "arrowRight";
		right.x = 221;
		right.y = 14;
		right.setSize(30, 28);
		addChild(right);
		nameBg = label("box", 40, 21, 178, 22, 12, 0xFFFFFF, true);
		nameBg.x += 1;
		nameBg.y += 1;
		addChild(nameBg);
		nameTop = label("box", 40, 21, 178, 22, 12, 0x222222, true);
		addChild(nameTop);
		spectatingText = label("spectatingText", 40, 3, 178, 16, 10, 0x666666, true);
		spectatingText.text = "SPECTATING";
		addChild(spectatingText);
	}

	private static function label(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, color:Int, bold:Bool):TextField {
		var field = new TextField();
		field.name = name;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, bold, null, null, null, null,
			TextFormatAlign.CENTER);
		return field;
	}
}
