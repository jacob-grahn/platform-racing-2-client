package pr2.lobby.dialogs;

import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Exact native composition of the authored rich-formatting reference sheet. */
class PMRFCodesView extends NativeView {
	public final panel:Shape;
	public final title:TextField;
	public final sizingSyntax:TextField;
	public final stylingSyntax:TextField;
	public final linkSyntax:TextField;
	public final linksBox:TextField;
	public final closeButton:GameButton;
	public var onClose:Null<Void->Void>;

	public function new() {
		super();
		panel = NativeAssets.svg(StaticSvg.QuantityPanel);
		panel.x = -150;
		panel.y = -150;
		panel.scaleX = 1.10292053222656;
		panel.scaleY = 1.57060241699219;
		addChild(panel);

		var rules = new Shape();
		rules.graphics.lineStyle(1, 0x999999);
		drawLine(rules, 0, -102.25, 0, -38.25);
		drawLine(rules, 0, -14.3, 0, 32.7);
		drawLine(rules, 0, 53.8, 0, 112.8);
		rules.graphics.lineStyle(1, 0x000000);
		drawLine(rules, 37.55, 19.8, 114.55, 19.8);
		addChild(rules);

		title = addText("-- Rich Formatting --", -104.5, -137.55, 208.9, 14.55, 12, true, TextFormatAlign.CENTER);
		addText("Text Sizing", -38, -119, 76, 12.15, 10, true, TextFormatAlign.CENTER);
		addText("Text Styling", -38, -30.05, 76, 12.15, 10, true, TextFormatAlign.CENTER);
		addText("Links", -40, 38.25, 80, 12.15, 10, true, TextFormatAlign.CENTER);

		sizingSyntax = addText("[tiny]text[/tiny]\n[small]text[/small]", -138, -105.25, 128, 24.3, 10, false, TextFormatAlign.CENTER);
		var mediumSyntax = addText("[medium]text[/medium]", -138, -76.95, 128, 12.15, 10, false, TextFormatAlign.CENTER);
		var largeSyntax = addText("[big]text[/big]\n[large]text[/large]", -138, -60.25, 127.95, 24.3, 10, false, TextFormatAlign.CENTER);
		italicizeWords(sizingSyntax, "text");
		italicizeWords(mediumSyntax, "text");
		italicizeWords(largeSyntax, "text");

		var sizeExamples = addText("tiny text!\nsmall text!", 12, -102.25, 128, 18.25, 6, false, TextFormatAlign.CENTER);
		applyFormat(sizeExamples, sizeExamples.text.indexOf("small"), sizeExamples.text.length, 9);
		addText("medium text!", 12, -79.35, 128, 14.55, 12, false, TextFormatAlign.CENTER);
		addText("BIG!!", 12, -63.25, 128, 29.2, 24, false, TextFormatAlign.CENTER);

		stylingSyntax = addText("[b]text[/b]\n[i]text[/i]\n[u]text[/u]\n[color=#hex]text[/color]", -138, -15.75, 128, 48.6, 10, false,
			TextFormatAlign.CENTER);
		italicizeWords(stylingSyntax, "text");
		var styleExamples = addText("bold text!\nitalic text!\nunderlined text!\ncolored text!", 12, -15.75, 128, 48.6, 10, false,
			TextFormatAlign.CENTER);
		var firstBreak = styleExamples.text.indexOf("\n");
		var secondBreak = styleExamples.text.indexOf("\n", firstBreak + 1);
		var thirdBreak = styleExamples.text.indexOf("\n", secondBreak + 1);
		applyFormat(styleExamples, 0, firstBreak, 10, true);
		applyFormat(styleExamples, firstBreak + 1, secondBreak, 10, false, true);
		applyFormat(styleExamples, secondBreak + 1, thirdBreak, 10, false, false, true);
		applyFormat(styleExamples, thirdBreak + 1, styleExamples.text.length, 10, false, false, false, 0xFF0000);

		linkSyntax = addText("[url]link[/url]\n[url=link]text[/url]\n[user]username[/user]\n[level=id]text[/level]\n[guild]guild name[/guild]", -138,
			52.25, 128, 60.75, 10, false, TextFormatAlign.CENTER);
		for (word in ["link", "text", "username", "id", "guild name"]) italicizeWords(linkSyntax, word);
		linksBox = addText("", 12, 52.25, 128, 60.75, 10, false, TextFormatAlign.CENTER);
		linksBox.name = "linksBox";
		linksBox.selectable = false;

		closeButton = ownControl(new GameButton("Close"));
		closeButton.name = "close_bt";
		closeButton.x = -45.4;
		closeButton.y = 120.65;
		closeButton.setSize(90.899658203125, 20.0006103515625);
		closeButton.onPress = function():Void if (onClose != null) onClose();
		addChild(closeButton);
	}

	private static function drawLine(shape:Shape, x1:Float, y1:Float, x2:Float, y2:Float):Void {
		shape.graphics.moveTo(x1, y1);
		shape.graphics.lineTo(x2, y2);
	}

	private function addText(value:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign):TextField {
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.multiline = value.indexOf("\n") >= 0 || height > 18;
		field.wordWrap = false;
		field.selectable = false;
		field.mouseEnabled = false;
		field.defaultTextFormat = format(size, bold, false, false, 0x000000, align);
		field.text = value;
		addChild(field);
		return field;
	}

	private function italicizeWords(field:TextField, word:String):Void {
		var start = field.text.indexOf(word);
		while (start >= 0) {
			applyFormat(field, start, start + word.length, 10, false, true);
			start = field.text.indexOf(word, start + word.length);
		}
	}

	private function applyFormat(field:TextField, begin:Int, end:Int, size:Int, bold:Bool = false, italic:Bool = false,
		underline:Bool = false, color:Int = 0x000000):Void {
		field.setTextFormat(format(size, bold, italic, underline, color, TextFormatAlign.CENTER), begin, end);
	}

	private function format(size:Int, bold:Bool, italic:Bool, underline:Bool, color:Int, align:TextFormatAlign):TextFormat {
		return new TextFormat(NativeAssets.font(FontAsset.Interface), size, color, bold, italic, underline, null, null, align, null, null, null, 0);
	}

	override public function dispose():Void {
		onClose = null;
		super.dispose();
	}
}
