package pr2.lobby.dialogs;

import openfl.display.Sprite;
import openfl.display.DisplayObject;
import openfl.display.Graphics;
import openfl.display.Bitmap;
import openfl.display.GradientType;
import openfl.display.SpreadMethod;
import openfl.display.InterpolationMethod;
import openfl.geom.Matrix;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.utils.Assets;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.ControlSkin;
import pr2.ui.controls.ControlState;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameSlider;
import pr2.ui.view.NativeView;

/** Native options panel covering audio, filtering, art, controls, and account actions. */
class OptionsView extends NativeView {
	public final panel:DisplayObject;
	public final title:TextField;

	public function new() {
		super();
		panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -137.5;
		panel.y = -145;
		panel.scaleX = 1.01094055175781;
		panel.scaleY = 1.51835632324219;
		addChild(panel);
		highlight("artHighlight", -93.05, -71.5);
		highlight("filterHighlight", -28.15, -71.5);
		componentButton("close_bt", "Close", -50, 106.5, 100);
		label("↑", null, -68.75, -2.8, 16, 14.6, 12, false, TextFormatAlign.CENTER);
		input("wasdUp", -68.75, 14.5);
		label("↓", null, -68.75, 51.95, 16, 14.6, 12, false, TextFormatAlign.CENTER);
		input("wasdDown", -68.8, 35.5);
		label("→", null, -26.35, 35.5, 12.65, 14.6, 12, false, TextFormatAlign.RIGHT);
		input("wasdRight", -46.35, 35.5);
		label("←", null, -108.7, 35.45, 13.95, 14.6, 12, false, TextFormatAlign.LEFT);
		input("wasdLeft", -91.25, 35.45);
		input("wasdItem", -56, 70.5);
		var itemIcon = new Bitmap(Assets.getBitmapData("assets/bitmaps/options_item.png"));
		itemIcon.name = "itemIcon";
		itemIcon.transform.matrix = new Matrix(0.6666259765625, 0, 0, 0.6666259765625, -83, 68);
		addChild(itemIcon);
		label("alt keys", null, -87.5, -18, 52.5, 14.55, 12, false, TextFormatAlign.CENTER);
		linkButton("changePass_bt", "Change Password", 21, 80, 92.2, 10);
		linkButton("changeEmail_bt", "Change Email", 30, 60, 72.8, 10);
		linkButton("guildLeave_bt", "Leave Guild", 36.5, 40, 61.4, 10);
		linkButton("guildCreate_bt", "Create Guild", 33.5, 20, 66.35, 10);
		linkButton("guildTransfer_bt", "Transfer Guild", 30.2, -20, 72.4, 10);
		linkButton("guildEdit_bt", "Edit Guild", 41, 0, 52.45, 10);
		linkButton("music_bt", "music", 18.5, -106.5, 40, 12);
		label("", "soundPercentBox", 71.25, -92.2, 42.5, 14.55, 12, false, TextFormatAlign.CENTER);
		label("", "musicPercentBox", 20.5, -92.2, 36, 14.55, 12, false, TextFormatAlign.CENTER);
		label("sounds", null, 71.25, -104.5, 42.5, 14.55, 12, false, TextFormatAlign.CENTER);
		slider("soundSlider", 98.3, -67.5);
		slider("musicSlider", 45.45, -67.5);
		componentButton("filterOff_bt", "Off", -52.9, -54.5, 50);
		label("swear filter", null, -63.4, -104.5, 69.05, 14.55, 12, false, TextFormatAlign.CENTER);
		componentButton("filterOn_bt", "On", -52.9, -82.45, 50);
		linkButton("art_bt", "art", -108.2, -106.5, 30, 12);
		componentButton("artOff_bt", "Off", -118.2, -54.5, 50);
		componentButton("artOn_bt", "On", -118.2, -82.45, 50);
		label("art", "artOffText", -106.1, -104.5, 26, 14.55, 12, false, TextFormatAlign.CENTER);
		title = label("-- Options --", null, -53, -133, 106, 17.05, 14, true, TextFormatAlign.CENTER);
	}

	private function slider(name:String, x:Float, y:Float):Void {
		var control = ownControl(new GameSlider(0, 100, 100, 5));
		control.name = name;
		control.setSize(100, 22);
		control.transform.matrix = new Matrix(0, 1, 1, 0, x, y);
		addChild(control);
	}

	private function highlight(name:String, x:Float, y:Float):Void {
		var highlight = new Sprite();
		highlight.name = name;
		highlight.graphics.beginGradientFill(GradientType.LINEAR, [0x89BFF5, 0xFFFFFF, 0x7A6FE6], [1, 1, 1], [0, 125, 255],
			new Matrix(0, 0.01708984375, -0.0113677978515625, 0, -0.05, 0), SpreadMethod.PAD, InterpolationMethod.RGB, 0);
		highlight.graphics.drawRoundRect(-33.05, -13, 66.1, 26, 7, 7);
		highlight.graphics.endFill();
		highlight.graphics.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF], [1, 0, 0, 1], [0, 48, 216, 255],
			new Matrix(-0.0341949462890625, 0, 0, -0.015869140625, 0, 0), SpreadMethod.PAD, InterpolationMethod.RGB, 0);
		highlight.graphics.drawRoundRect(-33.05, -13, 66.1, 26, 7, 7);
		highlight.graphics.endFill();
		highlight.x = x;
		highlight.y = y;
		highlight.scaleX = 0.90771484375;
		highlight.scaleY = 1.0191650390625;
		addChild(highlight);
	}

	private function componentButton(name:String, value:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(value));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 22);
		addChild(control);
	}

	private function linkButton(name:String, value:String, x:Float, y:Float, width:Float, size:Int):Void {
		var control = ownControl(new OptionsLinkButton(value, width, size));
		control.name = name;
		control.x = x;
		control.y = y;
		addChild(control);
	}

	private function input(name:String, x:Float, y:Float):Void {
		var field = label("", name, x, y, 16, 14.55, 12, false, TextFormatAlign.CENTER);
		field.type = TextFieldType.INPUT;
		field.selectable = true;
	}

	private function label(value:String, name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign):TextField {
		var field = new TextField();
		if (name != null) field.name = name;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		field.text = value;
		addChild(field);
		return field;
	}
}

private class OptionsLinkButton extends GameButton {
	private final authoredSize:Int;

	public function new(value:String, width:Float, size:Int) {
		authoredSize = size;
		super(value, new OptionsLinkSkin());
		setSize(width, size == 12 ? 18.55 : 16.15);
	}

	override public function setSize(width:Float, height:Float):Void {
		super.setSize(width, height);
		applyAuthoredLabel();
	}

	override public function redraw():Void {
		super.redraw();
		applyAuthoredLabel();
	}

	private function applyAuthoredLabel():Void {
		if (labelField == null) return;
		var format = new TextFormat(NativeAssets.font(FontAsset.Interface), authoredSize, hovered || pressed ? 0 : 0x4E4EFE, false, null, null, null, null,
			TextFormatAlign.LEFT);
		labelField.defaultTextFormat = format;
		labelField.setTextFormat(format);
		labelField.x = 2;
		labelField.y = 2;
		labelField.width = Math.max(0, controlWidth - 2);
		labelField.height = authoredSize == 12 ? 14.55 : 12.15;
	}
}

private class OptionsLinkSkin implements ControlSkin {
	public function new() {}
	public function draw(graphics:Graphics, width:Float, height:Float, state:ControlState):Void graphics.clear();
}
