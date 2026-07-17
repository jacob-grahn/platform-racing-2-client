package pr2.levelEditor;

import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameCheckBox;
import pr2.ui.view.NativeView;

/** Native save-level form with title/note limits and publication options. */
class SaveLevelView extends NativeView {
	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-190, -145, 380, 290, 14, 14);
		graphics.endFill();
		field(null, -160, -132, 320, 24, 16, true, TextFormatAlign.CENTER).text = "-- Save Level --";
		field(null, -160, -96, 70, 18, 11, true, TextFormatAlign.RIGHT).text = "Title";
		var title = field("titleBox", -82, -99, 240, 24, 11, false, TextFormatAlign.LEFT);
		input(title, 50);
		field("titleCharsRemaining", 88, -75, 70, 16, 9, false, TextFormatAlign.RIGHT);
		field(null, -160, -49, 70, 18, 11, true, TextFormatAlign.RIGHT).text = "Note";
		var note = field("noteBox", -82, -52, 240, 71, 11, false, TextFormatAlign.LEFT);
		input(note, 255);
		note.multiline = true;
		note.wordWrap = true;
		field("noteCharsRemaining", 88, 20, 70, 16, 9, false, TextFormatAlign.RIGHT);
		check("publish_chk", "Publish level", -82, 47);
		check("newest_chk", "List in newest", 45, 47);
		button("save_bt", "Save", -90, 102);
		button("cancel_bt", "Cancel", 10, 102);
	}

	private function input(field:TextField, maxChars:Int):Void {
		field.type = TextFieldType.INPUT;
		field.selectable = true;
		field.maxChars = maxChars;
		field.background = true;
		field.backgroundColor = 0xFFFFFF;
		field.border = true;
		field.borderColor = 0x777777;
	}

	private function check(name:String, label:String, x:Float, y:Float):Void {
		var control = ownControl(new GameCheckBox(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(120, 22);
		addChild(control);
	}

	private function button(name:String, label:String, x:Float, y:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(80, 24);
		addChild(control);
	}

	private function field(name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign):TextField {
		var text = new TextField();
		if (name != null) text.name = name;
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
