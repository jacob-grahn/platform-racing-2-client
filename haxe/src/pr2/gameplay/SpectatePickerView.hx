package pr2.gameplay;

import openfl.display.Sprite;
import openfl.filters.DropShadowFilter;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.ui.controls.AuthoredArrowButton;
import pr2.ui.view.NativeView;

/** Native spectating selector with explicit controls and dual-layer name text. */
class SpectatePickerView extends NativeView {
	public final nameTop:TextField;
	public final nameBg:TextField;
	public final spectatingText:Sprite;

	public function new() {
		super();
		var left = ownControl(new AuthoredArrowButton(false, function():Void {}));
		left.name = "arrowLeft";
		left.x = 0;
		left.y = 0;
		left.filters = [new DropShadowFilter(3, 90, 0x000000, 1, 2, 2, 0.25, 1)];
		addChild(left);
		var right = ownControl(new AuthoredArrowButton(true, function():Void {}));
		right.name = "arrowRight";
		right.x = 138.8;
		right.y = 0;
		right.filters = [new DropShadowFilter(3, 90, 0x000000, 1, 2, 2, 0.25, 1)];
		addChild(right);
		nameBg = label("box", 7.45, 0.95, 113.8, 14.55, 12, 0xB3B3B3, false);
		addChild(nameBg);
		nameTop = label("box", 6.45, -0.05, 113.8, 14.55, 12, 0x333333, false);
		addChild(nameTop);
		spectatingText = new Sprite();
		spectatingText.name = "spectatingText";
		var spectatingBg = label("box", 26, -13.55, 100, 14.55, 12, 0xB3B3B3, false);
		spectatingBg.text = "-- Spectating --";
		spectatingText.addChild(spectatingBg);
		var spectatingTop = label("box", 25, -14.55, 100, 14.55, 12, 0x333333, false);
		spectatingTop.text = "-- Spectating --";
		spectatingText.addChild(spectatingTop);
		addChild(spectatingText);
		setChildIndex(left, numChildren - 1);
		setChildIndex(right, numChildren - 1);
	}

	private static function label(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, color:Int, bold:Bool):TextField {
		var field = new TextField();
		field.name = name;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat("Verdana", size, color, bold, null, null, null, null,
			TextFormatAlign.CENTER);
		return field;
	}
}
