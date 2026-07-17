package pr2.levelEditor;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;

/** Explicit vector replacement for the editor's small timeline-backed controls. */
class EditorNativeGraphic extends Sprite {
	public function new(kind:String) {
		super();
		name = kind;
		buttonMode = true;
		useHandCursor = true;
		mouseChildren = false;
		draw(kind);
	}

	public function dispose():Void {
		if (parent != null) parent.removeChild(this);
	}

	private function draw(kind:String):Void {
		var label = switch (kind) {
			case "DeleteButton" | "ObjectDeleterButtonGraphic": "×";
			case "ResizeButton": "↘";
			case "EditTextButton" | "TextToolButtonGraphic" | "TextToolCursorGraphic": "T";
			case "BlockOptionsButton": "…";
			case "MusicNoteGraphic": "♪";
			case "ItemButtonGraphic": "⚡";
			case "HatsButtonGraphic": "H";
			case "BrushGraphic" | "BrushButtonGraphic": "B";
			case "EraserButtonGraphic": "E";
			case "LandscapeGraphic": "▰";
			default: "";
		}
		var color = kind == "DeleteButton" || kind == "ObjectDeleterButtonGraphic" ? 0xB74B4B : 0x66788C;
		graphics.beginFill(color);
		graphics.lineStyle(1, 0x333333);
		graphics.drawRoundRect(0, 0, 28, 28, 6, 6);
		graphics.endFill();
		if (kind == "ValueButtonGraphic") {
			field("titleBox", 1, 1, 26, 12, 7);
			field("valueBox", 1, 13, 26, 13, 8);
		} else {
			var text = field(null, 0, 4, 28, 21, 13);
			text.text = label;
		}
	}

	private function field(name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int):TextField {
		var text = new TextField();
		if (name != null) text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.mouseEnabled = false;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0xFFFFFF, true, null, null, null, null,
			TextFormatAlign.CENTER);
		addChild(text);
		return text;
	}
}
