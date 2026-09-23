package pr2.lobby.players;

/** Parsed guild detail shared by classic and mobile presentations. */
class GuildData {
	public final id:Int;
	public final ownerId:Int;
	public final name:String;
	public final gpToday:Int;
	public final gpTotal:Int;
	public final memberCount:Int;
	public final activeCount:Int;
	public final note:String;
	public final emblem:String;
	public final members:Array<GuildMemberData>;

	public function new(raw:Dynamic) {
		var guild:Dynamic = Reflect.field(raw, "guild"); if (guild == null) guild = raw;
		id = intAny(guild, ["guild_id", "guildId"]);
		ownerId = intAny(guild, ["owner_id", "ownerId"]);
		name = strAny(guild, ["guild_name", "guildName"]);
		gpToday = intAny(guild, ["gp_today", "gpToday"]);
		gpTotal = intAny(guild, ["gp_total", "gpTotal"]);
		memberCount = intAny(guild, ["member_count", "memberCount"]);
		activeCount = intAny(guild, ["active_count", "activeCount"]);
		note = str(guild, "note"); emblem = str(guild, "emblem");
		var values:Array<Dynamic> = cast Reflect.field(raw, "members");
		members = values == null ? [] : [for (value in values) new GuildMemberData(value, ownerId)];
	}
	private static function intAny(value:Dynamic, names:Array<String>):Int {
		for (name in names) { var raw = Reflect.field(value, name); if (raw != null) { if (Std.isOfType(raw, Int) || Std.isOfType(raw, Float)) return Std.int(raw); var n = Std.parseInt(Std.string(raw)); return n == null ? 0 : n; } }
		return 0;
	}
	private static function str(value:Dynamic, name:String):String { var raw = Reflect.field(value, name); return raw == null ? "" : Std.string(raw); }
	private static function strAny(value:Dynamic, names:Array<String>):String { for (name in names) { var text = str(value, name); if (text != "") return text; } return ""; }
}

class GuildMemberData {
	public final raw:Dynamic;
	public final id:Int;
	public final name:String;
	public final group:String;
	public final gpToday:Int;
	public final gpTotal:Int;
	public final owner:Bool;
	public function new(raw:Dynamic, ownerId:Int) {
		this.raw = raw;
		id = parseInt(Reflect.field(raw, "user_id"), Reflect.field(raw, "userId"));
		name = str(raw, "name"); group = str(raw, "group");
		gpToday = parseInt(Reflect.field(raw, "gp_today"), null); gpTotal = parseInt(Reflect.field(raw, "gp_total"), null);
		owner = ownerId != 0 && ownerId == id;
	}
	private static function parseInt(first:Dynamic, second:Dynamic):Int { var value = first == null ? second : first; if (value == null) return 0; if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) return Std.int(value); var n = Std.parseInt(Std.string(value)); return n == null ? 0 : n; }
	private static function str(raw:Dynamic, key:String):String { var value = Reflect.field(raw,key); return value == null ? "" : Std.string(value); }
}
