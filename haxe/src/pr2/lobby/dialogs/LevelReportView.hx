package pr2.lobby.dialogs;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameTextInput;
import pr2.ui.view.NativeView;

/** Native composition of LevelReportPopupGraphic. */
class LevelReportView extends NativeView {
	public final reasonInput:GameTextInput;
	public var onReport:Null<Void->Void>;
	public var onCancel:Null<Void->Void>;

	public function new() {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -122.45;
		panel.y = -79.15;
		panel.scaleX = 0.900650024414062;
		panel.scaleY = 0.837631225585938;
		addChild(panel);
		addLabel("-- Report Level --", -68.35, -68, 137, 18, 14, true, TextFormatAlign.CENTER);
		addLabel("Please let the moderators know what's wrong with this level.", -90.3, -43, 181, 31, 10, false,
			TextFormatAlign.CENTER);
		addLabel("Reason:", -86.3, 2, 43, 16, 11, false, TextFormatAlign.RIGHT);
		reasonInput = ownControl(new GameTextInput());
		reasonInput.x = -43.5;
		reasonInput.y = 0;
		reasonInput.setSize(130, 22);
		reasonInput.textField.name = "reasonBox";
		addChild(reasonInput);
		var report = ownControl(new GameButton("Report"));
		report.name = "report_bt";
		report.x = -80;
		report.y = 40;
		report.setSize(74, 22);
		report.onPress = function():Void if (onReport != null) onReport();
		addChild(report);
		var cancel = ownControl(new GameButton("Cancel"));
		cancel.name = "cancel_bt";
		cancel.x = 7;
		cancel.y = 40;
		cancel.setSize(74, 22);
		cancel.onPress = function():Void if (onCancel != null) onCancel();
		addChild(cancel);
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

	override public function dispose():Void {
		onReport = null;
		onCancel = null;
		super.dispose();
	}
}
