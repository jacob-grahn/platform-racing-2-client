package pr2.lobby;

import pr2.lobby.LobbyLeft;
import pr2.lobby.LobbyRight;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.ui.TabLayout;
import pr2.ui.TabsHolder;

/**
	Deterministic coverage for the shared lobby services and tab logic that don't
	need real display art: tab overlap math, remembered tab restoration, the
	socket command recorder, the command dispatcher, and session guest/member
	state.
**/
class LobbyServicesTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testTabLayoutNoCompression();
		testTabLayoutCompression();
		testTabLayoutSingleTab();
		testTabMemory();
		testPaneTabLabels();
		testSessionGuestMember();
		testSocketRecording();
		testCommandDispatch();
		testMemoryAndSecureData();
		trace('LobbyServicesTest passed $assertions assertions');
	}

	private static function testTabLayoutNoCompression():Void {
		// Row narrower than the pane: tabs stay at their cumulative offsets.
		var xs = TabLayout.positions([40, 50, 30], 200);
		assertEquals(0.0, xs[0], "first tab x");
		assertEquals(40.0, xs[1], "second tab x");
		assertEquals(90.0, xs[2], "third tab x");
	}

	private static function testTabLayoutCompression():Void {
		// total = 120, maxW = 90 -> overflow 30 split across (n-1)=2 => tabW = 15.
		// tab[1] -= 15*1, tab[2] -= 15*2.
		var xs = TabLayout.positions([40, 40, 40], 90);
		assertEquals(0.0, xs[0], "compressed first x");
		assertEquals(25.0, xs[1], "compressed second x");
		assertEquals(50.0, xs[2], "compressed third x");
	}

	private static function testTabLayoutSingleTab():Void {
		// One tab wider than the pane must not divide by zero.
		var xs = TabLayout.positions([300], 100);
		assertEquals(1, xs.length, "single tab count");
		assertEquals(0.0, xs[0], "single tab x");
	}

	private static function testTabMemory():Void {
		TabsHolder.clearMemory();
		// No memory yet: falls back to the supplied default.
		assertEquals(2, TabsHolder.resolveSelected("lobbyLeft", 2, 4), "default selected");
		TabsHolder.setLastTab("lobbyLeft", 1);
		assertEquals(1, TabsHolder.resolveSelected("lobbyLeft", 2, 4), "remembered selected");
		// Remembered index out of range for a smaller tab set falls back.
		assertEquals(0, TabsHolder.resolveSelected("lobbyLeft", 0, 1), "stale memory ignored");
		TabsHolder.clearMemory();
	}

	private static function testPaneTabLabels():Void {
		// Members see PMs (left) and Favorites (right); guests don't.
		var leftMember = LobbyLeft.tabLabels(2);
		assertEquals(4, leftMember.length, "member left tab count");
		assertEquals("PMs", leftMember[1], "member left has PMs");
		var leftGuest = LobbyLeft.tabLabels(0);
		assertEquals(3, leftGuest.length, "guest left tab count");
		assertEquals("Players", leftGuest[1], "guest left drops PMs");

		var rightMember = LobbyRight.tabLabels(1);
		assertEquals(6, rightMember.length, "member right tab count");
		assertEquals("♥", rightMember[5], "member right has favorites");
		var rightGuest = LobbyRight.tabLabels(0);
		assertEquals(5, rightGuest.length, "guest right tab count");
		assertEquals("Campaign", rightGuest[0], "right defaults to campaign");
	}

	private static function testSessionGuestMember():Void {
		LobbySession.clear();
		assertEquals(true, LobbySession.isGuest(), "fresh session is guest");
		assertEquals(false, LobbySession.isMember(), "guest is not member");
		LobbySession.begin("Jiggmin", 3, null, 1, true);
		assertEquals(true, LobbySession.isMember(), "logged-in is member");
		assertEquals("Jiggmin", LobbySession.userName, "user name set");
		assertEquals(true, LobbySession.remember, "remember flag set");
		var fired = 0;
		var listener = function():Void {
			fired++;
		};
		LobbySession.onAccountChange(listener);
		LobbySession.notifyAccountChange();
		assertEquals(1, fired, "account change fired");
		LobbySession.clear();
	}

	private static function testSocketRecording():Void {
		LobbySocket.resetSent();
		LobbySocket.write("set_chat_room`main");
		LobbySocket.write("set_right_room`none");
		assertEquals(2, LobbySocket.sentCommands.length, "two commands recorded");
		assertEquals("set_right_room`none", LobbySocket.lastSent(), "last command");
		LobbySocket.resetSent();
		assertEquals(0, LobbySocket.sentCommands.length, "reset clears recorder");
	}

	private static function testCommandDispatch():Void {
		var handler = new CommandHandler();
		var captured:Array<String> = null;
		handler.defineCommand("setChatRoomList", function(args):Void {
			captured = args;
		});
		// Server layout: hash`num`command`arg1`arg2`
		var handled = handler.handleServerFrame("abc`5`setChatRoomList`main`speed`");
		assertEquals(true, handled, "frame handled");
		assertEquals("main", captured[0], "first arg parsed");
		assertEquals("speed", captured[1], "second arg parsed");
		handler.defineCommand("setChatRoomList", null);
		assertEquals(false, handler.handleServerFrame("abc`6`setChatRoomList`x`"), "cleared command ignored");
	}

	private static function testMemoryAndSecureData():Void {
		Memory.clear();
		assertEquals(7, Memory.getInt("coursePageNum1", 7), "memory default int");
		Memory.set("coursePageNum1", 3);
		assertEquals(3, Memory.getInt("coursePageNum1", 7), "memory stored int");
		SecureData.clear();
		assertEquals(0.0, SecureData.getNumber("userRank"), "secure default");
		SecureData.setNumber("userRank", 5);
		assertEquals(5.0, SecureData.getNumber("userRank"), "secure stored");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
