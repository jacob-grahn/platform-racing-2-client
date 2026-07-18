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

/** Native composition of OptionsArtQualityMenuGraphic. */
class OptionsArtQualityView extends NativeView {
	public final losslessCheck:GameCheckBox;
	public final panel:DisplayObject;
	public final title:TextField;
	public final description:TextField;

	public function new(selected:Bool) {
		super();
		panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -115;
		panel.y = -33.95;
		panel.scaleX = 0.8455810546875;
		panel.scaleY = 0.83758544921875;
		addChild(panel);
		title = addLabel("-- Art Quality --", -63.0031227111816, -24.4, 125.9, 14.55, 12, true, TextFormatAlign.CENTER, false);
		title.scaleX = 1.00094604492188;
		losslessCheck = ownControl(new GameCheckBox("Lossless (EXPERIMENTAL)", selected));
		losslessCheck.name = "lossless_chk";
		losslessCheck.x = -85.7;
		losslessCheck.y = -0.95;
		losslessCheck.setSize(178, 22);
		addChild(losslessCheck);
		description = addLabel("This setting maximizes art quality but may increase drawing time. That may annoy your friends. Art in the Level Editor will always be drawn at lossless quality.", -105, 32.5, 212, 80.75, 12, false, TextFormatAlign.CENTER, true);
	}

	private function addLabel(value:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign, wrap:Bool):TextField {
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.multiline = true;
		field.wordWrap = wrap;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0, bold, null, null, null, null, align);
		field.text = value;
		addChild(field);
		return field;
	}
}
