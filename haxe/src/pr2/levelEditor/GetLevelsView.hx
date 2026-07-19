package pr2.levelEditor;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.runtime.SvgAsset;
import pr2.ui.controls.GameButton;
import pr2.ui.view.LoadingView;
import pr2.ui.view.NativeView;

/** Exact native composition of XFL `GetLevelsPopupGraphic`. */
class GetLevelsView extends NativeView {
	private static final LIST_SKIN_GRID = new Rectangle(1.55, 1.55, 148.5, 18.4);

	private var loading:Null<LoadingView>;
	public function new() {
		super();
		var background = SvgAsset.createNormalized("assets/svg/ui/shadow_bg.svg");
		background.name = "background";
		background.x = -147;
		background.y = -129;
		background.scaleX = 1.08087158203125;
		background.scaleY = 1.3455810546875;
		addChild(background);

		var listSkin = SvgAsset.create("assets/svg/ui/text_area_up.svg");
		listSkin.name = "listSkin";
		listSkin.scale9Grid = LIST_SKIN_GRID;
		listSkin.x = -131;
		listSkin.y = -86;
		listSkin.scaleX = 1.64472961425781;
		listSkin.scaleY = 7.27272033691406;
		addChild(listSkin);

		var holder = new Sprite();
		holder.name = "levelsHolder";
		holder.x = -130;
		holder.y = -85;
		addChild(holder);
		var listMask = new Shape();
		listMask.name = "levelsMask";
		listMask.graphics.beginFill(0);
		listMask.graphics.drawRect(-130, -85, 248, 158);
		listMask.graphics.endFill();
		addChild(listMask);
		holder.mask = listMask;

		loading = new LoadingView();
		loading.name = "loadingGraphic";
		loading.y = 0.05;
		addChild(loading);

		var title = field("titleBox", -84.15, -117, 162.85, 17.05, 14, true, TextFormatAlign.CENTER);
		title.text = "-- Load --";
		button("cancel_bt", "Cancel", 58, 89);
		button("load_bt", "Load", -131, 89);
		button("delete_bt", "Delete", -37, 89);
	}

	override public function dispose():Void {
		if (loading != null) loading.dispose();
		loading = null;
		super.dispose();
	}

	private function button(name:String, label:String, x:Float, y:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(76, 22);
		addChild(control);
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign):TextField {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x222222, bold, null, null, null, null, align);
		addChild(text);
		return text;
	}
}
