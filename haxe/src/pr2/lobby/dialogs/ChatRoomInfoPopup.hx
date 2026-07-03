package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class ChatRoomInfoPopup extends InfoPopup {
	private static inline var FONT_TAG:String = "<font face=\"_sans\" size=\"11\">";

	private var art:Null<PR2MovieClip>;
	private var textBox:Null<TextField>;
	private var loadingGraphic:Null<DisplayObject>;
	private var commandHandler:CommandHandler;
	private var roomHtml:String = "";

	public function new(target:DisplayObject, ?commandHandler:CommandHandler) {
		super();
		this.commandHandler = commandHandler != null ? commandHandler : CommandHandler.commandHandler;
		art = PR2MovieClip.fromLinkage("ChatRoomInfoPopupGraphic", {maxNestedDepth: 8});
		addChild(art);
		textBox = LobbyArt.text(art, "textBox");
		if (textBox != null) {
			textBox.htmlText = "";
		}
		loadingGraphic = DisplayUtil.findByName(art, "loadingGraphic");
		this.commandHandler.defineCommand("setChatRoomList", setChatRoomList);
		LobbySocket.write("get_chat_rooms`");
		positionNear(target);
	}

	public function setChatRoomList(rooms:Array<String>):Void {
		if (loadingGraphic != null) {
			loadingGraphic.visible = false;
		}
		for (room in rooms) {
			roomHtml += FONT_TAG + room + "</font><br/>";
		}
		if (textBox != null) {
			textBox.htmlText = roomHtml;
		}
	}

	@:allow(pr2.lobby.ChatTabTest)
	private function renderedRoomHtml():String {
		return roomHtml;
	}

	@:allow(pr2.lobby.ChatTabTest)
	private function loadingVisible():Bool {
		return loadingGraphic != null && loadingGraphic.visible;
	}

	override public function remove():Void {
		if (commandHandler != null) {
			commandHandler.defineCommand("setChatRoomList", null);
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		textBox = null;
		loadingGraphic = null;
		super.remove();
	}
}
