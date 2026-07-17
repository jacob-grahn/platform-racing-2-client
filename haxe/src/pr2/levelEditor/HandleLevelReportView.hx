package pr2.levelEditor;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameSelect;
import pr2.ui.view.NativeView;

/** Native reported-level moderation form. */
class HandleLevelReportView extends NativeView {
	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-205, -140, 410, 280, 14, 14);
		graphics.endFill();
		field("titleBox", -175, -125, 350, 42, 12, true, TextFormatAlign.CENTER);
		field(null, -165, -70, 74, 18, 10, true, TextFormatAlign.RIGHT).text = "Ban length";
		var duration = ownControl(new GameSelect<String>());
		duration.name = "duration";
		duration.x = -82;
		duration.y = -74;
		duration.setSize(145, 23);
		duration.addOption("Choose...", "0");
		duration.addOption("1 hour", "3600");
		duration.addOption("1 day", "86400");
		duration.addOption("1 week", "604800");
		addChild(duration);
		field(null, -165, -35, 74, 18, 10, true, TextFormatAlign.RIGHT).text = "Reason";
		var reason = ownControl(new GameSelect<String>());
		reason.name = "reason";
		reason.x = -82;
		reason.y = -39;
		reason.setSize(230, 23);
		reason.addOption("Choose...", "");
		reason.addOption("Vulgar Language", "Vulgar Language");
		reason.addOption("Inappropriate Content", "Inappropriate Content");
		reason.addOption("Other...", "");
		addChild(reason);
		var other = field("otherReasonBox", -82, -39, 230, 25, 10, false, TextFormatAlign.LEFT);
		other.type = TextFieldType.INPUT;
		other.selectable = true;
		other.background = true;
		other.backgroundColor = 0xFFFFFF;
		other.border = true;
		button("other_cancel_bt", "Back", 153, -39, 43);
		button("info_bt", "Info", -175, 13, 58);
		button("ban_bt", "Ban + Unpublish", -106, 75, 112);
		button("archive_bt", "Archive", 13, 75, 78);
		button("cancel_bt", "Cancel", 98, 75, 78);
	}

	private function button(name:String, label:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 24);
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
