package pr2.lobby.tabs;

import openfl.display.DisplayObject;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyPopups;
import pr2.lobby.Memory;
import pr2.lobby.chat.ArtifactHintClient;
import pr2.lobby.chat.ChatLog;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.lobby.dialogs.ChatRoomInfoPopup;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.page.Page;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/**
	Port of Flash `chat.ChatInstance` (+ its `page.Chat` base).

	Renders the `ChatGraphic` art and wires the full chat workflow: room
	selection with enter/join, the `set_chat_room` socket commands, send with
	slash-command routing, the rolling HTML transcript with lock-to-bottom
	scrolling, the info hover popup, and the Ctrl pause/update toggle. Incoming
	`chat` / `systemChat` frames are routed in through `CommandHandler`.
**/
class ChatTab extends Page {
	public static var instance(default, null):Null<ChatTab> = null;

	private var art:Null<PR2MovieClip>;
	private var roomBox:Null<TextField>;
	private var chatInput:Null<TextField>;
	private var textBox:Null<TextField>;
	private var nameMaker:HtmlNameMaker;
	private var log:ChatLog;
	private var lockBot:Bool = true;
	private var updateMessages:Bool = true;
	private var sendBinding:Null<LobbyArt.Binding>;
	private var joinBinding:Null<LobbyArt.Binding>;
	private var infoButton:Null<DisplayObject>;
	private var infoPopup:Null<ChatRoomInfoPopup>;
	private var artifactHintGeneration:Int = 0;
	private var artifactHintRemoved:Bool = false;

	public function new() {
		super();
		instance = this;
		nameMaker = new HtmlNameMaker();
		log = new ChatLog(nameMaker);
	}

	public function getChatRecord():String {
		return textBox == null ? "" : textBox.text;
	}

	override public function initialize():Void {
		art = PR2MovieClip.fromLinkage("ChatGraphic", {maxNestedDepth: 8});
		addChild(art);

		roomBox = LobbyArt.text(art, "roomBox");
		chatInput = LobbyArt.text(art, "chatInput");
		textBox = LobbyArt.text(art, "textBox");

		if (roomBox != null) {
			roomBox.addEventListener(KeyboardEvent.KEY_DOWN, roomBoxListenForEnter);
		}
		if (chatInput != null) {
			chatInput.addEventListener(KeyboardEvent.KEY_DOWN, chatInputListenForEnter);
			chatInput.addEventListener(FocusEvent.FOCUS_IN, lockToBottom);
		}
		if (textBox != null) {
			textBox.addEventListener(FocusEvent.FOCUS_OUT, lockToBottom);
			nameMaker.listenForLink(textBox);
		}
		sendBinding = LobbyArt.bind(DisplayUtil.findByName(art, "send_bt"), clickSend);
		joinBinding = LobbyArt.bind(DisplayUtil.findByName(art, "joinRoom_bt"), changeRoom);
		infoButton = DisplayUtil.findByName(art, "infoButton");
		if (infoButton != null) {
			infoButton.addEventListener(MouseEvent.MOUSE_OVER, overInfo);
			infoButton.addEventListener(MouseEvent.MOUSE_OUT, outInfo);
		}

		addEventListener(KeyboardEvent.KEY_DOWN, pauseListener);
		addEventListener(KeyboardEvent.KEY_UP, pauseListener);

		CommandHandler.commandHandler.defineCommand("chat", function(args) {
			log.handleMessageFromArray(args);
			showMessages();
		});
		CommandHandler.commandHandler.defineCommand("systemChat", function(args) {
			log.receiveSystemMessage(args);
			showMessages();
		});

		if (!Memory.has("chatRoom")) {
			Memory.set("chatRoom", "main");
		}
		var room = Memory.getString("chatRoom", "main");
		if (roomBox != null) {
			roomBox.text = room;
		}
		LobbySocket.write("set_chat_room`" + room);
	}

	private function pauseListener(e:KeyboardEvent):Void {
		// Ctrl (keyCode 17) freezes/unfreezes transcript updates.
		if (e.keyCode == 17) {
			updateMessages = !updateMessages;
			showMessages();
		}
	}

	private function chatInputListenForEnter(e:KeyboardEvent):Void {
		if (e.keyCode == 13 && chatInput != null) {
			sendMessage(chatInput.text);
		}
	}

	private function clickSend():Void {
		if (chatInput != null) {
			sendMessage(chatInput.text);
		}
	}

	private function sendMessage(message:String):Void {
		if (chatInput != null) {
			chatInput.text = "";
		}
		routeSend(message);
		if (textBox != null) {
			textBox.scrollV = textBox.maxScrollV;
		}
		lockBot = true;
	}

	private function routeSend(message:String):Void {
		switch (ChatLog.classifySend(message)) {
			case WriteChat(text):
				LobbySocket.write("chat`" + text);
			case ViewPlayer(name):
				LobbyPopups.showPlayer(name);
			case OpenGuild(name):
				LobbyPopups.showGuildByName(name);
			case SendPm(target):
				LobbyPopups.sendMessage(target);
			case OpenLevel(query):
				LobbyPopups.showLevel(query);
			case ArtifactHint:
				loadArtifactHint();
			case Ignore:
		}
	}

	private function loadArtifactHint():Void {
		var generation = ++artifactHintGeneration;
		ArtifactHintClient.load(function(data):Void {
			if (artifactHintRemoved || generation != artifactHintGeneration) {
				return;
			}
			for (message in ArtifactHintClient.fredMessages(data, nameMaker)) {
				log.handleMessageFromArray(["Fred the G. Cactus", "3,*", message], true);
			}
			showMessages();
		}, function(_:String):Void {});
	}

	private function roomBoxListenForEnter(e:KeyboardEvent):Void {
		if (e.keyCode == 13) {
			changeRoom();
		}
	}

	private function changeRoom():Void {
		if (roomBox == null) {
			return;
		}
		if (roomBox.text == "") {
			roomBox.text = "main";
		}
		Memory.set("chatRoom", roomBox.text);
		LobbySocket.write("set_chat_room`" + roomBox.text);
		log.clear();
		if (textBox != null) {
			textBox.text = "";
		}
	}

	private function showMessages():Void {
		if (!updateMessages || textBox == null) {
			return;
		}
		maybeLockToBottom();
		textBox.htmlText = log.existingMessages;
		if (lockBot) {
			lockToBottom();
		}
	}

	private function maybeLockToBottom():Void {
		if (textBox == null) {
			return;
		}
		lockBot = textBox.scrollV >= textBox.maxScrollV - 2;
	}

	private function lockToBottom(?e:FocusEvent):Void {
		lockBot = true;
		if (textBox != null) {
			textBox.scrollV = textBox.maxScrollV;
		}
	}

	private function overInfo(_:MouseEvent):Void {
		if (infoButton != null) {
			infoPopup = new ChatRoomInfoPopup(infoButton);
		}
	}

	private function outInfo(_:MouseEvent):Void {
		removeInfoPopup();
	}

	private function removeInfoPopup():Void {
		if (infoPopup != null) {
			infoPopup.remove();
			infoPopup = null;
		}
	}

	override public function remove():Void {
		artifactHintRemoved = true;
		artifactHintGeneration++;
		LobbySocket.write("set_chat_room`none");
		if (instance == this) {
			instance = null;
		}
		if (roomBox != null) {
			roomBox.removeEventListener(KeyboardEvent.KEY_DOWN, roomBoxListenForEnter);
		}
		if (chatInput != null) {
			chatInput.removeEventListener(KeyboardEvent.KEY_DOWN, chatInputListenForEnter);
			chatInput.removeEventListener(FocusEvent.FOCUS_IN, lockToBottom);
		}
		if (textBox != null) {
			textBox.removeEventListener(FocusEvent.FOCUS_OUT, lockToBottom);
		}
		if (infoButton != null) {
			infoButton.removeEventListener(MouseEvent.MOUSE_OVER, overInfo);
			infoButton.removeEventListener(MouseEvent.MOUSE_OUT, outInfo);
			infoButton = null;
		}
		removeInfoPopup();
		LobbyArt.unbind(sendBinding);
		LobbyArt.unbind(joinBinding);
		removeEventListener(KeyboardEvent.KEY_DOWN, pauseListener);
		removeEventListener(KeyboardEvent.KEY_UP, pauseListener);
		CommandHandler.commandHandler.defineCommand("chat", null);
		CommandHandler.commandHandler.defineCommand("systemChat", null);
		nameMaker.remove();
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
