package pr2.levelEditor;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native level-list popup shared by personal levels, reports, and loadouts. */
class GetLevelsView extends NativeView {
	public function new() {
		super();
		graphics.beginFill(0xF4F4F4, 0.98);
		graphics.lineStyle(2, 0x666666);
		graphics.drawRoundRect(-150, -135, 300, 270, 14, 14);
		graphics.endFill();
		field("titleBox", -125, -122, 250, 23, 16, true, TextFormatAlign.CENTER);
		var holder = new Sprite();
		holder.name = "levelsHolder";
		holder.x = -119;
		holder.y = -85;
		addChild(holder);
		button("load_bt", "Load", -119, 99, 70);
		button("delete_bt", "Delete", -39, 99, 70);
		button("cancel_bt", "Cancel", 41, 99, 78);
		var loading = new Sprite();
		loading.name = "loadingGraphic";
		loading.graphics.beginFill(0xFFFFFF, 0.9);
		loading.graphics.drawRect(-120, -86, 240, 160);
		loading.graphics.endFill();
		fieldOn(loading, null, -70, -8, 140, 20, 11, true, TextFormatAlign.CENTER).text = "Loading levels...";
		addChild(loading);
	}

	private function button(name:String, label:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 24);
		addChild(control);
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign):TextField {
		return fieldOn(this, name, x, y, width, height, size, bold, align);
	}

	private function fieldOn(parent:Sprite, name:Null<String>, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool,
		align:TextFormatAlign):TextField {
		var text = new TextField();
		if (name != null) text.name = name;
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
