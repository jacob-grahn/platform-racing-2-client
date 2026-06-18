package pr2.lobby.players;

/**
	Port of Flash `social.PlayersTabListItemInfo`: a player row showing the linked
	name, rank, and hat count. When a `server` is given the name links carry a
	`"name (server)"` display label, matching the online list.
**/
class PlayerEntry extends PlayerListItem {
	public var userName:String;
	public var rank:Int;
	public var hats:Int;

	public function new(name:String, group:String, rank:Int, hats:Int, server:String = "") {
		super();
		this.userName = name;
		this.rank = rank;
		this.hats = hats;
		var nameLink = server != "" ? htmlNameMaker.makeName(name, group, name + " (" + server + ")") : htmlNameMaker.makeName(name, group);
		setNameHtml(nameLink);
		setMid(Std.string(rank));
		setRight(Std.string(hats));
	}

	override public function numericField(key:String):Float {
		return switch (key) {
			case "rank": rank;
			case "hats": hats;
			default: 0;
		};
	}

	override public function sortName():String {
		return userName;
	}
}
