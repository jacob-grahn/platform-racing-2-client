package pr2.levelEditor;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.runtime.SvgAsset;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameSelect;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

/** Exact native composition of XFL `HandleLevelReportPopupGraphic`. */
class HandleLevelReportView extends NativeView {
	public function new() {
		super();
		var background = SvgAsset.createNormalized("assets/svg/ui/shadow_bg.svg");
		background.name = "background";
		background.x = -150;
		background.y = -135;
		background.scaleX = 1.10301208496094;
		background.scaleY = 1.41368103027344;
		addChild(background);

		field("heading", -68.35, -118, 216, 17.05, 14, true, TextFormatAlign.CENTER).text = "-- Handle Report --";
		var title = field("titleBox", -153.05, -88, 286, 12.15, 10, false, TextFormatAlign.CENTER);
		title.multiline = true;
		title.text = "Newbieland 2 by Jiggmin";
		field("detailsLabel", -92.05, -76.15, 146, 12.15, 10, false, TextFormatAlign.CENTER, true).text = "Report details:";
		var info = new EditorNativeGraphic("ReportInfoButton");
		info.name = "info_bt";
		info.x = 32.95;
		info.y = -75.3;
		info.scaleX = info.scaleY = 0.999984741210938;
		addChild(info);

		field("banLabel", -136.85, -54, 176, 12.15, 10, true, TextFormatAlign.CENTER).text = "Unpublish Level and Ban User";
		field("reasonHelp", -44.5, -33.85, 276, 12.15, 10, false, TextFormatAlign.CENTER, true).text =
			"All reasons start with \"Inappropriate Level -- \"";
		var reason = ownControl(new GameSelect<String>());
		reason.name = "reason";
		reason.x = -87.5;
		reason.y = -20;
		reason.setSize(175, 22);
		reason.rowCount = 5;
		for (option in ["Reason...", "Vulgar Language", "Harassment", "Sensitive Imagery", "Scamming", "Copying (w/o attrib)",
			"Republished Removed Level", "Other..."]) reason.addOption(option, option == "Reason..." || option == "Other..." ? "" : option);
		addChild(reason);
		var other = ownControl(new GameTextInput());
		other.name = "otherReasonBox";
		other.x = -94;
		other.y = -20;
		other.setSize(145, 22);
		addChild(other);
		var otherCancel = new EditorNativeGraphic("CancelTextButton");
		otherCancel.name = "other_cancel_bt";
		otherCancel.x = 58.5;
		otherCancel.y = -16.5;
		addChild(otherCancel);

		var duration = ownControl(new GameSelect<String>());
		duration.name = "duration";
		duration.x = -102.5;
		duration.y = 13.8;
		duration.setSize(90, 22);
		duration.rowCount = 5;
		var durationOptions = [
			["Duration...", "0"], ["One Hour", "3600"], ["One Day", "86400"], ["Three Days", "259200"], ["One Week", "604800"],
			["Two Weeks", "1209600"], ["One Month", "2592000"], ["Six Months", "15768000"], ["One Year", "31536000"]
		];
		for (option in durationOptions) duration.addOption(option[0], option[1]);
		addChild(duration);
		button("ban_bt", "Ban", 10, 13.8, 90, 23);

		graphics.lineStyle(1, 0x999999);
		graphics.moveTo(-125, 55);
		graphics.lineTo(125, 55);
		field("orLabel", -75.05, 67.5, 21, 12.15, 10, true, TextFormatAlign.CENTER).text = "OR";
		button("archive_bt", "Archive", -100, 90, 90, 23);
		button("cancel_bt", "Cancel", 10, 90, 90, 23);
	}

	private function button(name:String, label:String, x:Float, y:Float, width:Float, height:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, height);
		addChild(control);
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign,
		italic:Bool = false):TextField {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, italic, null, null, null, align);
		addChild(text);
		return text;
	}
}
