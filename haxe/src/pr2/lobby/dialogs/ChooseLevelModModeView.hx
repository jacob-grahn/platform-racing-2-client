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
	public var onUnpublish:Null<Void->Void>;
	public var onRestrict:Null<Void->Void>;
	public var onCancel:Null<Void->Void>;

	public function new() {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -122.5;
		panel.y = -68.75;
		panel.scaleX = 0.900802612304688;
		panel.scaleY = 0.719802856445312;
		addChild(panel);
		addLabel("-- Moderate Level --", -68.3, -58.2, 137, 18, 14, true, TextFormatAlign.CENTER);
		addLabel("Do what to this level?", -90.3, -33.2, 181, 16, 11, false, TextFormatAlign.CENTER);
		addButton("Unpublish", "unpublish_bt", -97.8, -7.5, onUnpublishPress);
		addButton("Restrict", "restrict_bt", 11.95, -7.5, onRestrictPress);
		addButton("Cancel", "cancel_bt", -40, 27, onCancelPress, 80);
	}

	private function addButton(label:String, name:String, x:Float, y:Float, press:Void->Void, width:Float = 85):Void {
		var button = ownControl(new GameButton(label));
		button.name = name;
		button.x = x;
		button.y = y;
		button.setSize(width, 22);
		button.onPress = press;
		addChild(button);
	}

	private function onUnpublishPress():Void if (onUnpublish != null) onUnpublish();
	private function onRestrictPress():Void if (onRestrict != null) onRestrict();
	private function onCancelPress():Void if (onCancel != null) onCancel();

	private function addLabel(value:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign):Void {
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0, bold, null, null, null, null, align);
		field.text = value;
		addChild(field);
	}

	override public function dispose():Void {
		onUnpublish = null;
		onRestrict = null;
		onCancel = null;
		super.dispose();
	}
}
