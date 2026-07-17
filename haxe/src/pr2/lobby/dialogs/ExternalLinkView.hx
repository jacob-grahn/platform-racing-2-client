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

/** Native composition of ExternalLinkPopupGraphic. */
class ExternalLinkView extends NativeView {
	public var onProceed:Null<Void->Void>;
	public var onClose:Null<Void->Void>;

	public function new(url:String) {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -150;
		panel.y = -155;
		panel.scaleX = 1.10302734375;
		panel.scaleY = 1.04719543457031;
		addChild(panel);
		addLabel("-- External Website --", -94, -31, 188, 18, 14, true, TextFormatAlign.CENTER);
		addLabel("You just clicked a link that is taking you to the website in the box above.", -84, -3, 168, 34, 10, false,
			TextFormatAlign.CENTER);
		addLabel("The world is a scary place, and that link\nmay harm your computer. If you trust the\nsender and recognize the link, proceed at\nyour own risk. If not, report the PM.", -85, 38, 172, 58, 10, false, TextFormatAlign.CENTER, 0x555555);
		var link = ownControl(new GameTextInput(url));
		link.x = -142.5;
		link.y = -147.5;
		link.setSize(285, 43);
		link.editable = false;
		link.textField.name = "linkBox";
		link.textField.multiline = true;
		link.textField.wordWrap = true;
		addChild(link);
		var proceed = ownControl(new GameButton("Proceed"));
		proceed.name = "proceed_bt";
		proceed.x = -105;
		proceed.y = 114;
		proceed.setSize(100, 22);
		proceed.onPress = function():Void if (onProceed != null) onProceed();
		addChild(proceed);
		var close = ownControl(new GameButton("Close"));
		close.name = "close_bt";
		close.x = 5;
		close.y = 114;
		close.setSize(100, 22);
		close.onPress = function():Void if (onClose != null) onClose();
		addChild(close);
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
