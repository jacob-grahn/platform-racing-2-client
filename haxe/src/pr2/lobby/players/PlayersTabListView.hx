package pr2.lobby.players;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.ui.view.NativeView;

/** Source-derived composition of XFL `TabPlayersList`, frames players/guilds. */
class PlayersTabListView extends NativeView {
	public final listHolder:Sprite;

	public function new(guilds:Bool) {
		super();
		// Graphics/Symbol 1015: the only authored background leaf.
		graphics.beginFill(0xFFFFFF, 128 / 255);
		graphics.drawRect(0, 0, 174, 350);
		graphics.endFill();

		button("name_bt", "Name", 2, 29.3);
		if (guilds) {
			button("gp_bt", "GP", 48.9, 13.85);
			button("active_bt", "Active", 89.9, 30.25);
		} else {
			button("rank_bt", "Rank", 103.8, 25.15);
			button("hats_bt", "Hats", 142.8, 22.8);
		}

		listHolder = new Sprite();
		listHolder.name = "listHolder";
		listHolder.y = 17;
		// Graphics/Symbol 26 scaled by the authored 1.74 x 3.33 mask.
		listHolder.scrollRect = new Rectangle(0, 0, 174, 333);
		addChild(listHolder);
	}

	private function button(name:String, label:String, x:Float, width:Float):Void {
		var control = new Sprite();
		control.name = name;
		control.x = x;
		control.buttonMode = true;
		control.mouseChildren = false;
		var text = new TextField();
		text.x = 0;
		text.y = 2;
		text.width = width;
		text.height = 12.15;
		text.selectable = false;
		text.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 10, 0x000000);
		text.text = label;
		control.addChild(text);
		listen(control, MouseEvent.MOUSE_OVER, function(_:MouseEvent):Void text.textColor = 0xFFFF00);
		listen(control, MouseEvent.MOUSE_OUT, function(_:MouseEvent):Void text.textColor = 0x000000);
		addChild(control);
	}
}
