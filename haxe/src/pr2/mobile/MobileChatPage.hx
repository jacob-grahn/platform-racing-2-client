package pr2.mobile;

import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
import pr2.lobby.LobbyPopups;
import pr2.lobby.Memory;
import pr2.lobby.chat.ChatLog;
import pr2.lobby.chat.ChatLog.ChatSendAction;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.page.Page;
import pr2.runtime.FontResolver;

/** Touch-sized chat surface; shares the desktop chat model and socket protocol. */
class MobileChatPage extends Page {
	private var room:TextField;
	private var transcript:TextField;
	private var input:TextField;
	private var join:MobileButton;
	private var send:MobileButton;
	private var nameMaker:HtmlNameMaker;
	private var log:ChatLog;

	override public function initialize():Void {
		nameMaker = new HtmlNameMaker();
		log = new ChatLog(nameMaker);
		room = inputField(18);
		room.text = Memory.getString("chatRoom", "main");
		room.addEventListener(KeyboardEvent.KEY_DOWN, onRoomKey);
		addChild(room);
		join = new MobileButton("Join Room", 126, 48, changeRoom);
		addChild(join);

		transcript = new TextField();
		transcript.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, 17, 0x253149);
		transcript.background = true;
		transcript.backgroundColor = 0xF4F6FA;
		transcript.border = true;
		transcript.borderColor = 0x8192AD;
		transcript.multiline = true;
		transcript.wordWrap = true;
		transcript.selectable = true;
		addChild(transcript);

		input = inputField(18);
		input.addEventListener(KeyboardEvent.KEY_DOWN, onInputKey);
		addChild(input);
		send = new MobileButton("Send", 100, 48, sendMessage);
		addChild(send);

		CommandHandler.commandHandler.defineCommand("chat", function(args:Array<String>):Void {
			log.handleMessageFromArray(args);
			showMessages();
		});
		CommandHandler.commandHandler.defineCommand("systemChat", function(args:Array<String>):Void {
			log.receiveSystemMessage(args);
			showMessages();
		});
		LobbySocket.write("set_chat_room`" + room.text);
	}

	public function setLayout(width:Float, height:Float):Void {
		var pad = 10.0;
		room.x = pad;
		room.y = pad;
		room.width = Math.max(120, width - 166);
		room.height = 48;
		join.x = width - 146;
		join.y = pad;
		transcript.x = pad;
		transcript.y = 66;
		transcript.width = width - pad * 2;
		transcript.height = Math.max(80, height - 132);
		input.x = pad;
		input.y = height - 58;
		input.width = Math.max(120, width - 130);
		input.height = 48;
		send.x = width - 110;
		send.y = height - 58;
	}

	private function changeRoom():Void {
		if (StringTools.trim(room.text) == "") room.text = "main";
		Memory.set("chatRoom", room.text);
		LobbySocket.write("set_chat_room`" + room.text);
		log.clear();
		showMessages();
	}

	private function sendMessage():Void {
		var message = input.text;
		input.text = "";
		switch (ChatLog.classifySend(message)) {
			case WriteChat(text): LobbySocket.write("chat`" + text);
			case ViewPlayer(name): LobbyPopups.showPlayer(name);
			case OpenGuild(name): LobbyPopups.showGuildByName(name);
			case SendPm(target): LobbyPopups.sendMessage(target);
			case OpenLevel(query): LobbyPopups.showLevel(query);
			case ArtifactHint | Ignore:
		}
		transcript.scrollV = transcript.maxScrollV;
	}

	private function showMessages():Void {
		transcript.htmlText = log.existingMessages;
		transcript.scrollV = transcript.maxScrollV;
	}

	private function onRoomKey(event:KeyboardEvent):Void if (event.keyCode == Keyboard.ENTER) changeRoom();
	private function onInputKey(event:KeyboardEvent):Void if (event.keyCode == Keyboard.ENTER) sendMessage();

	private static function inputField(size:Int):TextField {
		var field = new TextField();
		field.defaultTextFormat = new TextFormat(FontResolver.DEFAULT, size, 0x172137);
		field.type = TextFieldType.INPUT;
		field.background = true;
		field.backgroundColor = 0xFFFFFF;
		field.border = true;
		field.borderColor = 0x8192AD;
		return field;
	}

	override public function remove():Void {
		LobbySocket.write("set_chat_room`none");
		CommandHandler.commandHandler.defineCommand("chat", null);
		CommandHandler.commandHandler.defineCommand("systemChat", null);
		room.removeEventListener(KeyboardEvent.KEY_DOWN, onRoomKey);
		input.removeEventListener(KeyboardEvent.KEY_DOWN, onInputKey);
		join.remove();
		send.remove();
		nameMaker.remove();
		super.remove();
	}
}
