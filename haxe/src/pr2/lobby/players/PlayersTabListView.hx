package pr2.lobby.players;

import openfl.display.Sprite;
import pr2.ui.controls.GameButton;
import pr2.ui.view.NativeView;

/** Native sortable-list shell shared by player and guild listings. */
class PlayersTabListView extends NativeView {
	public function new(guilds:Bool) {
		super();
		graphics.beginFill(0xF2F2F2, 0.96);
		graphics.lineStyle(1, 0x777777);
		graphics.drawRoundRect(0, 0, 252, 334, 10, 10);
		graphics.endFill();
		button("name_bt", "Name", 7, 7, 118);
		button(guilds ? "active_bt" : "rank_bt", guilds ? "Active" : "Rank", 129, 7, 55);
		button(guilds ? "gp_bt" : "hats_bt", guilds ? "GP" : "Hats", 188, 7, 57);
		var holder = new Sprite();
		holder.name = "listHolder";
		holder.x = 7;
		holder.y = 38;
		addChild(holder);
	}

	private function button(name:String, label:String, x:Float, y:Float, width:Float):Void {
		var control = ownControl(new GameButton(label));
		control.name = name;
		control.x = x;
		control.y = y;
		control.setSize(width, 24);
		addChild(control);
	}
}
