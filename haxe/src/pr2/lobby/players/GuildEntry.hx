package pr2.lobby.players;

import pr2.lobby.NumberFormat;

/**
	Port of Flash `social.PlayersTabGuildListItem`: a guild row showing the linked
	guild name, today's GP (comma-formatted, in the rank column), and the active
	member count (in the hats column).
**/
class GuildEntry extends PlayerListItem {
	public var guildName:String;
	public var activeMembers:Int;
	public var gpToday:Int;

	public function new(name:String, guildId:Int, activeCount:Int, gpTodayCount:Int) {
		super();
		this.guildName = name;
		this.activeMembers = activeCount;
		this.gpToday = gpTodayCount;
		setNameHtml(htmlNameMaker.makeGuild(name, guildId));
		setMid(NumberFormat.withCommas(gpTodayCount));
		setRight(Std.string(activeCount));
	}

	override public function numericField(key:String):Float {
		return switch (key) {
			case "gpToday": gpToday;
			case "activeMembers": activeMembers;
			default: 0;
		};
	}

	override public function sortName():String {
		return guildName;
	}
}
