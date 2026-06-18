package pr2.lobby.players;

import openfl.display.Sprite;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.lobby.players.PlayerListSort.SortableRow;
import pr2.runtime.PR2MovieClip;

/**
	Base for a single row in the players/guilds list, wrapping
	`PlayersTabListItemGraphic`. The graphic's three dynamic-text fields were
	exported without instance names, so they are recovered positionally
	(left = name, middle = the rank/GP column, right = the hats/active column).
	The name field gets link handling via `HtmlNameMaker`.
**/
class PlayerListItem extends Sprite implements SortableRow {
	private var art:PR2MovieClip;
	private var htmlNameMaker:HtmlNameMaker;
	private var nameField:Null<TextField>;
	private var midField:Null<TextField>;
	private var rightField:Null<TextField>;

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("PlayersTabListItemGraphic", {maxNestedDepth: 4});
		addChild(art);
		var fields = LobbyArt.textFields(art);
		nameField = fields.length > 0 ? fields[0] : null;
		midField = fields.length > 1 ? fields[1] : null;
		rightField = fields.length > 2 ? fields[2] : null;
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

	public function remove():Void {
		if (htmlNameMaker != null) {
			htmlNameMaker.remove();
			htmlNameMaker = null;
		}
		if (art != null) {
			art.dispose();
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
