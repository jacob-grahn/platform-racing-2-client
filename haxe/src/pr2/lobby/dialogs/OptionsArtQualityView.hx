package pr2.lobby.dialogs;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameCheckBox;
import pr2.ui.view.NativeView;

/** Native composition of OptionsArtQualityMenuGraphic. */
class OptionsArtQualityView extends NativeView {
	public final losslessCheck:GameCheckBox;

	public function new(selected:Bool) {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -115;
		panel.y = -33.95;
		panel.scaleX = 0.8455810546875;
		panel.scaleY = 0.83758544921875;
		addChild(panel);
		addLabel("-- Art Quality --", -59.7, -24.4, 120, 18, 14, true, TextFormatAlign.CENTER);
		losslessCheck = ownControl(new GameCheckBox("Lossless quality", selected));
		losslessCheck.name = "lossless_chk";
		losslessCheck.x = -85.7;
		losslessCheck.y = -0.95;
		losslessCheck.setSize(178, 22);
		addChild(losslessCheck);
		addLabel("This setting maximizes art quality but may increase drawing time. That may annoy your friends. Art in the Level Editor will always be drawn at lossless quality.", -96, 32.5, 192, 62, 9, false, TextFormatAlign.LEFT);
	}

	private function addLabel(value:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign):Void {
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.multiline = true;
		field.wordWrap = true;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0, bold, null, null, null, null, align);
		field.text = value;
		addChild(field);
	}
}
