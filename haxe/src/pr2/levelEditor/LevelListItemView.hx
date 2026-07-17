package pr2.levelEditor;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.view.NativeView;

/** Native selectable row for personal or reported levels. */
class LevelListItemView extends NativeView {
	public var currentFrame(default, null):Int = 1;
	private final reported:Bool;

	public function new(reported:Bool = false) {
		super();
		this.reported = reported;
		field("titleBox", 7, 0, 150, 18, 10, false, TextFormatAlign.LEFT);
		field(reported ? "timeBox" : "statusBox", 160, 0, 72, 18, 9, false, TextFormatAlign.RIGHT);
		gotoAndStop("up");
	}

	public function gotoAndStop(frame:Dynamic):Void {
		var state = Std.string(frame);
		currentFrame = state == "over" ? 2 : state == "selected" ? 3 : 1;
		graphics.clear();
		graphics.beginFill(state == "selected" ? 0xDCEBFF : state == "over" ? 0xE8F2FF : 0xF7F7F7);
		graphics.lineStyle(1, state == "selected" ? 0x4B78B5 : 0xAAAAAA);
		graphics.drawRoundRect(0, 0, 236, 18, 4, 4);
		graphics.endFill();
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign):Void {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		addChild(text);
	}
}
