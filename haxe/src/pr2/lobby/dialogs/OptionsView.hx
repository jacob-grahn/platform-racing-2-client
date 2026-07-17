package pr2.lobby.dialogs;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameSlider;
import pr2.ui.view.NativeView;

/** Native options panel covering audio, filtering, art, controls, and account actions. */
class OptionsView extends NativeView {
	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-210, -165, 420, 330, 14, 14);
		graphics.endFill();
		label("-- Options --", null, -130, -151, 260, 24, 17, true, TextFormatAlign.CENTER);
		label("Music", null, -190, -116, 58, 18, 11, true, TextFormatAlign.RIGHT);
		slider("musicSlider", -125, -119);
		label("", "musicPercentBox", 40, -116, 45, 18, 10, false, TextFormatAlign.RIGHT);
		button("music_bt", "Songs", 95, -120, 78);
		label("Sound", null, -190, -84, 58, 18, 11, true, TextFormatAlign.RIGHT);
		slider("soundSlider", -125, -87);
		label("", "soundPercentBox", 40, -84, 45, 18, 10, false, TextFormatAlign.RIGHT);
		choiceRow("Filter chat", "filterOn_bt", "filterOff_bt", "filterHighlight", -52);
		choiceRow("Draw art", "artOn_bt", "artOff_bt", "artHighlight", -20);
		button("art_bt", "Quality", 95, -24, 78);
		label("Art disabled", "artOffText", 91, -20, 88, 18, 10, false, TextFormatAlign.CENTER);
		label("Alternate controls", null, -184, 18, 150, 18, 11, true, TextFormatAlign.LEFT);
		var controls = [
			{name: "wasdUp", label: "Up", x: -170.0},
			{name: "wasdRight", label: "Right", x: -99.0},
			{name: "wasdDown", label: "Down", x: -28.0},
			{name: "wasdLeft", label: "Left", x: 43.0},
			{name: "wasdItem", label: "Item", x: 114.0}
		];
		for (spec in controls) {
			label(spec.label, null, spec.x, 40, 52, 15, 9, false, TextFormatAlign.CENTER);
			var input = label("", spec.name, spec.x + 12, 56, 28, 23, 12, true, TextFormatAlign.CENTER);
			input.type = TextFieldType.INPUT;
			input.background = true;
			input.backgroundColor = 0xFFFFFF;
			input.border = true;
			input.borderColor = 0x777777;
			input.selectable = true;
		}
		for (spec in [
			{name: "changePass_bt", label: "Password"}, {name: "changeEmail_bt", label: "Email"}, {name: "guildLeave_bt", label: "Leave Guild"},
			{name: "guildCreate_bt", label: "Create Guild"}, {name: "guildEdit_bt", label: "Edit Guild"}, {name: "guildTransfer_bt", label: "Transfer Guild"}
		]) button(spec.name, spec.label, 80, 20, 94);
		button("close_bt", "Close", -44, 126, 88);
	}

	private function slider(name:String, x:Float, y:Float):Void {
		var control = ownControl(new GameSlider(0, 100, 100, 1));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(160, 22);
		addChild(control);
	}

	private function choiceRow(title:String, yes:String, no:String, highlightName:String, y:Float):Void {
		label(title, null, -187, y + 4, 82, 18, 11, true, TextFormatAlign.RIGHT);
		button(yes, "On", -96, y, 48);
		button(no, "Off", -43, y, 48);
		var highlight = new Sprite();
		highlight.name = highlightName;
		highlight.graphics.lineStyle(2, 0xE0B62E);
		highlight.graphics.drawRoundRect(-98, 0, 103, 25, 6, 6);
		highlight.y = -71.5;
		addChild(highlight);
	}

	private function button(name:String, value:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(value));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 24);
		addChild(control);
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
