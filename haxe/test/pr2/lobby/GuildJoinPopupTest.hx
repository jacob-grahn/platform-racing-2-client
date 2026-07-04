package pr2.lobby;

import pr2.lobby.dialogs.GuildJoinPopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.net.ServerConfig;

class GuildJoinPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var savedPostFactory = UploadingPopup.postFactory;
		var savedGuildId = LobbySession.guildId;
		var savedGuildName = LobbySession.guildName;
		var savedEmblem = LobbySession.emblem;
		var savedGuildOwner = LobbySession.guildOwner;
		ServerConfig.setHost("http://example.test");
		closeAll();

		var accountChanges = 0;
		var listener = function():Void accountChanges++;
		LobbySession.onAccountChange(listener);
		var posts:Array<{url:String, fields:Map<String, String>}> = [];
		UploadingPopup.postFactory = function(url:String, fields:Map<String, String>, onResult:String->Void, onError:String->Void):Void {
			posts.push({url: url, fields: fields});
			onResult('{"guild_id":42,"guild_name":"Invited","emblem":"invite.png"}');
		};

		LobbyPopups.lastRequest = "sentinel";
		LobbyPopups.showGuildJoin(42);
		var open = Popup.getOpen();
		var popup = Std.downcast(open[open.length - 1], GuildJoinPopup);
		assertNotNull(popup, "invite route opens GuildJoinPopup");
		assertEquals("invite:42", LobbyPopups.lastRequest, "invite route records request");
		assertEquals(1, posts.length, "guild join posts once");
		assertEquals(ServerConfig.guildJoinUrl(), posts[0].url, "guild join endpoint");
		assertEquals("42", posts[0].fields.get("guild_id"), "guild join posts guild id");
		assertEquals("Joining guild...", LobbyArt.text(popup, "textBox").text, "guild join upload label");
		assertEquals(42, LobbySession.guildId, "guild join updates session guild id");
		assertEquals("Invited", LobbySession.guildName, "guild join updates session guild name");
		assertEquals("invite.png", LobbySession.emblem, "guild join updates session emblem");
		assertEquals(false, LobbySession.guildOwner, "guild join clears owner flag");
		assertEquals(1, accountChanges, "guild join dispatches account change");

		LobbySession.offAccountChange(listener);
		UploadingPopup.postFactory = savedPostFactory;
		LobbySession.guildId = savedGuildId;
		LobbySession.guildName = savedGuildName;
		LobbySession.emblem = savedEmblem;
		LobbySession.guildOwner = savedGuildOwner;
		ServerConfig.resetHost();
		closeAll();
		trace('GuildJoinPopupTest passed $assertions assertions');
	}

	private static function closeAll():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) throw message;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
