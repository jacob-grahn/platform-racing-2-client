package pr2.lobby.dialogs;

import openfl.text.TextField;
import openfl.display.DisplayObject;
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
	public final panel:DisplayObject;
	public final title:TextField;
	public final prompt:TextField;
	public final reasonLabel:TextField;
	public final reportButton:GameButton;
	public final cancelButton:GameButton;
	public var onReport:Null<Void->Void>;
	public var onCancel:Null<Void->Void>;

	public function new() {
		super();
		panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -122.45;
		panel.y = -79.15;
		panel.scaleX = 0.900650024414062;
		panel.scaleY = 0.837631225585938;
		addChild(panel);
		title = addLabel("-- Report Level --", -108, -68, 216, 17.05, 14, true, TextFormatAlign.CENTER, false);
		prompt = addLabel("Please let the moderators know what's wrong with this level.", -107.95, -43, 216.95, 29.1, 12, false,
			TextFormatAlign.CENTER, true);
		reasonLabel = addLabel("Reason: ", -106.63, 2, 52.8, 14.55, 12, false, TextFormatAlign.RIGHT, false);
		reasonLabel.scaleX = 1.00152587890625;
		reasonLabel.scaleY = 1.00286865234375;
		reasonInput = ownControl(new GameTextInput());
		reasonInput.x = -43.5;
		reasonInput.y = 0;
		reasonInput.setSize(130, 22);
		reasonInput.textField.name = "reasonBox";
		addChild(reasonInput);
		reportButton = ownControl(new GameButton("Report"));
		reportButton.name = "report_bt";
		reportButton.x = -80;
		reportButton.y = 40;
		reportButton.setSize(74.0005493164062, 22);
		reportButton.onPress = function():Void if (onReport != null) onReport();
		addChild(reportButton);
		cancelButton = ownControl(new GameButton("Cancel"));
		cancelButton.name = "cancel_bt";
		cancelButton.x = 7;
		cancelButton.y = 40;
		cancelButton.setSize(74.0005493164062, 22);
		cancelButton.onPress = function():Void if (onCancel != null) onCancel();
		addChild(cancelButton);
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

	override public function dispose():Void {
		onReport = null;
		onCancel = null;
		super.dispose();
	}
}
