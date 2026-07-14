package pr2.lobby;

class LobbySessionTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testAccountStateDispatch();
		if (pr2.DeterministicTestMode.finishSmokeSuite("LobbySessionTest")) return;
		testGuildStateHelpers();
		testRememberMeAccountGate();
		LobbySession.clear();
		trace('LobbySessionTest passed $assertions assertions');
	}

	private static function testAccountStateDispatch():Void {
		LobbySession.clear();
		var changes = 0;
		var listener = function():Void changes++;
		LobbySession.onAccountChange(listener);
		LobbySession.updateAccountState(true, "tok");
		assertEquals(true, LobbySession.hasEmail, "account helper updates email flag");
		assertEquals("tok", LobbySession.token, "account helper updates token");
		assertEquals(1, changes, "account helper dispatches by default");

		LobbySession.updateAccountState(false, "silent", false);
		assertEquals(false, LobbySession.hasEmail, "silent account helper still updates email flag");
		assertEquals("silent", LobbySession.token, "silent account helper still updates token");
		assertEquals(1, changes, "silent account helper skips dispatch");
		LobbySession.offAccountChange(listener);
	}

	private static function testGuildStateHelpers():Void {
		LobbySession.clear();
		var changes = 0;
		LobbySession.onAccountChange(function():Void changes++);
		LobbySession.updateGuildFromData({
			guild_id: "42",
			guild_name: "Racers",
			is_owner: "1",
			emblem: "racing.png"
		});
		assertEquals(42, LobbySession.guildId, "guild data helper parses id");
		assertEquals("Racers", LobbySession.guildName, "guild data helper parses name");
		assertEquals(true, LobbySession.guildOwner, "guild data helper parses owner");
		assertEquals("racing.png", LobbySession.emblem, "guild data helper updates emblem");
		assertEquals(1, changes, "guild data helper dispatches");

		LobbySession.updateGuildFromData({guild_id: 9, guild_name: "Socket", is_owner: false}, null, true, false);
		assertEquals(9, LobbySession.guildId, "socket guild helper parses id");
		assertEquals("Socket", LobbySession.guildName, "socket guild helper parses name");
		assertEquals(false, LobbySession.guildOwner, "socket guild helper parses owner");
		assertEquals("racing.png", LobbySession.emblem, "socket guild helper can preserve emblem");
		assertEquals(2, changes, "socket guild helper dispatches");

		LobbySession.clearGuild(false);
		assertEquals(0, LobbySession.guildId, "clear guild resets id");
		assertEquals("", LobbySession.guildName, "clear guild resets name");
		assertEquals(false, LobbySession.guildOwner, "clear guild resets owner");
		assertEquals("", LobbySession.emblem, "clear guild resets emblem");
		assertEquals(2, changes, "silent clear guild skips dispatch");
	}

	private static function testRememberMeAccountGate():Void {
		LobbySession.clear();
		LobbySession.remember = false;
		assertEquals(false, LobbySession.canUseRememberMeAccountAction(), "remember-me action blocked when not remembered");
		LobbySession.remember = true;
		assertEquals(true, LobbySession.canUseRememberMeAccountAction(), "remember-me action allowed when remembered");
		assertEquals("Psst... I won't work if you're not logged in with remember me. Log back in with remember me enabled and click me again! :)",
			LobbySession.REMEMBER_ME_REQUIRED_COPY, "remember-me account copy centralized");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
