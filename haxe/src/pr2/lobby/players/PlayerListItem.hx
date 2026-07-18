package pr2.lobby.players;

import openfl.text.TextField;
import pr2.display.Removable;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.lobby.players.PlayerListSort.SortableRow;

/**
	Base for a single row in the players/guilds list, wrapping
	`PlayersTabListItemGraphic`. The three dynamic-text fields retain their XFL
	instance names and coordinates in `PlayerListItemView`.
	The name field gets link handling via `HtmlNameMaker`.
**/
class PlayerListItem extends Removable implements SortableRow {
	private var art:PlayerListItemView;
	private var htmlNameMaker:HtmlNameMaker;
	private var nameField:Null<TextField>;
	private var midField:Null<TextField>;
	private var rightField:Null<TextField>;

	public function new() {
		super();
		art = new PlayerListItemView();
		addChild(art);
		nameField = art.nameBox;
		midField = art.rankBox;
		rightField = art.hatBox;
		htmlNameMaker = new HtmlNameMaker();
		if (nameField != null) {
			htmlNameMaker.listenForLink(nameField);
		}
	}

	private function setNameHtml(html:String):Void {
		if (nameField != null) {
			nameField.htmlText = html;
		}
	}

	private function setMid(text:String):Void {
		if (midField != null) {
			midField.text = text;
		}
	}

	private function setRight(text:String):Void {
		if (rightField != null) {
			rightField.text = text;
		}
	}

	// SortableRow — overridden by subclasses.
	public function numericField(key:String):Float {
		return 0;
	}

	public function sortName():String {
		return "";
	}

	override public function remove():Void {
		if (isRemoved()) return;
		if (htmlNameMaker != null) {
			htmlNameMaker.remove();
			htmlNameMaker = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
