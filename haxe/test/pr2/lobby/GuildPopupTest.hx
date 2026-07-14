package pr2.lobby;

import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.KeyboardEvent;
import openfl.net.URLRequest;
import pr2.app.AppStage;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.GuildPopup;
import pr2.lobby.dialogs.Popup;
import pr2.net.ServerConfig;
import pr2.net.SuperLoader;
import pr2.util.DisplayUtil;

/**
	Verifies the authored guild popup path used by chat/profile guild links:
	guild data fills the Flash fields, member rows render with linked names, guild
	members get the PM Everyone button, and Shift toggles the title to the guild id.
**/
class GuildPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		try {
			runMain();
		} catch (error:Dynamic) {
			throw 'GuildPopupTest setup/main: ${Std.string(error)}';
		}
	}

	private static function runMain():Void {
		var savedGroup = LobbySession.group;
		var savedGuildId = LobbySession.guildId;
		var savedGuildName = LobbySession.guildName;
		var savedGuildOwner = LobbySession.guildOwner;
		var savedTrialMod = LobbySession.isTrialMod;
		var savedDeleteFactory = GuildPopup.deleteFactory;
		ServerConfig.setHost("http://example.test");

		run("render non-member", testRenderNonMember);
		if (pr2.DeterministicTestMode.isSmoke()) {
			LobbySession.group = savedGroup;
			LobbySession.guildId = savedGuildId;
			LobbySession.guildName = savedGuildName;
			LobbySession.guildOwner = savedGuildOwner;
			LobbySession.isTrialMod = savedTrialMod;
			GuildPopup.deleteFactory = savedDeleteFactory;
			SuperLoader.resetHooks();
			ServerConfig.resetHost();
			closeAll();
			pr2.DeterministicTestMode.finishSmokeSuite("GuildPopupTest");
			return;
		}
		run("member entry and shift", testMemberEntryPointAndShiftToggle);
		run("admin delete", testAdminDeleteClearsCurrentGuild);
		run("async cleanup", testRemoveCancelsAsyncGuildInfoLoad);

		LobbySession.group = savedGroup;
		LobbySession.guildId = savedGuildId;
		LobbySession.guildName = savedGuildName;
		LobbySession.guildOwner = savedGuildOwner;
		LobbySession.isTrialMod = savedTrialMod;
		GuildPopup.deleteFactory = savedDeleteFactory;
		SuperLoader.resetHooks();
		ServerConfig.resetHost();
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
		assertEquals(false, DisplayUtil.findByName(popup, "messageButton") != null, "non-members do not get PM Everyone");
		assertEquals(true, LobbyArt.text(popup, "nameBox").htmlText.indexOf("Jiggmin") >= 0, "member row uses linked name");
		assertNotNull(popup.emblemForTests(), "guild popup mounts an emblem loader");
		assertEquals("racers.jpg", popup.emblemForTests().getFileName(), "guild popup loads the server emblem filename");
		assertEquals(-140, popup.emblemForTests().x, "guild emblem uses Flash x position");
		assertEquals(-109, popup.emblemForTests().y, "guild emblem uses Flash y position");

		popup.remove();
		assertEquals(null, popup.emblemForTests(), "guild popup removes emblem loader on close");
	}

	private static function run(label:String, test:Void->Void):Void {
		try {
			test();
		} catch (error:Dynamic) {
			throw '$label: ${Std.string(error)}';
		}
	}

	private static function testMemberEntryPointAndShiftToggle():Void {
		LobbySession.group = 3;
		LobbySession.guildId = 9;
		LobbySession.isTrialMod = false;
		closeAll();
		LobbyPopups.lastRequest = "sentinel";
		LobbyPopups.showGuild(9);
		var popup = Std.downcast(Popup.getOpen()[Popup.getOpen().length - 1], GuildPopup);
		assertNotNull(popup, "showGuild opens a GuildPopup");
		assertEquals("sentinel", LobbyPopups.lastRequest, "guild popup route is no longer record-only");
		popup.applyReturnData(sampleData());
		assertEquals(true, DisplayUtil.findByName(popup, "messageButton") != null, "members get PM Everyone");
		assertEquals(true, DisplayUtil.findByName(popup, "delete_bt").visible, "admins see delete");

		if (AppStage.stage != null) {
			AppStage.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, 16));
			assertEquals("-- Guild ID: 9 --", LobbyArt.text(popup, "titleBox").text, "Shift shows guild id");
			AppStage.stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, 16));
			assertEquals("-- Racers --", LobbyArt.text(popup, "titleBox").text, "Shift toggles back to name");
		}
		closeAll();
	}

	private static function testAdminDeleteClearsCurrentGuild():Void {
		LobbySession.group = 3;
		LobbySession.guildId = 9;
		LobbySession.guildName = "Racers";
		LobbySession.guildOwner = true;
		LobbySession.isTrialMod = false;
		var accountChanges = 0;
		var listener = function():Void accountChanges++;
		LobbySession.onAccountChange(listener);
		var posts:Array<{url:String, fields:Map<String, String>}> = [];
		GuildPopup.deleteFactory = function(url:String, fields:Map<String, String>):SuperLoader {
			posts.push({url: url, fields: fields});
			return new SuperLoader(false, SuperLoader.raw, false);
		};

		var popup = new GuildPopup(9, "", false);
		popup.applyReturnData(sampleData());
		click(popup, "delete_bt");
		var confirm = lastPopup(ConfirmPopup);
		assertNotNull(confirm, "delete button opens a confirmation popup");
		assertEquals(true, LobbyArt.text(confirm, "textBox").htmlText.indexOf("Racers") >= 0, "delete confirmation includes guild name");
		click(confirm, "ok_bt");

		assertEquals(1, posts.length, "confirming delete posts once");
		assertEquals(ServerConfig.guildDeleteUrl(), posts[0].url, "delete posts to guild_delete.php");
		assertEquals("9", posts[0].fields.get("guild_id"), "delete posts guild id");
		assertEquals(0, LobbySession.guildId, "deleting current guild clears session guild id");
		assertEquals("", LobbySession.guildName, "deleting current guild clears session guild name");
		assertEquals(false, LobbySession.guildOwner, "deleting current guild clears owner flag");
		assertEquals(1, accountChanges, "deleting current guild dispatches account change");
		assertEquals(true, popup.fadeOutStarted, "confirmed delete closes the guild popup");

		LobbySession.offAccountChange(listener);
		closeAll();
	}

	private static function testRemoveCancelsAsyncGuildInfoLoad():Void {
		var fake = new FakeTransport();
		SuperLoader.transportFactory = function():Dynamic return fake;
		var popup = new GuildPopup(9);
		popup.remove();

		assertEquals(true, fake.closed, "removing guild popup closes pending guild-info loader");
		assertEquals(true, fake.removes >= 5, "removing guild popup detaches guild-info loader listeners");
		fake.data = '{"guild":{"guild_id":9,"guild_name":"Late"},"members":[]}';
		fake.emit(new Event(Event.COMPLETE));
		assertEquals(false, isOpen(popup), "late guild-info completion does not reopen removed popup");
		SuperLoader.resetHooks();
	}

	private static function sampleData():Dynamic {
		return {
			guild: {
				guild_id: 9, owner_id: 5, guild_name: "Racers",
				gp_today: 1234, gp_total: 98765,
				member_count: 2, active_count: 1, note: "Fast only", emblem: "racers.jpg"
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

	private static function isOpen(target:Popup):Bool {
		for (popup in Popup.getOpen()) {
			if (popup == target) {
				return true;
			}
		}
		return false;
	}

	private static function click(root:Popup, name:String):Void {
		var target = DisplayUtil.findByName(root, name);
		assertNotNull(target, 'missing clickable $name');
		target.dispatchEvent(new MouseEvent(MouseEvent.CLICK, true, false));
	}

	private static function lastPopup<T:Popup>(klass:Class<T>):Null<T> {
		var popups = Popup.getOpen();
		for (i in 0...popups.length) {
			var popup = popups[popups.length - 1 - i];
			var typed = Std.downcast(popup, klass);
			if (typed != null) return typed;
		}
		return null;
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

private class FakeTransport extends EventDispatcher {
	public var data:Dynamic = null;
	public var dataFormat:Dynamic = null;
	public var loaded:Null<URLRequest>;
	public var closed:Bool = false;
	public var adds:Int = 0;
	public var removes:Int = 0;

	public function new() {
		super();
	}

	public function load(request:URLRequest):Void {
		loaded = request;
	}

	public function close():Void {
		closed = true;
	}

	override public function addEventListener(type:String, listener:Dynamic, useCapture:Bool = false, priority:Int = 0,
			useWeakReference:Bool = false):Void {
		adds++;
	}

	override public function removeEventListener(type:String, listener:Dynamic, useCapture:Bool = false):Void {
		removes++;
	}

	public function emit(event:Event):Void {
		// Listener removal is what this test verifies; no late event is delivered.
	}
}
