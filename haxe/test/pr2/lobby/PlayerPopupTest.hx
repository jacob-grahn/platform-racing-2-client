package pr2.lobby;

import openfl.events.MouseEvent;
import pr2.lobby.dialogs.PlayerGuestPopup;
import pr2.lobby.dialogs.PlayerPopup;
import pr2.lobby.dialogs.Popup;
import pr2.runtime.FlButton;

/**
	Verifies that clicking a chat name brings up the player info popup the way the
	Flash `dialogs.PlayerPopup` did: member data fills the authored fields and
	toggles the social-button labels, guest data hands off to `PlayerGuestPopup`,
	and the `LobbyPopups` chat-link entry points open the right popup.
**/
class PlayerPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var savedGroup = LobbySession.group;

		testMemberRender();
		testGuestHandoff();
		testChatLinkEntryPoints();
		testGuestButtonsDisabled();

		LobbySession.group = savedGroup;
		closeAll();
		trace('PlayerPopupTest passed $assertions assertions');
	}

	private static function testMemberRender():Void {
		LobbySession.group = 1;
		var popup = new PlayerPopup("Jiggmin", false);
		popup.applyReturnData({
			userId: 5, group: 1, status: "online", rank: 24, hats: "3",
			registerDate: 0, loginDate: 1363478400, guildId: 0,
			hat: 1, head: 1, body: 1, feet: 1,
			following: 0, friend: 1, ignored: 0,
			verified: true, hof: false, exp_points: 10, exp_to_rank: 100
		});

		assertEquals("-- Jiggmin --", LobbyArt.text(popup, "nameBox").text, "name header shows the player");
		assertEquals("online", LobbyArt.text(popup, "statusBox").text, "status fills");
		assertEquals("Member", LobbyArt.text(popup, "groupBox").text, "group 1 is Member");
		assertEquals("24", LobbyArt.text(popup, "rankBox").text, "rank fills");
		assertEquals("Age of Heroes", LobbyArt.text(popup, "registerBox").text, "registerDate 0 is Age of Heroes");
		assertEquals("none", LobbyArt.text(popup, "guildBox").text, "guildless shows none");

		assertEquals("Follow", flLabel(popup, "followButton"), "not following => Follow");
		assertEquals("Remove Friend", flLabel(popup, "friendButton"), "already a friend => Remove Friend");
		assertEquals("Ignore", flLabel(popup, "ignoreButton"), "not ignored => Ignore");
		assertEquals(true, flButton(popup, "followButton").enabled, "members can follow");
		assertEquals(true, LobbyArt.findByName(popup, "playerInfo").visible, "info panel becomes visible");

		popup.remove();
	}

	private static function testGuestHandoff():Void {
		LobbySession.group = 1;
		closeAll();
		var popup = new PlayerPopup("SomeGuest", false);
		popup.applyReturnData({userId: 0, group: 0});
		assertEquals(true, popup.fadeOutStarted, "guest data fades out the member popup");
		var open = Popup.getOpen();
		assertNotNull(Std.downcast(open[open.length - 1], PlayerGuestPopup), "guest data hands off to PlayerGuestPopup");
		closeAll();
	}

	private static function testChatLinkEntryPoints():Void {
		LobbySession.group = 1;
		closeAll();
		LobbyPopups.lastRequest = "sentinel";
		LobbyPopups.showGuestPlayer("Anon");
		var open = Popup.getOpen();
		var guest = Std.downcast(open[open.length - 1], PlayerGuestPopup);
		assertNotNull(guest, "showGuestPlayer opens a PlayerGuestPopup");
		assertEquals("-- Anon --", LobbyArt.text(guest, "nameBox").text, "guest popup shows the name");
		assertEquals("sentinel", LobbyPopups.lastRequest, "guest popup route is no longer record-only");

		// A member chat link opens the full popup (which then loads asynchronously).
		LobbyPopups.showPlayer("Member");
		open = Popup.getOpen();
		assertNotNull(Std.downcast(open[open.length - 1], PlayerPopup), "showPlayer opens a PlayerPopup");
		assertEquals("sentinel", LobbyPopups.lastRequest, "player popup route is no longer record-only");
		closeAll();
	}

	private static function testGuestButtonsDisabled():Void {
		LobbySession.group = 0;
		closeAll();
		var popup = new PlayerPopup("Target", false);
		popup.applyReturnData({
			userId: 7, group: 1, status: "", rank: 1, hats: "0",
			registerDate: 1363478400, loginDate: 1363478400, guildId: 0,
			hat: 1, head: 1, body: 1, feet: 1,
			following: 1, friend: 0, ignored: 1
		});
		assertEquals("Unfollow", flLabel(popup, "followButton"), "following => Unfollow");
		assertEquals("Unignore", flLabel(popup, "ignoreButton"), "ignored => Unignore");
		assertEquals(false, flButton(popup, "followButton").enabled, "guests cannot follow");
		assertEquals(false, flButton(popup, "ignoreButton").enabled, "guests cannot ignore");
		popup.remove();
	}

	private static function flButton(popup:PlayerPopup, name:String):FlButton {
		var button = Std.downcast(LobbyArt.findByName(popup, name), FlButton);
		if (button == null) throw name + " is not an FlButton";
		return button;
	}

	private static function flLabel(popup:PlayerPopup, name:String):String {
		return flButton(popup, name).label;
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
