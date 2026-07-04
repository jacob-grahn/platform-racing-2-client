package pr2.net;

import pr2.lobby.LobbySession;
import pr2.lobby.Memory;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.messages.UnreadNotif;

class LobbySocketLifecycleTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testPingIntervalAndSend();
		testReceivePingSyncsServerTime();
		testCloseSendsFlashCloseAndClearsSessionState();
		testTransportCloseAndErrorPopups();
		closeAll();
		trace('LobbySocketLifecycleTest passed $assertions assertions');
	}

	private static function testPingIntervalAndSend():Void {
		resetSocket();
		LobbySocket.simulateOpenForTests();
		assertEquals(true, LobbySocket.pingIsActiveForTests(), "open starts ping interval");
		LobbySocket.sendPing();
		assertEquals("ping`", LobbySocket.lastSent(), "sendPing emits Flash ping command");
		LobbySocket.close();
		assertEquals(false, LobbySocket.pingIsActiveForTests(), "close stops ping interval");
	}

	private static function testReceivePingSyncsServerTime():Void {
		resetSocket();
		LobbySocket.nowMs = function():Float return 100000;
		LobbySocket.receivePing(["101"]);
		assertEquals(100000.0, LobbySocket.getMS(), "small ping drift leaves local clock");
		LobbySocket.receivePing(["130"]);
		assertEquals(130000.0, LobbySocket.getMS(), "large ping drift updates server clock offset");
		assertEquals(130.0, LobbySocket.getTimestamp(), "socket exposes server timestamp");

		LobbySocket.nowMs = function():Float return 200000;
		var handler = new CommandHandler();
		assertEquals(true, handler.handleServerFrame(CommandHandler.buildServerFrame(1, "ping", ["250"])), "ping frame handled");
		assertEquals(250000.0, LobbySocket.getMS(), "default ping command updates socket server clock");
		LobbySocket.receivePing(["172800"]);
		assertEquals(2.0, LobbySocket.getDay(), "socket exposes server day");
	}

	private static function testCloseSendsFlashCloseAndClearsSessionState():Void {
		resetSocket();
		Memory.set("coursePageNumcampaign", 4);
		Memory.set("campaignInfo2", ["cached"]);
		LobbySocket.campaignPage = 2;
		LobbySession.isSpecialUser = true;
		LobbySession.isPrizer = true;
		LobbySession.isTempMod = true;
		LobbySession.isTrialMod = true;
		LobbySession.tournamentMode = true;
		LobbySession.serverOwner = 7;
		UnreadNotif.setLastRead(0);
		UnreadNotif.notifyUser(99);
		CommandHandler.commandHandler.sendNum = 42;
		LobbySocket.simulateOpenForTests();
		LobbySocket.write("noop`");

		LobbySocket.close();

		assertEquals("close`", LobbySocket.lastSent(), "close writes Flash close command before disconnect");
		assertEquals(0, LobbySocket.sendNum, "close resets socket send counter");
		assertEquals(-1, CommandHandler.commandHandler.sendNum, "close resets received command counter");
		assertEquals(false, Memory.has("coursePageNumcampaign"), "close clears campaign page cache");
		assertEquals(false, Memory.has("campaignInfo2"), "close clears current campaign info cache");
		assertEquals(false, LobbySession.isSpecialUser, "close clears special user flag");
		assertEquals(false, LobbySession.isPrizer, "close clears prizer flag");
		assertEquals(false, LobbySession.isTempMod, "close clears temp mod flag");
		assertEquals(false, LobbySession.isTrialMod, "close clears trial mod flag");
		assertEquals(false, LobbySession.tournamentMode, "close clears tournament mode");
		assertEquals(0, LobbySession.serverOwner, "close clears server owner");
		assertEquals(0, UnreadNotif.numUnread(), "close resets unread PM notifications");
	}

	private static function testTransportCloseAndErrorPopups():Void {
		resetSocket();
		closeAll();
		LobbySocket.simulateOpenForTests();
		LobbySocket.simulateConnectionCloseForTests();
		assertMessageContains("Disconnected.", "transport close opens Flash disconnected popup");
		assertEquals(false, LobbySocket.pingIsActiveForTests(), "transport close stops ping interval");

		resetSocket();
		closeAll();
		LobbySocket.simulateOpenForTests();
		LobbySocket.simulateConnectionErrorForTests();
		assertMessageContains("Could not connect.", "transport error opens Flash connection popup");
		assertEquals(false, LobbySocket.pingIsActiveForTests(), "transport error stops ping interval");
	}

	private static function resetSocket():Void {
		closeAll();
		LobbySocket.onOpen = null;
		LobbySocket.onFrame = null;
		LobbySocket.onConnectionClose = null;
		LobbySocket.onConnectionError = null;
		LobbySocket.resetSent();
		LobbySocket.campaignPage = 0;
		Memory.clear();
		LobbySession.clear();
		UnreadNotif.reset();
	}

	private static function assertMessageContains(needle:String, message:String):Void {
		var popup = Std.downcast(Popup.getOpen()[Popup.getOpen().length - 1], MessagePopup);
		assertNotNull(popup, message);
		var text = pr2.lobby.LobbyArt.text(popup, "textBox");
		assertNotNull(text, '$message text');
		assertContains(text.htmlText, needle, message);
	}

	private static function closeAll():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}

	private static function assertContains(value:String, needle:String, message:String):Void {
		assertions++;
		if (value.indexOf(needle) < 0) throw '$message: missing $needle in $value';
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
