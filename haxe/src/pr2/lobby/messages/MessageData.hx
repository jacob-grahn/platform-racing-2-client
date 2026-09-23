package pr2.lobby.messages;

import pr2.lobby.account.Settings;
import pr2.lobby.chat.ChatText;

/** Shared wire model and Flash message formatting rules. */
class MessageData {
	public var id:Int;
	public var name:String;
	public var group:String;
	public var body:String;
	public var guild:Bool;
	public var time:Int;
	public function new(value:Dynamic) {
		id = number(value.message_id); name = string(value.name); group = string(value.group);
		body = string(value.message); guild = value.guild_message == true || string(value.guild_message) == "1";
		time = number(value.time);
	}
	public static function filtered(body:String):String return Settings.getValue(Settings.FILTER_SWEARS, true) ? ChatText.filterSwears(body) : body;
	public static function html(body:String, group:String):String {
		var rank = number(group.split(",")[0]);
		return StringTools.replace(ChatText.parseLinks(rank < 3 ? ChatText.escapeString(body, true) : body), "\r", "<br>");
	}
	public static function quote(body:String):String {
		var result = "\n--- \n" + body;
		return result.length > 200 ? result.substr(0, 200) + "..." : result;
	}
	public static function validate(to:String, body:String):String return to == "" ? "Please enter a name!" : body == "" ? "You didn't write a message!" : "";
	private static function string(value:Dynamic):String return value == null ? "" : Std.string(value);
	private static function number(value:Dynamic):Int { var n = Std.parseInt(string(value)); return n == null ? 0 : n; }
}
