package pr2.lobby.chat;

import openfl.events.TextEvent;
import openfl.text.TextField;
import pr2.lobby.LobbyPopups;
import haxe.io.Bytes;

/**
	Port of Flash `com.jiggmin.data.HTMLNameMaker`.

	Builds the colored, clickable HTML used for player/guild/level/url links in
	chat and message bodies, and wires `event:` link clicks on registered text
	fields back to the lobby popup service. The color rules follow the v160 group
	codes documented in the AS3 source.
**/
class HtmlNameMaker {
	private var fields:Array<TextField> = [];

	public function new() {}

	public static function groupColor(groupStr:String):String {
		var vars = groupStr.split(",");
		var group = Std.parseInt(vars[0]);
		if (group == null) {
			group = 0;
		}
		var group2 = vars.length > 1 ? vars[1] : null;
		var color = "676666"; // guests
		if (group == 1) {
			color = group2 == "1" ? "BC9055" : "047B7B"; // ambassador vs member
		} else if (group == 2) {
			color = group2 == "0" ? "006400" : (group2 == "1" ? "0092FF" : "1C369F");
		} else if (group == 3) {
			color = "870A6F";
		}
		if (group2 == "*") {
			color = "83C141"; // special users
		}
		return color;
	}

	public function makeName(name:String, groupStr:String, dispText:String = ""):String {
		var color = groupColor(groupStr);
		var group = Std.parseInt(groupStr.split(",")[0]);
		if (group == null) {
			group = 0;
		}
		if (dispText == "") {
			dispText = name;
		}
		name = ChatText.cleanHTML(name);
		dispText = ChatText.cleanHTML(dispText);
		return '<u><font color="#' + color + '"><a href="event:user`' + group + "`" + name + '">' + dispText + "</a></font></u>";
	}

	public function makeGuild(name:String, id:Int):String {
		name = ChatText.escapeString(name);
		return '<u><font color="#0000FF"><a href="event:guild`' + id + '">' + name + "</a></font></u>";
	}

	public function makeLevel(name:String, id:Int):String {
		name = ChatText.escapeString(name);
		return '<u><font color="#0000FF"><a href="event:level`' + id + '">' + name + "</a></font></u>";
	}

	public function makeLink(disp:String, url:String):String {
		disp = ChatText.escapeString(disp);
		url = encodeURICompat(ChatText.escapeString(url));
		return '<u><font color="#0000FF"><a href="event:url`' + url + '">' + disp + "</a></font></u>";
	}

	private static function encodeURICompat(value:String):String {
		var bytes = Bytes.ofString(value);
		var out = new StringBuf();
		for (i in 0...bytes.length) {
			var code = bytes.get(i);
			if (isEncodeURIUnescaped(code)) {
				out.addChar(code);
			} else {
				out.add("%");
				out.add(StringTools.hex(code, 2));
			}
		}
		return out.toString();
	}

	private static function isEncodeURIUnescaped(code:Int):Bool {
		return (code >= "A".code && code <= "Z".code)
			|| (code >= "a".code && code <= "z".code)
			|| (code >= "0".code && code <= "9".code)
			|| "-_.!~*'()".indexOf(String.fromCharCode(code)) >= 0
			|| ";/?:@&=+$,#[]".indexOf(String.fromCharCode(code)) >= 0;
	}

	public function listenForLink(field:TextField):Void {
		fields.push(field);
		field.addEventListener(TextEvent.LINK, clickLink);
	}

	private function clickLink(e:TextEvent):Void {
		var arr = e.text.split("`");
		var mode = arr[0];
		switch (mode) {
			case "user":
				var group = arr.length > 1 ? arr[1] : "0";
				var userName = arr.length > 2 ? arr[2] : "";
				var forcePlayer = arr.length > 3 && Std.parseInt(arr[3]) == 1;
				var groupNum = Std.parseInt(group.split(",")[0]);
				if ((groupNum != null && groupNum > 0) || forcePlayer) {
					LobbyPopups.showPlayer(userName);
				} else {
					LobbyPopups.showGuestPlayer(userName);
				}
			case "guild":
				LobbyPopups.showGuild(Std.parseInt(arr[1]) == null ? 0 : Std.parseInt(arr[1]));
			case "invite":
				LobbyPopups.showGuildJoin(Std.parseInt(arr[1]) == null ? 0 : Std.parseInt(arr[1]));
			case "level":
				LobbyPopups.showLevel(arr.length > 1 ? arr[1] : "");
			case "url":
				LobbyPopups.openUrl(arr.length > 1 ? arr[1] : "");
			case "discordverify":
				LobbyPopups.showDiscordVerification(arr.length > 1 ? arr[1] : "");
			default:
		}
	}

	public function remove():Void {
		for (field in fields) {
			field.removeEventListener(TextEvent.LINK, clickLink);
		}
		fields = [];
	}
}
