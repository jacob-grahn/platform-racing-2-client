package pr2.lobby;

import openfl.display.DisplayObjectContainer;
import openfl.events.MouseEvent;
import pr2.lobby.dialogs.BanMenu;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.GuildPopup;
import pr2.lobby.dialogs.LevelInfoPopup;
import pr2.lobby.dialogs.PlayerGuestPopup;
import pr2.lobby.dialogs.PlayerPopup;
import pr2.lobby.dialogs.Popup;
import pr2.net.LobbySocket;
import pr2.net.ServerConfig;
import pr2.runtime.FlButton;
import pr2.runtime.FlComboBox;
import pr2.runtime.FlComponents;
import pr2.runtime.PR2MovieClip;
import pr2.ui.GuildName;
import pr2.util.DisplayUtil;

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
		var savedTempMod = LobbySession.isTempMod;
		var savedTrialMod = LobbySession.isTrialMod;
		var savedServerOwner = LobbySession.serverOwner;
		var savedUploadFactory = BanMenu.uploadFactory;
		var savedChatRecordProvider = BanMenu.chatRecordProvider;
		var savedGuildNameFactory = GuildName.popupFactory;
		var savedHoverDelayFactory = PlayerPopup.hoverDelayFactory;
		var savedLevelAutoLoad = LevelInfoPopup.autoLoadOnCreate;
		var savedChatRoom = Memory.get("chatRoom");

		testMemberRender();
		testServerOwnerAndRankSupplement();
		testGuildRenderingAndContextCleanup();
		testDelayedSendPmHoverAndLevelContextCleanup();
		testGuestHandoff();
		testChatLinkEntryPoints();
		testGuestButtonsDisabled();
		testTempModMenu();
		testBanMenu();
		testAdminMenu();

		LobbySession.group = savedGroup;
		LobbySession.isTempMod = savedTempMod;
		LobbySession.isTrialMod = savedTrialMod;
		LobbySession.serverOwner = savedServerOwner;
		BanMenu.uploadFactory = savedUploadFactory;
		BanMenu.chatRecordProvider = savedChatRecordProvider;
		GuildName.popupFactory = savedGuildNameFactory;
		PlayerPopup.hoverDelayFactory = savedHoverDelayFactory;
		LevelInfoPopup.autoLoadOnCreate = savedLevelAutoLoad;
		if (savedChatRoom == null) {
			Memory.remove("chatRoom");
		} else {
			Memory.set("chatRoom", savedChatRoom);
		}
		closeAll();
		trace('PlayerPopupTest passed $assertions assertions');
	}

	private static function testMemberRender():Void {
		LobbySession.group = 1;
		LobbySession.serverOwner = 0;
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
		assertEquals(true, DisplayUtil.findByName(popup, "playerInfo").visible, "info panel becomes visible");

		popup.remove();
	}

	private static function testServerOwnerAndRankSupplement():Void {
		LobbySession.group = 1;
		LobbySession.serverOwner = 5;
		var popup = new PlayerPopup("Jiggmin", false);
		popup.applyReturnData({
			userId: 5, group: 1, status: "online", rank: 24, hats: "3",
			registerDate: 0, loginDate: 1363478400, guildId: 0,
			hat: 1, head: 1, body: 1, feet: 1,
			following: 0, friend: 1, ignored: 0,
			verified: false, hof: false, exp_points: 1234, exp_to_rank: 5000
		});

		assertEquals("Server Owner", LobbyArt.text(popup, "groupBox").text, "server owner overrides profile group text");
		var rankBox = DisplayUtil.findByName(popup, "rankBox");
		rankBox.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals(true, DisplayUtil.findByName(popup, "supplBg").visible, "rank hover shows supplement background");
		assertEquals("", LobbyArt.text(popup, "supplText").text, "rank hover no longer uses text fallback");
		assertNotNull(findSymbolOrNull(popup, "ExpGainGraphic"), "rank hover shows authored ExpGain supplement");
		rankBox.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals(null, findSymbolOrNull(popup, "ExpGainGraphic"), "rank mouse-out removes ExpGain supplement");
		popup.remove();
		LobbySession.serverOwner = 0;
	}

	private static function testGuildRenderingAndContextCleanup():Void {
		LobbySession.group = 1;
		LobbySession.serverOwner = 0;
		closeAll();
		var existingGuild = new GuildPopup(9, "", false);
		var openedGuilds:Array<Int> = [];
		GuildName.popupFactory = function(id:Int):Void openedGuilds.push(id);

		var popup = new PlayerPopup("Guilded", false);
		assertEquals(true, existingGuild.fadeOutStarted, "opening player popup fades existing guild popup context");
		popup.applyReturnData({
			userId: 8, group: 1, status: "online", rank: 9, hats: "2",
			registerDate: 1363478400, loginDate: 1363478400, guildId: 42,
			guildName: "Speed <Guild>", emblem: "speed.png",
			hat: 1, head: 1, body: 1, feet: 1,
			following: 0, friend: 0, ignored: 0,
			verified: false, hof: false, exp_points: 10, exp_to_rank: 100
		});

		assertEquals(null, DisplayUtil.findByName(popup, "guildBox"), "guild text box is replaced by GuildName clip");
		var guildName = findGuildName(popup);
		assertNotNull(guildName, "guilded profile renders GuildName clip");
		assertEquals(-40.0, guildName.x, "GuildName x matches Flash placement");
		assertEquals(64.0, guildName.y, "GuildName y matches Flash placement");
		assertEquals(145.0, guildName.nameWidthForTests(), "GuildName uses wide profile width");
		assertEquals(true, guildName.nameHtmlForTests().indexOf("<b>") >= 0, "GuildName uses bold profile text");
		assertEquals(true, guildName.nameHtmlForTests().indexOf("&lt;Guild&gt;") >= 0, "GuildName escapes profile guild name");
		assertEquals("speed.png", guildName.emblemForTests().getFileName(), "GuildName loads profile emblem");
		guildName.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, openedGuilds.length, "profile GuildName remains clickable");
		assertEquals(42, openedGuilds[0], "profile GuildName routes guild id");

		popup.remove();
		assertEquals(true, guildName.isRemoved(), "player popup removal cleans GuildName clip");
		closeAll();
	}

	private static function testDelayedSendPmHoverAndLevelContextCleanup():Void {
		LobbySession.group = 1;
		LobbySession.serverOwner = 0;
		closeAll();
		var capturedHover:Null<Void->Void> = null;
		var capturedDelay = 0;
		PlayerPopup.hoverDelayFactory = function(callback:Void->Void, delayMs:Int):Null<haxe.Timer> {
			capturedHover = callback;
			capturedDelay = delayMs;
			return null;
		};

		LevelInfoPopup.autoLoadOnCreate = false;
		var level = new LevelInfoPopup(50815);
		var popup = new PlayerPopup("Target", false);
		popup.applyReturnData({
			userId: 7, group: 1, status: "", rank: 1, hats: "0",
			registerDate: 1363478400, loginDate: 1363478400, guildId: 0,
			hat: 1, head: 1, body: 1, feet: 1,
			following: 0, friend: 0, ignored: 0,
			verified: false, hof: false, exp_points: 10, exp_to_rank: 100
		});

		var message = DisplayUtil.findByName(popup, "messageButton");
		message.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
		assertEquals(500, capturedDelay, "Send PM hover uses Flash delay");
		assertEquals(false, popup.hasSendPmHoverForTests(), "Send PM hover is delayed");
		capturedHover();
		assertEquals(true, popup.hasSendPmHoverForTests(), "Send PM hover appears after delay callback");
		message.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals(false, popup.hasSendPmHoverForTests(), "Send PM mouse-out clears delayed hover");

		var guild = new GuildPopup(9, "", false);
		guild.fadeOutStarted = false;
		click(popup, "levelsButton");
		assertEquals(true, guild.fadeOutStarted, "view-levels closes open guild popup context");
		assertEquals(true, level.fadeOutStarted, "view-levels closes open level popup context");
		assertEquals(true, popup.fadeOutStarted, "view-levels closes player popup");
		closeAll();
	}

	private static function testTempModMenu():Void {
		LobbySession.group = 1;
		LobbySession.isTempMod = true;
		LobbySocket.resetSent();
		closeAll();

		var popup = new PlayerPopup("Target", false);
		popup.applyReturnData({
			userId: 7, group: 1, status: "", rank: 1, hats: "0",
			registerDate: 1363478400, loginDate: 1363478400, guildId: 0,
			hat: 1, head: 1, body: 1, feet: 1
		});

		assertNotNull(DisplayUtil.findByName(popup, "warning1Button"), "temporary moderators see the warning menu");
		click(popup, "warning2Button");
		assertEquals("warn`Target`2", LobbySocket.lastSent(), "warning buttons emit warn command");
		assertEquals(true, popup.fadeOutStarted, "warning starts closing the player popup");
		popup.remove();

		popup = new PlayerPopup("Target", false);
		popup.applyReturnData({
			userId: 7, group: 1, status: "", rank: 1, hats: "0",
			registerDate: 1363478400, loginDate: 1363478400, guildId: 0,
			hat: 1, head: 1, body: 1, feet: 1
		});
		click(tempModMenu(popup), "kickButton");
		var confirm = lastPopup(ConfirmPopup);
		assertNotNull(confirm, "kick opens a confirmation popup");
		click(confirm, "ok_bt");
		assertEquals("kick`Target", LobbySocket.lastSent(), "confirmed kick emits kick command");
		assertEquals(true, popup.fadeOutStarted, "confirmed kick starts closing the player popup");

		LobbySession.isTempMod = false;
		closeAll();
	}

	private static function testBanMenu():Void {
		LobbySession.group = 2;
		LobbySession.isTempMod = false;
		LobbySession.isTrialMod = false;
		LobbySocket.resetSent();
		Memory.set("chatRoom", "main");
		closeAll();

		var uploads:Array<{url:String, fields:Map<String, String>, label:String}> = [];
		BanMenu.chatRecordProvider = function():String return "chat transcript";
		BanMenu.uploadFactory = function(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
				onError:String->Void):Null<pr2.lobby.dialogs.UploadingPopup> {
			uploads.push({url: url, fields: fields, label: label});
			onResult({ban_id: 123});
			return null;
		};

		var popup = new PlayerPopup("Target", false);
		popup.applyReturnData({
			userId: 7, group: 1, status: "", rank: 1, hats: "0",
			registerDate: 1363478400, loginDate: 1363478400, guildId: 0,
			hat: 1, head: 1, body: 1, feet: 1
		});

		var menu = banMenu(popup);
		assertNotNull(menu, "moderators see the full ban menu");
		click(menu, "warning3Button");
		assertEquals("warn`Target`3", LobbySocket.lastSent(), "ban menu warning emits warn command");
		popup.remove();

		popup = new PlayerPopup("Target", false);
		popup.applyReturnData({
			userId: 7, group: 1, status: "", rank: 1, hats: "0",
			registerDate: 1363478400, loginDate: 1363478400, guildId: 0,
			hat: 1, head: 1, body: 1, feet: 1
		});
		menu = banMenu(popup);
		FlComponents.asTextField(DisplayUtil.findByName(menu, "reason")).text = "spam";
		var duration = combo(menu, "duration");
		duration.selectedIndex = 2;
		click(menu, "banButton");
		var confirm = lastPopup(ConfirmPopup);
		assertNotNull(confirm, "ban opens a confirmation popup");
		click(confirm, "ok_bt");

		assertEquals(1, uploads.length, "ban uploads once after confirmation");
		assertEquals(ServerConfig.banUserUrl(), uploads[0].url, "ban endpoint");
		assertEquals("Target", uploads[0].fields.get("banned_name"), "ban target field");
		assertEquals("86400", uploads[0].fields.get("duration"), "selected ban duration");
		assertEquals("spam", uploads[0].fields.get("reason"), "ban reason field");
		assertEquals("both", uploads[0].fields.get("type"), "ban type field");
		assertEquals("social", uploads[0].fields.get("scope"), "ban scope field");
		assertEquals("chat transcript", uploads[0].fields.get("record"), "ban includes current chat record outside mod rooms");
		assertEquals("Banning...", uploads[0].label, "ban upload label");
		assertEquals("ban`Target`86400`social`123`spam", LobbySocket.lastSent(), "ban success emits socket command");
		assertEquals(true, popup.fadeOutStarted, "ban success closes the player popup");

		popup.remove();

		Memory.set("chatRoom", "mod");
		uploads = [];
		var direct = directBanMenu("Bad <Name>");
		FlComponents.asTextField(DisplayUtil.findByName(direct.art, "reason")).text = "mod room";
		combo(direct.art, "duration").selectedIndex = 2;
		click(direct.art, "banButton");
		confirm = lastPopup(ConfirmPopup);
		assertNotNull(confirm, "ban confirmation opens for escaped-name check");
		var confirmText = LobbyArt.text(confirm, "textBox").htmlText;
		assertEquals(true, confirmText.indexOf("Bad &lt;Name&gt;") >= 0, "ban confirmation escapes target name");
		click(confirm, "ok_bt");
		assertEquals(false, uploads[0].fields.exists("record"), "ban omits chat record in mod room");
		direct.popup.remove();

		LobbySession.isTrialMod = true;
		direct = directBanMenu("Target");
		assertTrialDurations(combo(direct.art, "duration"));
		assertTrialScope(combo(direct.art, "scope"));
		direct.popup.remove();
		LobbySession.isTrialMod = false;

		var capturedResult:Null<Dynamic->Void> = null;
		var capturedError:Null<String->Void> = null;
		uploads = [];
		Memory.set("chatRoom", "main");
		BanMenu.uploadFactory = function(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void,
				onError:String->Void):Null<pr2.lobby.dialogs.UploadingPopup> {
			uploads.push({url: url, fields: fields, label: label});
			capturedResult = onResult;
			capturedError = onError;
			return null;
		};
		direct = directBanMenu("Target");
		FlComponents.asTextField(DisplayUtil.findByName(direct.art, "reason")).text = "late";
		combo(direct.art, "duration").selectedIndex = 2;
		click(direct.art, "banButton");
		confirm = lastPopup(ConfirmPopup);
		click(confirm, "ok_bt");
		LobbySocket.resetSent();
		direct.menu.remove();
		direct.popup.remove();
		capturedResult({ban_id: 999});
		capturedError("late error");
		assertEquals("", LobbySocket.lastSent(), "removed ban menu ignores late upload callbacks");
		assertEquals(false, direct.popup.fadeOutStarted, "removed ban menu does not fade target after late upload callbacks");

		BanMenu.uploadFactory = BanMenu.defaultUpload;
		BanMenu.chatRecordProvider = BanMenu.defaultChatRecord;
		closeAll();
	}

	private static function testAdminMenu():Void {
		LobbySession.group = 3;
		LobbySession.isTempMod = false;
		LobbySession.isTrialMod = false;
		LobbySocket.resetSent();
		closeAll();

		var popup = new PlayerPopup("Target", false);
		popup.applyReturnData({
			userId: 7, group: 1, status: "", rank: 1, hats: "0",
			registerDate: 1363478400, loginDate: 1363478400, guildId: 0,
			hat: 1, head: 1, body: 1, feet: 1
		});
		var admin = adminMenu(popup);
		assertNotNull(admin, "admins see promotion controls");
		click(admin, "trialMod_bt");
		var confirm = lastPopup(ConfirmPopup);
		assertNotNull(confirm, "trial promotion opens confirmation");
		click(confirm, "ok_bt");
		assertEquals("promote_to_moderator`Target`trial", LobbySocket.lastSent(), "trial promotion payload");
		assertEquals(true, popup.fadeOutStarted, "promotion starts closing the player popup");
		popup.remove();

		popup = new PlayerPopup("Target", false);
		popup.applyReturnData({
			userId: 7, group: 2, status: "", rank: 1, hats: "0",
			registerDate: 1363478400, loginDate: 1363478400, guildId: 0,
			hat: 1, head: 1, body: 1, feet: 1
		});
		admin = adminMenu(popup);
		click(admin, "demote_bt");
		confirm = lastPopup(ConfirmPopup);
		assertNotNull(confirm, "demotion opens confirmation");
		click(confirm, "ok_bt");
		assertEquals("demote_moderator`Target", LobbySocket.lastSent(), "demotion payload");
		assertEquals(true, popup.fadeOutStarted, "demotion starts closing the player popup");

		closeAll();
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
		var button = Std.downcast(DisplayUtil.findByName(popup, name), FlButton);
		if (button == null) throw name + " is not an FlButton";
		return button;
	}

	private static function flLabel(popup:PlayerPopup, name:String):String {
		return flButton(popup, name).label;
	}

	private static function click(container:DisplayObjectContainer, name:String):Void {
		var target = DisplayUtil.findByName(container, name);
		if (target == null) throw 'missing click target $name';
		target.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	}

	private static function tempModMenu(popup:PlayerPopup):PR2MovieClip {
		return findSymbol(popup, "TempModMenuGraphic");
	}

	private static function banMenu(container:DisplayObjectContainer):PR2MovieClip {
		return findSymbol(container, "BanMenuGraphic");
	}

	private static function adminMenu(container:DisplayObjectContainer):PR2MovieClip {
		return findSymbol(container, "AdminMenuGraphic");
	}

	private static function combo(container:DisplayObjectContainer, name:String):FlComboBox {
		var combo = Std.downcast(DisplayUtil.findByName(container, name), FlComboBox);
		if (combo == null) throw name + " is not an FlComboBox";
		return combo;
	}

	private static function directBanMenu(name:String):{popup:Popup, menu:BanMenu, art:PR2MovieClip} {
		var popup = new Popup(false);
		var menu = new BanMenu(name, popup);
		popup.addChild(menu);
		return {popup: popup, menu: menu, art: banMenu(menu)};
	}

	private static function assertTrialDurations(duration:FlComboBox):Void {
		for (i in 0...duration.length) {
			var seconds = Std.parseInt(Std.string(Reflect.field(duration.dataProvider.getItemAt(i), "data")));
			assertEquals(true, seconds != null && seconds <= 86400, "trial moderator duration stays at one day or less");
		}
	}

	private static function assertTrialScope(scope:FlComboBox):Void {
		assertEquals(false, scope.enabled, "trial moderators cannot change ban scope");
		for (i in 0...scope.length) {
			assertEquals(false, Reflect.field(scope.dataProvider.getItemAt(i), "data") == "game", "trial moderators do not get game bans");
		}
	}

	private static function findSymbol(container:Dynamic, symbolName:String):PR2MovieClip {
		var found = findSymbolOrNull(container, symbolName);
		if (found != null) return found;
		throw 'missing $symbolName';
	}

	private static function findSymbolOrNull(container:Dynamic, symbolName:String):Null<PR2MovieClip> {
		var display = Std.downcast(container, DisplayObjectContainer);
		if (display == null) return null;
		for (i in 0...display.numChildren) {
			var child = display.getChildAt(i);
			var clip = Std.downcast(child, PR2MovieClip);
			if (clip != null && clip.symbol.linkageClassName == symbolName) {
				return clip;
			}
			var childContainer = Std.downcast(child, DisplayObjectContainer);
			if (childContainer != null) {
				var found = findSymbolOrNull(childContainer, symbolName);
				if (found != null) return found;
			}
		}
		return null;
	}

	private static function findGuildName(container:Dynamic):Null<GuildName> {
		var display = Std.downcast(container, DisplayObjectContainer);
		if (display == null) return null;
		for (i in 0...display.numChildren) {
			var child = display.getChildAt(i);
			var guild = Std.downcast(child, GuildName);
			if (guild != null) return guild;
			var found = findGuildName(child);
			if (found != null) return found;
		}
		return null;
	}

	private static function lastPopup<T:Popup>(cls:Class<T>):Null<T> {
		var open = Popup.getOpen();
		var i = open.length - 1;
		while (i >= 0) {
			var popup = Std.downcast(open[i], cls);
			if (popup != null) return popup;
			i--;
		}
		return null;
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
