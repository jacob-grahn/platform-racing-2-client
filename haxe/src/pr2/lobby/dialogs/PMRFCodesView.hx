package pr2.lobby.dialogs;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native rich-formatting reference panel. */
class PMRFCodesView extends NativeView {
	public final linksBox:TextField;
	public var onClose:Null<Void->Void>;

	public function new() {
		super();
		var panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -155;
		panel.y = -150;
		panel.scaleX = 1.14;
		panel.scaleY = 1.45;
		addChild(panel);
		addLabel("-- Rich Formatting Codes --", -125, -136, 250, 18, 14, true, TextFormatAlign.CENTER);
		addLabel("PMs support clickable URLs, player names, levels, and guilds. Here are live examples:", -130, -101, 260, 35, 11, false,
			TextFormatAlign.LEFT);
		linksBox = addLabel("", -130, -57, 260, 125, 12, false, TextFormatAlign.LEFT);
		linksBox.name = "linksBox";
		linksBox.multiline = true;
		linksBox.wordWrap = true;
		var close = ownControl(new GameButton("Close"));
		close.name = "close_bt";
		close.x = -45;
		close.y = 91;
		close.setSize(90, 22);
		close.onPress = function():Void if (onClose != null) onClose();
		addChild(close);
	}

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
		onClose = null;
		super.dispose();
	}
}
