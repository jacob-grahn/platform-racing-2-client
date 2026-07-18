package pr2.page;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.view.NativeView;

/** Native full-stage intro shell and skip prompt. */
class IntroPageView extends NativeView {
	public final introHolder:Sprite;

	public function new() {
		super();
		introHolder = new Sprite();
		introHolder.name = "introHolder";
		addChild(introHolder);
		var skip = new TextField();
		skip.name = "skipPrompt";
		skip.x = 5;
		skip.y = 381.15;
		skip.width = 138.3;
		skip.height = 18.55;
		skip.selectable = false;
		var format = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0x999999, false, null, null, null, null, TextFormatAlign.LEFT);
		format.letterSpacing = -0.05;
		skip.defaultTextFormat = format;
		skip.text = "Click anywhere to skip";
		addChild(skip);
	}
}
