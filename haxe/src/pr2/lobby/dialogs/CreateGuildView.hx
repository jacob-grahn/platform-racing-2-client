package pr2.lobby.dialogs;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

/** Native create/edit guild form with emblem and ownership actions. */
class CreateGuildView extends NativeView {
	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-184, -135, 368, 270, 14, 14);
		graphics.endFill();
		label("-- Create Guild --", "titleBox", -135, -120, 270, 24, 16, true, TextFormatAlign.CENTER);
		label("Guild name:", null, -165, -84, 91, 18, 11, false, TextFormatAlign.RIGHT);
		input("nameBox", -68, -87, 220, 23, false);
		label("Guild note:", null, -165, -51, 91, 18, 11, false, TextFormatAlign.RIGHT);
		input("proseBox", -68, -54, 220, 60, true);
		button("changeEmblem_bt", "Change Emblem", -156, 24, 105);
		button("deleteEmblem_bt", "Reset Emblem", -45, 24, 95);
		var transferBg = new Sprite();
		transferBg.name = "transfer_bg";
		transferBg.graphics.beginFill(0xE6E6E6);
		transferBg.graphics.drawRoundRect(54, 19, 102, 34, 7, 7);
		transferBg.graphics.endFill();
		addChild(transferBg);
		button("transfer_bt", "Transfer", 63, 24, 84);
		button("confirm_bt", "Confirm", -101, 91, 86);
		button("cancel_bt", "Cancel", 15, 91, 86);
	}

	private function input(name:String, x:Float, y:Float, width:Float, height:Float, multiline:Bool):Void {
		var control = ownControl(new GameTextInput());
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, height);
		control.textField.multiline = multiline;
		control.textField.wordWrap = multiline;
		addChild(control);
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
		align:TextFormatAlign):Void {
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
	}
}
