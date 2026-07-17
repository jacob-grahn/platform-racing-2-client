package pr2.gameplay;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native prize announcement shell and explicit part preview states. */
class PrizePopupView extends NativeView {
	public function new() {
		super();
		var bg = new Sprite();
		bg.name = "bg";
		bg.graphics.beginFill(0xF4F4F4, 0.98);
		bg.graphics.lineStyle(2, 0x666666);
		bg.graphics.drawRoundRect(-190, -150, 380, 300, 14, 14);
		bg.graphics.endFill();
		addChild(bg);
		field("titleBox", -160, -134, 320, 25, 16, true, TextFormatAlign.CENTER);
		field("textBox", -160, -102, 320, 40, 11, false, TextFormatAlign.CENTER);
		part("hat", -75, -35);
		part("head", -75, -35);
		part("body", -75, -35);
		part("foot", -75, -35);
		var exp = new Sprite();
		exp.name = "exp";
		exp.x = -145;
		exp.y = -25;
		fieldOn(exp, "textBox", 0, 0, 290, 55, 12, true, TextFormatAlign.CENTER);
		addChild(exp);
		var flavorBg = new Sprite();
		flavorBg.name = "flavorBg";
		flavorBg.x = -160;
		flavorBg.y = 66;
		flavorBg.graphics.beginFill(0xE8EBEF);
		flavorBg.graphics.drawRoundRect(0, 0, 320, 38, 8, 8);
		flavorBg.graphics.endFill();
		addChild(flavorBg);
		field("flavor", -150, 73, 300, 28, 10, false, TextFormatAlign.CENTER);
		var close = ownControl(new GameButton("Close"));
		close.name = "close_bt";
		close.x = -42;
		close.y = 114;
		close.setSize(84, 24);
		addChild(close);
	}

	private function part(name:String, x:Float, y:Float):Void {
		var symbol = new PrizePartSymbol(name == "head");
		symbol.name = name;
		symbol.x = x;
		symbol.y = y;
		addChild(symbol);
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign):TextField {
		return fieldOn(this, name, x, y, width, height, size, bold, align);
	}

	private function fieldOn(parent:Sprite, name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign):TextField {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		parent.addChild(text);
		return text;
	}
}

class PrizePartSymbol extends Sprite {
	public var currentFrame(default, null):Int = 1;
	public final colorMC:PrizePartSymbolChannel;
	public final colorMC2:PrizePartSymbolChannel;

	public function new(withHats:Bool = false) {
		super();
		colorMC = new PrizePartSymbolChannel();
		colorMC.name = "colorMC";
		addChild(colorMC);
		colorMC2 = new PrizePartSymbolChannel();
		colorMC2.name = "colorMC2";
		addChild(colorMC2);
		if (withHats) {
			for (i in 1...5) {
				var hat = new Sprite();
				hat.name = "hat" + i;
				addChild(hat);
			}
		}
		gotoAndStop(1);
	}

	public function gotoAndStop(frame:Int):Void {
		currentFrame = frame;
		graphics.clear();
		graphics.beginFill(0xB7C4D5);
		graphics.lineStyle(2, 0x4F5966);
		graphics.drawRoundRect(0, 0, 150, 95, 22, 22);
		graphics.endFill();
		colorMC.gotoAndStop(frame);
		colorMC2.gotoAndStop(frame);
	}
}

class PrizePartSymbolChannel extends Sprite {
	public var currentFrame(default, null):Int = 1;
	public function new() {
		super();
		graphics.beginFill(0xFFFFFF, 0.5);
		graphics.drawCircle(75, 47, 24);
		graphics.endFill();
	}
	public function gotoAndStop(frame:Int):Void currentFrame = frame;
}
