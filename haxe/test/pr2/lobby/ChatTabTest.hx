package pr2.lobby;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextFieldType;
import pr2.lobby.chat.ArtifactHintClient;
import pr2.lobby.dialogs.ChatRoomInfoPopup;
import pr2.lobby.tabs.ChatTab;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.net.ServerConfig;
import pr2.util.TestDisplayUtil as DisplayUtil;

class ChatTabTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testChatRoomInfoPopupCommandLifecycle();
		if (pr2.DeterministicTestMode.finishSmokeSuite("ChatTabTest")) return;
		testChatTabInfoHoverLifecycle();
		testArtifactHintCommandLifecycle();
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
		var art = findChatRoomInfoView(popup);
		assertNotNull(art, "chat room info popup mounts the typed authored view");
		assertEquals(-98.0, art.textArea.x, "chat room TextArea keeps its XFL X");
		assertEquals(-65.0, art.textArea.y, "chat room TextArea keeps its XFL Y");
		assertEquals(197.100830078125, art.textArea.controlWidth, "chat room TextArea keeps its XFL width");
		assertEquals(128.0, art.textArea.controlHeight, "chat room TextArea keeps its authored height");
		assertEquals(TextFieldType.INPUT, art.textBox.type, "chat room TextArea preserves the XFL editable state");
		handler.dispatch("setChatRoomList", ["main", "speed"]);
		assertEquals(false, @:privateAccess popup.loadingVisible(), "room list hides loading graphic");
		assertEquals('<font face="_sans" size="11">main</font><br/><font face="_sans" size="11">speed</font><br/>',
			@:privateAccess popup.renderedRoomHtml(), "room list preserves Flash _sans wrapper");

		popup.remove();
		assertEquals(false, handler.hasCommand("setChatRoomList"), "popup remove unregisters room-list command");
	}

	private static function findChatRoomInfoView(popup:ChatRoomInfoPopup):pr2.lobby.dialogs.ChatRoomInfoView {
		for (index in 0...popup.numChildren) {
			var view = Std.downcast(popup.getChildAt(index), pr2.lobby.dialogs.ChatRoomInfoView);
			if (view != null) return view;
		}
		return null;
	}

	private static function testChatTabInfoHoverLifecycle():Void {
		CommandHandler.commandHandler.clearAll();
		LobbySocket.resetSent();
		var tab = new ChatTab();
		tab.initialize();
		var view = @:privateAccess tab.art;
		assertClose(100 * 1.0001220703125, view.roomInput.controlWidth, "chat room input keeps XFL width");
		assertEquals(16, view.roomInput.maxChars, "chat room input keeps XFL maximum");
		assertEquals("^`", view.roomInput.restrict, "chat room input keeps XFL restriction");
		assertClose(103, DisplayUtil.findByName(view, "joinRoom_bt").x, "chat join button keeps XFL X");
		assertClose(100 * 0.660003662109375, DisplayUtil.findByName(view, "joinRoom_bt").width, "chat join button keeps XFL width");
		assertClose(175, DisplayUtil.findByName(view, "infoButton").x, "chat info button keeps XFL X");
		assertClose(25, view.transcriptArea.y, "chat transcript keeps XFL Y");
		assertClose(100 * 1.87985229492188, view.transcriptArea.controlWidth, "chat transcript keeps XFL width");
		assertClose(44 * 6.88603210449219, view.transcriptArea.controlHeight, "chat transcript keeps XFL height");
		assertClose(331 - 25 - 44 * 6.88603210449219,
			view.chatInputControl.y - view.transcriptArea.y - view.transcriptArea.controlHeight,
			"chat transcript reaches the input with the authored gap");
		assertEquals(TextFieldType.DYNAMIC, view.textBox.type, "chat transcript keeps XFL non-editable state");
		assertClose(331, view.chatInputControl.y, "chat input keeps XFL Y");
		assertClose(100 * 1.45013427734375, view.chatInputControl.controlWidth, "chat input keeps XFL width");
		assertEquals(150, view.chatInputControl.maxChars, "chat input keeps XFL maximum");
		assertClose(148, DisplayUtil.findByName(view, "send_bt").x, "chat send button keeps XFL X");
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

	private static function testArtifactHintCommandLifecycle():Void {
		CommandHandler.commandHandler.clearAll();
		LobbySocket.resetSent();
		ServerConfig.resetHost();
		ServerConfig.setHost("/api");
		var requestedUrl = "";
		var onJson:Null<Dynamic->Void> = null;
		ArtifactHintClient.getFactory = function(url:String, success:Dynamic->Void, onError:Null<String->Void>):Void {
			requestedUrl = url;
			onJson = success;
		};

		var tab = new ChatTab();
		tab.initialize();
		@:privateAccess tab.routeSend("/hint");
		assertEquals("/api/files/level_of_the_week.json", requestedUrl, "artifact command loads LOTW JSON");
		onJson({
			current: {
				level: {title: "Artifact Course", id: 44, author: {name: "Builder", group: "1"}}
			}
		});
		assertEquals(true, @:privateAccess tab.log.existingMessages.indexOf("Fred the G. Cactus") >= 0, "artifact hint renders Fred message");
		assertEquals(true, @:privateAccess tab.log.existingMessages.indexOf('event:level`44') >= 0, "artifact hint renders level link");
		tab.remove();

		var removedTab = new ChatTab();
		removedTab.initialize();
		@:privateAccess removedTab.routeSend("/arti");
		removedTab.remove();
		onJson({
			current: {
				level: {title: "Late Course", id: 45, author: {name: "Builder", group: "1"}}
			}
		});
		assertEquals("", @:privateAccess removedTab.log.existingMessages, "removed chat tab ignores late artifact response");

		ArtifactHintClient.resetHooksForTests();
		ServerConfig.resetHost();
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

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000001) throw '$message: expected $expected, got $actual';
	}
}
