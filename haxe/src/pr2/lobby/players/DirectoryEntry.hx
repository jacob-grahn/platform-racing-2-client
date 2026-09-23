package pr2.lobby.players;

/** Display-independent row shared by the classic and mobile directories. */
class DirectoryEntry implements pr2.lobby.players.PlayerListSort.SortableRow {
	public var name:String;
	public var group:String = "0";
	public var status:String = "";
	public var rank:Int = 0;
	public var hats:Int = 0;
	public var guildId:Int = 0;
	public var activeMembers:Int = 0;
	public var gpToday:Int = 0;
	public function new(name:String) this.name = name;
	public function sortName():String return name;
	public function numericField(key:String):Float return switch key {
		case "rank": rank;
		case "hats": hats;
		case "activeMembers": activeMembers;
		case "gpToday": gpToday;
		default: 0;
	};
	public function open(guild:Bool):Void {
		if (guild) pr2.lobby.LobbyPopups.showGuild(guildId);
		else if (DirectorySource.intOf(group.split(",")[0]) > 0) pr2.lobby.LobbyPopups.showPlayer(name);
		else pr2.lobby.LobbyPopups.showGuestPlayer(name);
	}
}
