package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.text.AntiAliasType;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;
import pr2.runtime.FontResolver;

/**
	Port of Flash `dialogs.HoverPopup`: a tooltip with a bold title over wrapped
	HTML content, on a `ShadowBG`, placed beside the hovered target via `InfoPopup`.
	An empty title and content produce nothing (matching Flash).
**/
class HoverPopup extends InfoPopup {
	private var bg:Null<Shape>;

	public function new(title:String, content:String, target:DisplayObject) {
		super();
		if (title == "" && content == "") {
			return;
		}
		var titleBox = generateTextBox();
		titleBox.htmlText = "<b>" + title + "</b>";
		titleBox.y = 5;
		var contentBox = generateTextBox();
		contentBox.htmlText = content;
		contentBox.y = titleBox.height + titleBox.y + 5;

		bg = NativeAssets.svg(StaticSvg.QuantityPanel);
		bg.width = width + 10;
		bg.height = height + 12;
		addChildAt(bg, 0);

		positionNear(target);
	}

	private function generateTextBox():TextField {
		var t = new TextField();
		var f = new TextFormat(FontResolver.resolve("Arial"));
		t.defaultTextFormat = f;
		t.width = 150;
		t.height = 1;
		t.x = 5;
		t.multiline = true;
		t.wordWrap = true;
		t.selectable = false;
		t.autoSize = TextFieldAutoSize.LEFT;
		t.antiAliasType = AntiAliasType.ADVANCED;
		addChild(t);
		return t;
	}

	override public function remove():Void {
		if (bg != null) {
			if (bg.parent == this) removeChild(bg);
			bg = null;
		}
		super.remove();
	}
}
