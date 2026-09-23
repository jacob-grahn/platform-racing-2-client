package pr2.lobby.players;

import pr2.lobby.LobbySession;
import pr2.util.Dyn;

/** Profile interpretation shared by the authored and mobile presentations. */
class ProfileData {
	public final raw:Dynamic;
	public function new(raw:Dynamic) this.raw = raw;
	public function number(key:String):Int return Dyn.int(raw, key);
	public function text(key:String):String return Dyn.string(raw, key, "");
	public function flag(key:String):Bool return Dyn.bool(raw, key);
	public function isGuest():Bool return number("group") < 1 || number("group") > 3;
	public function groupLabel():String {
		if (isGuest()) return "Guest";
		if (LobbySession.serverOwner == number("userId")) return "Server Owner";
		return switch number("group") {
			case 1: flag("ca") ? "Community Ambassador" : "Member";
			case 2: flag("temp_mod") ? "Temporary Moderator" : flag("trial_mod") ? "Trial Moderator" : "Moderator";
			default: "Admin";
		};
	}
	public function canInvite():Bool return !isGuest() && LobbySession.guildOwner && number("guildId") == 0;
	public function canKick():Bool return !isGuest() && LobbySession.guildOwner && number("guildId") != 0 && number("guildId") == LobbySession.guildId;
	public function staffTools():Bool return LobbySession.group >= 2 || (!isGuest() && LobbySession.group == 1 && LobbySession.isTempMod && number("group") == 1);
	public static function shortDate(t:Float):String {
		var d = Date.fromTime(t * 1000);
		return d.getDate() + "/" + ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][d.getMonth()] + "/" + d.getFullYear();
	}
	public static function longDate(t:Float):String {
		var d = Date.fromTime(t * 1000); var hour = d.getHours(); var h = hour % 12;
		return ["January","February","March","April","May","June","July","August","September","October","November","December"][d.getMonth()]
			+ " " + d.getDate() + ", " + d.getFullYear() + " " + (h == 0 ? 12 : h) + ":" + StringTools.lpad(Std.string(d.getMinutes()), "0", 2)
			+ ":" + StringTools.lpad(Std.string(d.getSeconds()), "0", 2) + (hour >= 12 ? " PM" : " AM");
	}
}
