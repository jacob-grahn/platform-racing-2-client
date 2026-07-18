package pr2.levelEditor;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.view.NativeView;
import pr2.ui.SelectableButton.SelectableView;
import pr2.runtime.SvgAsset;
import openfl.display.DisplayObject;

/** Native selectable row for personal or reported levels. */
class LevelListItemView extends NativeView implements SelectableView {
	public var currentFrame(default, null):Int = 1;
	private final reported:Bool;
	private var authoredBackground:Null<DisplayObject>;

	public function new(reported:Bool = false) {
		super();
		this.reported = reported;
		field("titleBox", 2, reported ? 2.5 : 2, 158.95, reported ? 14.55 : 14.5, 12, false, TextFormatAlign.LEFT,
			"Title goes here");
		field(reported ? "timeBox" : "statusBox", 171, reported ? 2.5 : 2, reported ? 78.05 : 72, reported ? 14.55 : 14.5, 12, false,
			reported ? TextFormatAlign.RIGHT : TextFormatAlign.LEFT, reported ? "14/Jun/2020" : "Unpublished");
		setInteractionState("up");
	}

	public function setInteractionState(state:String):Void {
		currentFrame = state == "over" ? 6 : state == "selected" ? 11 : 1;
		if (authoredBackground != null && authoredBackground.parent == this) removeChild(authoredBackground);
		var path = state == "selected" ? "assets/svg/editor/level_list_selected.svg" : state == "over" ? "assets/svg/editor/level_list_over.svg" :
			"assets/svg/editor/level_list_up.svg";
		authoredBackground = SvgAsset.create(path);
		authoredBackground.name = "authoredBackground";
		addChildAt(authoredBackground, 0);
	}

	private function field(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign, value:String):Void {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0x333333, bold, null, null, null, null, align);
		text.text = value;
		addChild(text);
	}
}
