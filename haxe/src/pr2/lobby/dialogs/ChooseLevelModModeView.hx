package pr2.lobby.dialogs;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native composition of ChooseLevelModModePopupGraphic. */
class ChooseLevelModModeView extends NativeView {
	public final panel:openfl.display.Shape;
	public final title:TextField;
	public final prompt:TextField;
	public final unpublishButton:GameButton;
	public final restrictButton:GameButton;
	public final cancelButton:GameButton;
	public var onUnpublish:Null<Void->Void>;
	public var onRestrict:Null<Void->Void>;
	public var onCancel:Null<Void->Void>;

	public function new() {
		super();
		panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -122.5;
		panel.y = -68.75;
		panel.scaleX = 0.900802612304688;
		panel.scaleY = 0.719802856445312;
		addChild(panel);
		title = addLabel("-- Moderate Level --", -107.95, -58.2, 216.95, 17.05, 14, true, TextFormatAlign.CENTER);
		prompt = addLabel("Do what to this level?", -107.95, -33.2, 216.95, 14.55, 12, false, TextFormatAlign.CENTER);
		unpublishButton = addButton("Unpublish", "unpublish_bt", -97.8, -7.5, onUnpublishPress, 84.9899291992188, 23.5989074707032);
		restrictButton = addButton("Restrict", "restrict_bt", 11.95, -7.5, onRestrictPress, 84.9899291992188, 23.5989074707032);
		cancelButton = addButton("Cancel", "cancel_bt", -40, 27, onCancelPress, 79.9972534179688, 23.699951171875);
	}

	private function addButton(label:String, name:String, x:Float, y:Float, press:Void->Void, width:Float, height:Float):GameButton {
		var button = ownControl(new GameButton(label));
		button.name = name;
		button.x = x;
		button.y = y;
		button.setSize(width, height);
		button.onPress = press;
		addChild(button);
		return button;
	}

	private function onUnpublishPress():Void if (onUnpublish != null) onUnpublish();
	private function onRestrictPress():Void if (onRestrict != null) onRestrict();
	private function onCancelPress():Void if (onCancel != null) onCancel();

	private function addLabel(value:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign):TextField {
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0, bold, null, null, null, null, align);
		field.text = value;
		addChild(field);
		return field;
	}

	override public function dispose():Void {
		onUnpublish = null;
		onRestrict = null;
		onCancel = null;
		super.dispose();
	}
}
