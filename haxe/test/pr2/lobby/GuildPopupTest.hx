package pr2.lobby;

import openfl.events.KeyboardEvent;
import pr2.app.AppStage;
import pr2.lobby.dialogs.GuildPopup;
import pr2.lobby.dialogs.Popup;

/**
	Verifies the authored guild popup path used by chat/profile guild links:
	guild data fills the Flash fields, member rows render with linked names, guild
	members get the PM Everyone button, and Shift toggles the title to the guild id.
**/
class GuildPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var savedGroup = LobbySession.group;
		var savedGuildId = LobbySession.guildId;
		var savedTrialMod = LobbySession.isTrialMod;

		testRenderNonMember();
		testMemberEntryPointAndShiftToggle();

		LobbySession.group = savedGroup;
		LobbySession.guildId = savedGuildId;
		LobbySession.isTrialMod = savedTrialMod;
		closeAll();
		trace('GuildPopupTest passed $assertions assertions');
	}

	private static function testRenderNonMember():Void {
		LobbySession.group = 1;
		LobbySession.guildId = 0;
		LobbySession.isTrialMod = false;
		var popup = new GuildPopup(9, "", false);
		popup.applyReturnData(sampleData());

		assertEquals("-- Racers --", LobbyArt.text(popup, "titleBox").text, "title header shows the guild");
		assertEquals(true, hasText(popup, "GP Today: 1,234"), "GP today is formatted");
		assertEquals(true, hasText(popup, "GP Total: 98,765"), "GP total is formatted");
		assertEquals("Members: 2 (1 active)", LobbyArt.text(popup, "membersCount").text, "member count fills");
		assertEquals("Fast only", LobbyArt.text(popup, "guildProse").text, "guild note fills");
		assertEquals(false, LobbyArt.findByName(popup, "messageButton") != null, "non-members do not get PM Everyone");
		assertEquals(true, LobbyArt.text(popup, "nameBox").htmlText.indexOf("Jiggmin") >= 0, "member row uses linked name");

		popup.remove();
	}

	private static function testMemberEntryPointAndShiftToggle():Void {
		LobbySession.group = 3;
		LobbySession.guildId = 9;
		LobbySession.isTrialMod = false;
		closeAll();
		LobbyPopups.showGuild(9);
		var popup = Std.downcast(Popup.getOpen()[Popup.getOpen().length - 1], GuildPopup);
		assertNotNull(popup, "showGuild opens a GuildPopup");
		popup.applyReturnData(sampleData());
		assertEquals(true, LobbyArt.findByName(popup, "messageButton") != null, "members get PM Everyone");
		assertEquals(true, LobbyArt.findByName(popup, "delete_bt").visible, "admins see delete");

		if (AppStage.stage != null) {
			AppStage.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, 16));
			assertEquals("-- Guild ID: 9 --", LobbyArt.text(popup, "titleBox").text, "Shift shows guild id");
			AppStage.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, 16));
			assertEquals("-- Racers --", LobbyArt.text(popup, "titleBox").text, "Shift toggles back to name");
		}
		closeAll();
	}

	private static function sampleData():Dynamic {
		return {
			guild: {
				guild_id: 9, owner_id: 5, guild_name: "Racers",
				gp_today: 1234, gp_total: 98765,
				member_count: 2, active_count: 1, note: "Fast only"
			},
			members: [
				{name: "Jiggmin", group: "1", user_id: 5, gp_today: 1000, gp_total: 90000},
				{name: "Guest", group: "0", user_id: 6, gp_today: 234, gp_total: 8765}
			]
		};
	}

	private static function closeAll():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}

	private static function hasText(popup:Popup, expected:String):Bool {
		for (field in LobbyArt.textFields(popup)) {
			if (field.text == expected) return true;
		}
		return false;
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
