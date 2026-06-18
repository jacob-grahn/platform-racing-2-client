package pr2.lobby.chat;

enum ChatSendAction {
	WriteChat(message:String);
	ViewPlayer(name:String);
	ArtifactHint;
	OpenGuild(name:String);
	SendPm(target:String);
	OpenLevel(query:String);
	Ignore;
}

/**
	Pure chat-record model ported from Flash `page.Chat`: it accumulates the
	rolling HTML transcript (capped at `maxMessages` lines), formats incoming
	`chat` / `systemChat` frames the way the original did, and classifies an
	outgoing line into a slash-command action. Kept display-free so the formatting
	and the 40-line trimming can be tested directly.
**/
class ChatLog {
	public var existingMessages(default, null):String = "";
	public var messages(default, null):Int = 0;
	public var maxMessages:Int = 40;

	private var nameMaker:HtmlNameMaker;
	private var filterSwears:Bool;

	public function new(nameMaker:HtmlNameMaker, filterSwears:Bool = true) {
		this.nameMaker = nameMaker;
		this.filterSwears = filterSwears;
	}

	public function clear():Void {
		existingMessages = "";
		messages = 0;
	}

	/** Format a `chat` frame `[name, group, text]` and append it. */
	public function handleMessageFromArray(arr:Array<String>, fred:Bool = false):String {
		var userName = arr.length > 0 ? arr[0] : "";
		var group = arr.length > 1 ? arr[1] : "0";
		var messageText = arr.length > 2 ? arr[2] : "";
		if (!fred) {
			messageText = filterSwears ? ChatText.escapeAndFilterString(messageText) : ChatText.escapeString(messageText);
		}
		var chatMessageName = nameMaker.makeName(userName, group);
		var fullMessage = chatMessageName + "<font color='#666666'>: " + messageText + "</font><br/>";
		if (fred) {
			fullMessage = "<i>" + fullMessage + "</i>";
		}
		return displayMessage(fullMessage);
	}

	public function receiveSystemMessage(arr:Array<String>):String {
		var text = arr.length > 0 ? arr[0] : "";
		return displayMessage("<br/><i><font color='#3E8697'>" + text + "</font></i><br/><br/>");
	}

	public function displayMessage(message:String):String {
		messages++;
		if (messages > maxMessages) {
			var cut = existingMessages.indexOf("<br/>");
			if (cut >= 0) {
				existingMessages = existingMessages.substr(cut + 5);
			}
		}
		existingMessages += message;
		return existingMessages;
	}

	/** Classify an outgoing chat line, matching the AS3 slash-command routing. */
	public static function classifySend(message:String):ChatSendAction {
		var lower = message.toLowerCase();
		var trimmed = ChatText.trimWhitespace(lower);
		if (lower.indexOf("/view ") == 0) {
			return ViewPlayer(message.substr(6));
		} else if (trimmed == "/hint" || trimmed == "/lotw" || trimmed == "/arti") {
			return ArtifactHint;
		} else if (message.indexOf("/guild ") == 0) {
			return OpenGuild(message.substr(7));
		} else if (message.indexOf("/pm ") == 0) {
			return SendPm(message.substr(4));
		} else if (message.indexOf("/level ") == 0) {
			return OpenLevel(message.substr(7));
		}
		var cleaned = StringTools.replace(message, "\n", "");
		return cleaned == "" ? Ignore : WriteChat(cleaned);
	}
}
