package pr2.lobby.players;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.view.NativeView;

/** Native three-column player/guild list row. */
class PlayerListItemView extends NativeView {
	public final nameBox:TextField;
	public final rankBox:TextField;
	public final hatBox:TextField;

	public function new() {
		super();
		// TabPlayersListItem has no row background. Its complete authored
		// composition is these three named Verdana fields at the XFL coordinates.
		nameBox = field("nameBox", 2, 2, 95);
		rankBox = field("rankBox", 106, 2, 30);
		hatBox = field("hatBox", 146, 2, 24);
	}

	private function field(name:String, x:Float, y:Float, width:Float):TextField {
		var text = new TextField();
		text.name = name;
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = name == "nameBox" ? 12.05 : 12.15;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0x000000, false, null, null, null, null,
			TextFormatAlign.LEFT);
		addChild(text);
		return text;
	}
}
