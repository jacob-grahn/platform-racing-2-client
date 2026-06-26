package pr2.gameplay;

import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.ui.Keyboard;
import pr2.lobby.LobbyArt;
import pr2.lobby.chat.ChatText;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `gameplay.RaceChat` around the authored `RaceChatGraphic`.
**/
class RaceChat extends Sprite {
	public static var textBox:Null<TextField>;

	private static inline final MAX_MESSAGES:Int = 7;

	private var art:Null<PR2MovieClip>;
	private var chatInput:Null<TextField>;
	private var topText:Null<TextField>;
	private var bgText:Null<TextField>;
	private var existingMessages:String = "";
	private var messages:Int = 0;
	private var htmlNameMaker:HtmlNameMaker = new HtmlNameMaker();
	private var sendHandler:Null<String->Bool>;
	private var stageListenersActive:Bool = false;
	private var ownerStage:Null<Stage>;

	public function new(?sendHandler:String->Bool) {
		super();
		this.sendHandler = sendHandler;
		art = PR2MovieClip.fromLinkage("RaceChatGraphic", {maxNestedDepth: 6});
		addChild(art);

		chatInput = LobbyArt.text(art, "chatInput");
		topText = LobbyArt.text(cast LobbyArt.findByName(art, "top"), "textBox1");
		bgText = LobbyArt.text(cast LobbyArt.findByName(art, "bg"), "textBox2");

		if (chatInput != null) {
			chatInput.restrict = "^`";
			textBox = chatInput;
		}
		if (topText != null) topText.mouseWheelEnabled = false;
		if (bgText != null) bgText.mouseWheelEnabled = false;
		if (topText != null) htmlNameMaker.listenForLink(topText);
		if (art != null) art.addEventListener(MouseEvent.MOUSE_WHEEL, ensureBottom);
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
	}

	public function submitText(message:String):Bool {
		if (chatInput != null) {
			chatInput.text = "";
		}
		var cleaned = stripForbidden(message);
		if (ChatText.trimWhitespace(cleaned) == "") {
			return true;
		}
		return sendHandler == null ? false : sendHandler(cleaned);
	}

	public function receiveSystemMessage(message:String):Void {
		displayMessage("<i><font color='#3E8697'>" + ChatText.escapeString(message) + "</font></i><br/>");
	}

	public function receiveChatMessage(userName:String, group:String, messageText:String, fred:Bool = false, filterSwears:Bool = true):Void {
		if (!fred) {
			messageText = filterSwears ? ChatText.escapeAndFilterString(messageText) : ChatText.escapeString(messageText);
		}
		var chatMessageName = htmlNameMaker.makeName(userName, group);
		var fullMessage = chatMessageName + "<font color='#666666'>: " + messageText + "</font><br/>";
		displayMessage(fred ? '<i>' + fullMessage + '</i>' : fullMessage);
	}

	public function displayMessage(message:String):Void {
		messages++;
		if (messages > MAX_MESSAGES) {
			var firstBreak = existingMessages.indexOf("<br/>");
			existingMessages = firstBreak < 0 ? "" : existingMessages.substr(firstBreak + 5);
		}
		existingMessages += message;
		showMessages();
	}

	public function inputText():String {
		return chatInput == null ? "" : chatInput.text;
	}

	public function outputHtml():String {
		return topText == null ? "" : topText.htmlText;
	}

	public function inputHasFocus():Bool {
		return stage != null && chatInput != null && stage.focus == chatInput;
	}

	public function remove():Void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		removeStageListeners();
		if (art != null) {
			art.removeEventListener(MouseEvent.MOUSE_WHEEL, ensureBottom);
			art.dispose();
			art = null;
		}
		htmlNameMaker.remove();
		if (textBox == chatInput) {
			textBox = null;
		}
		chatInput = null;
		topText = null;
		bgText = null;
		sendHandler = null;
		if (parent != null) parent.removeChild(this);
	}

	private function onAddedToStage(_:Event):Void {
		if (stage == null || stageListenersActive) {
			return;
		}
		ownerStage = stage;
		ownerStage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		ownerStage.addEventListener(KeyboardEvent.KEY_DOWN, focusOrSend);
		stageListenersActive = true;
	}

	private function onRemovedFromStage(_:Event):Void {
		removeStageListeners();
	}

	private function removeStageListeners():Void {
		if (!stageListenersActive || ownerStage == null) {
			stageListenersActive = false;
			ownerStage = null;
			return;
		}
		ownerStage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		ownerStage.removeEventListener(KeyboardEvent.KEY_DOWN, focusOrSend);
		stageListenersActive = false;
		ownerStage = null;
	}

	private function mouseDownHandler(event:MouseEvent):Void {
		if (inputHasFocus() && event.target != this && event.target != chatInput) {
			focusOnRace();
		}
	}

	private function focusOrSend(event:KeyboardEvent):Void {
		if (event.keyCode != Keyboard.ENTER || chatInput == null || stage == null) {
			return;
		}
		if (event.target != this && event.target != chatInput) {
			stage.focus = chatInput;
			chatInput.setSelection(0, 0);
			return;
		}
		submitText(chatInput.text);
		focusOnRace();
	}

	private function focusOnRace():Void {
		if (stage != null) {
			stage.focus = stage;
		}
	}

	private function showMessages():Void {
		if (topText != null) topText.htmlText = existingMessages;
		if (bgText != null) bgText.htmlText = existingMessages;
		ensureBottom();
	}

	private function ensureBottom(?_:MouseEvent):Void {
		if (topText != null) topText.scrollV = topText.maxScrollV;
		if (bgText != null) bgText.scrollV = bgText.maxScrollV;
	}

	private static function stripForbidden(message:String):String {
		return message == null ? "" : StringTools.replace(message, "`", "");
	}
}
