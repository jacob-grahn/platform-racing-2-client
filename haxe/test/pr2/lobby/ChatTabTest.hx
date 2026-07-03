package pr2.lobby;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import pr2.lobby.dialogs.ChatRoomInfoPopup;
import pr2.lobby.tabs.ChatTab;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;

class ChatTabTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testChatRoomInfoPopupCommandLifecycle();
		testChatTabInfoHoverLifecycle();
		trace('ChatTabTest passed $assertions assertions');
	}

	private static function testChatRoomInfoPopupCommandLifecycle():Void {
		var handler = new CommandHandler();
		var target = new Sprite();
		LobbySocket.resetSent();

		var popup = new ChatRoomInfoPopup(target, handler);

		assertEquals("get_chat_rooms`", LobbySocket.lastSent(), "popup requests chat room list");
		assertEquals(true, handler.hasCommand("setChatRoomList"), "popup registers room-list command");
		assertEquals(true, @:privateAccess popup.loadingVisible(), "popup starts with loading graphic visible");
		handler.dispatch("setChatRoomList", ["main", "speed"]);
		assertEquals(false, @:privateAccess popup.loadingVisible(), "room list hides loading graphic");
		assertEquals('<font face="_sans" size="11">main</font><br/><font face="_sans" size="11">speed</font><br/>',
			@:privateAccess popup.renderedRoomHtml(), "room list preserves Flash _sans wrapper");

		popup.remove();
		assertEquals(false, handler.hasCommand("setChatRoomList"), "popup remove unregisters room-list command");
	}

	private static function testChatTabInfoHoverLifecycle():Void {
		CommandHandler.commandHandler.clearAll();
		LobbySocket.resetSent();
		var tab = new ChatTab();
		tab.initialize();
		var infoButton = @:privateAccess tab.infoButton;
		assertNotNull(infoButton, "chat tab mounts info button");

		infoButton.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertNotNull(@:privateAccess tab.infoPopup, "mouse over creates chat-room info popup");
		assertEquals(true, CommandHandler.commandHandler.hasCommand("setChatRoomList"), "hover popup registers room-list command");
		assertEquals("get_chat_rooms`", LobbySocket.lastSent(), "hover popup requests room list");
		CommandHandler.commandHandler.dispatch("setChatRoomList", ["main"]);
		assertEquals('<font face="_sans" size="11">main</font><br/>', @:privateAccess tab.infoPopup.renderedRoomHtml(),
			"hover popup renders returned room");

		infoButton.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals(null, @:privateAccess tab.infoPopup, "mouse out removes info popup");
		assertEquals(false, CommandHandler.commandHandler.hasCommand("setChatRoomList"), "mouse out unregisters room-list command");

		infoButton.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertNotNull(@:privateAccess tab.infoPopup, "hover can create a second popup");
		tab.remove();
		assertEquals(null, @:privateAccess tab.infoPopup, "tab remove clears active info popup");
		assertEquals(false, CommandHandler.commandHandler.hasCommand("setChatRoomList"), "tab remove unregisters room-list command");
		assertEquals("set_chat_room`none", LobbySocket.lastSent(), "tab remove leaves chat room");
		CommandHandler.commandHandler.clearAll();
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) throw '$message: value was null';
	}
}
