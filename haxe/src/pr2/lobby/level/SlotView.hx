package pr2.lobby.level;

import openfl.display.Sprite;
import openfl.display.DisplayObject;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.runtime.SvgAsset;
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
		background.y = 1;
		addChild(background);
		rankBox = field("rankBox", 3, 2, 14);
		nameBox = field("nameBox", 21, 2, 76);
	}

	private function field(name:String, x:Float, y:Float, width:Float):TextField {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = 12.15;
		text.scaleY = 1.00311279296875;
		text.multiline = true;
		text.selectable = false;
		text.mouseEnabled = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0, false, null, null, null, null, TextFormatAlign.LEFT);
		addChild(text);
		return text;
	}
}

class SlotBackground extends Sprite {
	public var currentState(default, null):String;
	private var art:Null<DisplayObject>;

	public function new() {
		super();
		render("emptyUp");
	}

	public function render(state:String):Void {
		if (art != null && art.parent == this) removeChild(art);
		currentState = state;
		var file = switch (state) {
			case "emptyOver": "slot_empty_over.svg";
			case "filledUp": "slot_filled_up.svg";
			case "filledOver": "slot_filled_over.svg";
			case "confirmedUp": "slot_confirmed_up.svg";
			case "confirmedOver": "slot_confirmed_over.svg";
			case "pending": "slot_pending.svg";
			default: "slot_empty_up.svg";
		};
		art = SvgAsset.create("assets/svg/ui/" + file);
		addChild(art);
	}
}
