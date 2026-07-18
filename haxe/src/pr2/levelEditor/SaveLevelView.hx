package pr2.levelEditor;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.runtime.SvgAsset;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameCheckBox;
import pr2.ui.controls.GameTextArea;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

/** Exact native composition of XFL `SaveLevelPopupGraphic`. */
class SaveLevelView extends NativeView {
	public function new() {
		super();
		var background = SvgAsset.createNormalized("assets/svg/ui/shadow_bg.svg");
		background.name = "background";
		background.x = -136;
		background.y = -120.4;
		background.scaleY = 1.33515930175781;
		addChild(background);

		field("heading", -53, -109.15, 106, 14.55, 12, true, TextFormatAlign.CENTER).text = "-- Save Level --";
		var titleLabel = field("titleLabel", -134, -80, 52, 14.55, 12, false, TextFormatAlign.CENTER, 0x333333);
		titleLabel.scaleY = 1.00286865234375;
		titleLabel.text = "Title";
		var title = ownControl(new GameTextInput());
		title.name = "titleBox";
		title.x = -79;
		title.y = -78;
		title.scaleX = 2.03001403808594;
		title.maxChars = 50;
		addChild(title);
		field("titleCharsRemaining", -134, -68, 52, 12.75, 8, false, TextFormatAlign.CENTER, 0xAAAAAA).text = "50 / 50";

		var noteLabel = field("noteLabel", -134, -41, 52, 14.55, 12, false, TextFormatAlign.CENTER, 0x333333);
		noteLabel.scaleY = 1.00286865234375;
		noteLabel.text = "Note";
		var note = ownControl(new GameTextArea(100, 44));
		note.name = "noteBox";
		note.x = -79;
		note.y = -41;
		note.scaleX = 2.030029296875;
		note.scaleY = 1.3865966796875;
		note.maxChars = 255;
		note.wordWrap = true;
		addChild(note);
		field("noteCharsRemaining", -134, -29, 52, 12.75, 8, false, TextFormatAlign.CENTER, 0xAAAAAA).text = "255 / 255";

		var publishLabel = field("publishLabel", -102.45, 28, 48.8, 14.55, 12, false, TextFormatAlign.LEFT, 0x333333);
		publishLabel.scaleY = 1.00286865234375;
		publishLabel.text = "Publish?";
		var newestLabel = field("newestLabel", 39.9, 28, 67.65, 14.55, 12, false, TextFormatAlign.LEFT, 0x333333);
		newestLabel.scaleY = 1.00286865234375;
		newestLabel.text = "To Newest?";
		check("publish_chk", -107.45, 25, 0.850082397460938, true);
		check("newest_chk", 8, 25, 1.05000305175781, false);
		var warning = field("warning", -105.45, 54, 213, 26.3, 10, false, TextFormatAlign.CENTER, 0x222222, true);
		warning.multiline = true;
		warning.wordWrap = true;
		warning.text = "If you publish a level, it must not contain\nprofanity or obscene content.";
		button("save_bt", "Save", -114, 94);
		button("cancel_bt", "Cancel", 13, 94);
	}

	private function check(name:String, x:Float, y:Float, scaleX:Float, enabled:Bool):Void {
		var control = ownControl(new GameCheckBox(""));
		control.name = name;
		control.x = x;
		control.y = y;
		control.scaleX = scaleX;
		control.enabled = enabled;
		addChild(control);
	}

	private function button(name:String, label:String, x:Float, y:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(100, 22);
		addChild(control);
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign,
		color:Int = 0x222222, italic:Bool = false):TextField {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, bold, italic, null, null, null, align);
		addChild(text);
		return text;
	}
}
