package pr2.net;

import haxe.crypto.Md5;

enum LoginSocketMessage {
	LoginId(loginId:String);
	LoginSuccessful(group:Int, userName:String);
	LoginFailure(message:String);
	Other(command:String);
}

class LoginSocketProtocol {
	public static inline var END_CHAR:String = "\x04";

	private static inline var COMM_PASS:String = "QHE0NSNwKWZZQVEhU19xMA==";
	private static inline var COMM_PASS_SERVER_10:String = "ayo3JnBGQCZVRiEhVjFAQA==";

	private final serverId:Int;
	private var sendNum:Int = 0;
	private var buffer:String = "";

	public function new(serverId:Int) {
		this.serverId = serverId;
	}

	public function requestLoginIdFrame():String {
		return commandFrame("request_login_id`");
	}

	public function commandFrame(command:String):String {
		sendNum++;
		if (sendNum == 12) {
			sendNum++;
		}
		var payload = sendNum + "`" + command;
		var hash = Md5.encode(socketToken(serverId) + payload).substr(0, 3);
		return hash + "`" + payload + END_CHAR;
	}

	public function append(chunk:String):Array<LoginSocketMessage> {
		buffer += chunk;
		var messages:Array<LoginSocketMessage> = [];
		var endIndex = buffer.indexOf(END_CHAR);
		while (endIndex >= 0) {
			var frame = buffer.substr(0, endIndex);
			buffer = buffer.substr(endIndex + 1);
			var message = parseFrame(frame);
			if (message != null) {
				messages.push(message);
			}
			endIndex = buffer.indexOf(END_CHAR);
		}
		return messages;
	}

	public static function parseFrame(frame:String):Null<LoginSocketMessage> {
		var parts = frame.split("`");
		if (parts.length < 3) {
			return null;
		}
		var command = parts[2];
		return switch (command) {
			case "setLoginID" if (parts.length >= 4):
				LoginId(parts[3]);
			case "loginSuccessful":
				var group = parts.length >= 4 ? Std.parseInt(parts[3]) : null;
				LoginSuccessful(group == null ? 0 : group, parts.length >= 5 ? parts[4] : "");
			case "loginFailure":
				LoginFailure(parts.slice(3).join(" "));
			case _:
				Other(command);
		}
	}

	private static function socketToken(serverId:Int):String {
		return serverId == 10 ? COMM_PASS_SERVER_10 : COMM_PASS;
	}
}
