package pr2.gameplay;

import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import openfl.ui.Keyboard;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyPopups;
import pr2.lobby.chat.ArtifactHintClient;
import pr2.lobby.chat.ChatLog;
import pr2.lobby.chat.ChatText;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.net.LobbySocket;

/**
	Port of Flash `gameplay.RaceChat` around the authored `RaceChatGraphic`.
**/
class RaceChat extends Sprite {
	public static var textBox:Null<TextField>;

	private static inline final MAX_MESSAGES:Int = 7;

	private var art:Null<RaceChatView>;
	private var chatInput:Null<TextField>;
	private var topText:Null<TextField>;
	private var bgText:Null<TextField>;
	private var existingMessages:String = "";
	private var messages:Int = 0;
	private var htmlNameMaker:HtmlNameMaker = new HtmlNameMaker();
	private var sendHandler:Null<String->Bool>;
	private var stageListenersActive:Bool = false;
	private var ownerStage:Null<Stage>;
	private var artifactHintGeneration:Int = 0;
	private var removed:Bool = false;

	public function new(?sendHandler:String->Bool) {
		super();
		this.sendHandler = sendHandler;
		art = new RaceChatView();
		addChild(art);

		chatInput = art.chatInput;
		topText = art.topText;
		bgText = art.bgText;

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
		if (sendHandler != null && sendHandler(cleaned)) {
			return true;
		}
		routeSend(cleaned);
		return true;
	}

	public function receiveSystemMessage(message:String):Void {
		// The command channel is trusted HTML in the Flash client. In particular,
		// server-authored links must remain clickable here.
		displayMessage("<i><font color='#3E8697'>" + message + "</font></i><br/>");
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

	/** Flash ignores the global race-chat Enter shortcut while a PM TextArea is
		editing. Native popups use multiline input TextFields for the same role. */
	public static function isMultilineInputTarget(target:Dynamic):Bool {
		var field = Std.downcast(target, TextField);
		return field != null && field.type == TextFieldType.INPUT && field.multiline;
	}

	public function transcriptScroll():Array<Int> {
		return topText == null || bgText == null
			? []
			: [topText.scrollV, topText.maxScrollV, bgText.scrollV, bgText.maxScrollV];
	}

	/** Exact XFL metrics, exposed for deterministic parity coverage. */
	public function authoredGeometry():Array<Float> {
		if (art == null) return [];
		return [
			art.chatInput.x,
			art.chatInput.y,
			art.chatInput.width,
			art.chatInput.height,
			art.topText.x,
			art.topText.y,
			art.topText.width,
			art.topText.height,
			art.bgText.x + art.bgText.parent.x,
			art.bgText.y + art.bgText.parent.y,
			art.chatInput.scaleY,
			art.topText.scaleY,
			art.bgText.scaleY,
			art.bgText.parent.scaleY,
			art.getChildIndex(art.chatInput),
			art.getChildIndex(art.bgText.parent),
			art.getChildIndex(art.topText.parent)
		];
	}

	public function remove():Void {
		removed = true;
		artifactHintGeneration++;
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
		if (event.keyCode != Keyboard.ENTER || chatInput == null || stage == null || isMultilineInputTarget(event.target)) {
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
			if (removed || generation != artifactHintGeneration) {
				return;
			}
			for (message in ArtifactHintClient.fredMessages(data, htmlNameMaker)) {
				receiveChatMessage("Fred the G. Cactus", "3,*", message, true);
			}
		}, function(_:String):Void {});
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

private class RaceChatView extends Sprite {
	public static inline final OUTPUT_X:Float = 2;
	public static inline final OUTPUT_Y:Float = 2;
	public static inline final OUTPUT_WIDTH:Float = 141;
	public static inline final OUTPUT_HEIGHT:Float = 116.05;
	public static inline final INPUT_X:Float = 45;
	public static inline final INPUT_Y:Float = 129.7;
	public static inline final INPUT_WIDTH:Float = 100;
	public static inline final INPUT_HEIGHT:Float = 14.55;

	public final chatInput:TextField;
	public final topText:TextField;
	public final bgText:TextField;

	public function new() {
		super();
		// RaceChatGraphic is intentionally transparent. Its authored XFL contains
		// two offset transcript fields, the input border, and the two-color Chat:
		// label; the level remains visible behind it.
		bgText = makeOutput("textBox2", OUTPUT_X, OUTPUT_Y, OUTPUT_WIDTH, 116, 0x808080);
		var bg = new Sprite();
		bg.name = "bg";
		bg.x = 1;
		bg.y = 1;
		bg.scaleY = 1.00079345703125;
		bg.addChild(bgText);
		topText = makeOutput("textBox1", OUTPUT_X, OUTPUT_Y, OUTPUT_WIDTH, OUTPUT_HEIGHT, 0x000000);
		var top = new Sprite();
		top.name = "top";
		top.addChild(topText);

		var whiteLabel = makeLabel(5, 130.9, 0xFFFFFF);
		var blackLabel = makeLabel(4, 129.9, 0x000000);

		chatInput = new TextField();
		chatInput.name = "chatInput";
		chatInput.x = INPUT_X;
		chatInput.y = INPUT_Y;
		chatInput.width = INPUT_WIDTH;
		chatInput.height = INPUT_HEIGHT;
		chatInput.type = openfl.text.TextFieldType.INPUT;
		chatInput.border = true;
		chatInput.maxChars = 100;
		chatInput.scaleY = 0.999664306640625;
		chatInput.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0x000000);

		// Animate lists layers from top to bottom. Add them in reverse display-list
		// order so the XFL's transcript/color-shadow layering remains exact.
		addChild(whiteLabel);
		addChild(chatInput);
		addChild(blackLabel);
		addChild(bg);
		addChild(top);
	}

	private static function makeOutput(name:String, x:Float, y:Float, width:Float, height:Float, color:Int):TextField {
		var field = new TextField();
		field.name = name;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.scaleY = 0.999664306640625;
		field.multiline = true;
		field.wordWrap = false;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, color);
		return field;
	}

	private static function makeLabel(x:Float, y:Float, color:Int):TextField {
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = 33.4;
		field.height = 14.55;
		field.scaleY = 0.999664306640625;
		field.selectable = false;
		field.mouseEnabled = false;
		field.alpha = 0.498039215686275;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, color);
		field.text = "Chat:";
		return field;
	}

	public function dispose():Void {
		if (parent != null) parent.removeChild(this);
	}
}
