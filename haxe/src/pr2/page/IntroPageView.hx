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
		skip.x = 365;
		skip.y = 366;
		skip.width = 170;
		skip.height = 20;
		skip.selectable = false;
		skip.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0xB8B8B8, false, null, null, null, null,
			TextFormatAlign.RIGHT);
		skip.text = "Click anywhere to skip";
		addChild(skip);
	}
}
