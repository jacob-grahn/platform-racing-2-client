package pr2.lobby.level;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.view.NativeView;

/** Native join slot with explicit hover/pending/filled/confirmed rendering. */
class SlotView extends NativeView {
	public final background:SlotBackground;
	public final rankBox:TextField;
	public final nameBox:TextField;

	public function new() {
		super();
		background = new SlotBackground();
		background.name = "bg";
		addChild(background);
		rankBox = field("rankBox", 5, 5, 28, TextFormatAlign.CENTER);
		nameBox = field("nameBox", 37, 5, 111, TextFormatAlign.LEFT);
	}

	private function field(name:String, x:Float, y:Float, width:Float, align:TextFormatAlign):TextField {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = 20;
		text.selectable = false;
		text.mouseEnabled = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0x222222, false, null, null, null, null, align);
		addChild(text);
		return text;
	}
}

class SlotBackground extends Sprite {
	public function new() {
		super();
		render("emptyUp");
	}

	public function render(state:String):Void {
		var over = StringTools.endsWith(state, "Over");
		var color = if (state == "pending") 0xE7C95B else if (StringTools.startsWith(state, "confirmed")) 0x82C98B else if (StringTools.startsWith(state,
			"filled")) 0xBBD9F2 else 0xE8E8E8;
		graphics.clear();
		graphics.beginFill(over ? brighten(color) : color, 0.96);
		graphics.lineStyle(1, 0x666666);
		graphics.drawRoundRect(0, 0, 154, 29, 7, 7);
		graphics.endFill();
	}

	private static function brighten(color:Int):Int {
		var r = Std.int(Math.min(255, ((color >> 16) & 0xFF) + 20));
		var g = Std.int(Math.min(255, ((color >> 8) & 0xFF) + 20));
		var b = Std.int(Math.min(255, (color & 0xFF) + 20));
		return (r << 16) | (g << 8) | b;
	}
}
