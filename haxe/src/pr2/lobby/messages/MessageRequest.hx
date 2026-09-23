package pr2.lobby.messages;

import pr2.net.ServerConfig;

/** The same endpoints and wire fields for both presentations. */
class MessageRequest {
	public var url:String;
	public var fields:Map<String, String>;
	public function new(action:String, id:Int = 0, to:String = "", body:String = "", guild:Bool = false) {
		url = switch action {
			case "send": guild ? ServerConfig.guildMessageUrl() : ServerConfig.messageSendUrl();
			case "report": ServerConfig.messageReportUrl();
			case "delete": ServerConfig.messageDeleteUrl();
			case "deleteAll": ServerConfig.messagesDeleteAllUrl();
			default: throw "Unknown message action";
		};
		fields = action == "send" ? ["to_name" => to, "message" => body] : action == "deleteAll" ? new Map() : ["message_id" => Std.string(id)];
	}
}
