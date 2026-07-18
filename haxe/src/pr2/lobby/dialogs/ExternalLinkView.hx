package pr2.lobby.dialogs;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.display.Shape;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.controls.GameTextArea;
import pr2.ui.view.NativeView;

/** Native composition of ExternalLinkPopupGraphic. */
class ExternalLinkView extends NativeView {
	public var onProceed:Null<Void->Void>;
	public var onClose:Null<Void->Void>;
	public final topPanel:Shape;
	public final bodyPanel:Shape;
	public final linkArea:GameTextArea;
	public final proceedButton:GameButton;
	public final closeButton:GameButton;

	public function new(url:String) {
		super();
		bodyPanel = NativeAssets.svg(StaticSvg.QuantityPanel);
		bodyPanel.x = -150;
		bodyPanel.y = -45;
		bodyPanel.scaleX = 1.10302734375;
		bodyPanel.scaleY = 1.04719543457031;
		addChild(bodyPanel);
		topPanel = NativeAssets.svg(StaticSvg.QuantityPanel);
		topPanel.x = -150;
		topPanel.y = -155;
		topPanel.scaleX = 1.10302734375;
		topPanel.scaleY = 0.523590087890625;
		addChild(topPanel);
		addLabel("-- External Website --", -94, -31, 188.1, 17.05, 14, true, TextFormatAlign.CENTER);
		addLabel("You just clicked a link that is taking you to the website in the box above.", -134.95, -3, 266, 29.1, 12, false,
			TextFormatAlign.CENTER);
		addLabel("The world is a scary place, and that link\nmay harm your computer. If you trust the\nsender and recognize the link, proceed at\nyour own risk. If not, report the PM.", -129.95, 38.1, 256, 58.2, 12, false, TextFormatAlign.CENTER);
		linkArea = ownControl(new GameTextArea(285.000610351562, 43));
		linkArea.x = -142.5;
		linkArea.y = -147.5;
		linkArea.editable = false;
		linkArea.textField.name = "linkBox";
		linkArea.text = url;
		addChild(linkArea);
		proceedButton = ownControl(new GameButton("Proceed"));
		proceedButton.name = "proceed_bt";
		proceedButton.x = -105;
		proceedButton.y = 114;
		proceedButton.onPress = function():Void if (onProceed != null) onProceed();
		addChild(proceedButton);
		closeButton = ownControl(new GameButton("Go Back"));
		closeButton.name = "close_bt";
		closeButton.x = 5;
		closeButton.y = 114;
		closeButton.onPress = function():Void if (onClose != null) onClose();
		addChild(closeButton);
	}

	private function addLabel(value:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign,
		color:Int = 0):Void {
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.multiline = true;
		field.wordWrap = true;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, bold, null, null, null, null, align);
		field.text = value;
		addChild(field);
	}

	override public function dispose():Void {
		onProceed = null;
		onClose = null;
		super.dispose();
	}
}
