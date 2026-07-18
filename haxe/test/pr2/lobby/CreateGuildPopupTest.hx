package pr2.lobby;

import openfl.events.MouseEvent;
import pr2.lobby.dialogs.CreateGuildPopup;
import pr2.lobby.dialogs.GuildPopup;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.net.ServerConfig;
import pr2.ui.controls.GameTextInput;
import pr2.ui.controls.GameTextArea;
import pr2.util.TestDisplayUtil as DisplayUtil;

class CreateGuildPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var savedInfoFactory = CreateGuildPopup.infoFactory;
		var savedSaveFactory = CreateGuildPopup.saveFactory;
		var savedTransferFactory = CreateGuildPopup.transferFactory;
		var savedGuildId = LobbySession.guildId;
		var savedGuildName = LobbySession.guildName;
		var savedEmblem = LobbySession.emblem;
		var savedGuildOwner = LobbySession.guildOwner;
		var savedRemember = LobbySession.remember;
		var savedGroup = LobbySession.group;
		ServerConfig.setHost("http://example.test");

		testCreateUpdatesAccount();
		if (pr2.DeterministicTestMode.finishSmokeSuite("CreateGuildPopupTest")) return;
		testExactAuthoredLayout();
		testSaveErrorRestoresConfirm();
		testEditLoadsDeletesAndPosts();
		testModEditDoesNotUpdateAccount();
		testTransferGate();
		testGuildPopupEditButton();

		CreateGuildPopup.infoFactory = savedInfoFactory;
		CreateGuildPopup.saveFactory = savedSaveFactory;
		CreateGuildPopup.transferFactory = savedTransferFactory;
		LobbySession.guildId = savedGuildId;
		LobbySession.guildName = savedGuildName;
		LobbySession.emblem = savedEmblem;
		LobbySession.guildOwner = savedGuildOwner;
		LobbySession.remember = savedRemember;
		LobbySession.group = savedGroup;
		ServerConfig.resetHost();
		closeAll();
		trace('CreateGuildPopupTest passed $assertions assertions');
	}

	private static function testCreateUpdatesAccount():Void {
		closeAll();
		LobbySession.guildId = 0;
		LobbySession.guildOwner = false;
		var accountChanges = 0;
		var listener = function():Void accountChanges++;
		LobbySession.onAccountChange(listener);
		var saves:Array<{url:String, fields:Map<String, String>}> = [];
		CreateGuildPopup.saveFactory = function(url:String, fields:Map<String, String>, onResult:Dynamic->Void, onError:String->Void):Void {
			saves.push({url: url, fields: fields});
			onResult({guild_id: 17, guild_name: "New Guild", emblem: "new.png"});
		};

		var popup = new CreateGuildPopup();
		setInput(popup, "nameBox", "New Guild");
		setInput(popup, "proseBox", "Guild note");
		popup.setEmblemFileNameForTests("new.png");
		click(popup, "confirm_bt");

		assertEquals(1, saves.length, "create posts once");
		assertEquals(ServerConfig.guildCreateUrl(), saves[0].url, "create endpoint");
		assertEquals(false, saves[0].fields.exists("guild_id"), "create does not post guild id");
		assertEquals("New Guild", saves[0].fields.get("name"), "create posts guild name");
		assertEquals("Guild note", saves[0].fields.get("note"), "create posts note");
		assertEquals("new.png", saves[0].fields.get("emblem"), "create posts emblem filename");
		assertEquals(17, LobbySession.guildId, "create updates session guild id");
		assertEquals("New Guild", LobbySession.guildName, "create updates session guild name");
		assertEquals("new.png", LobbySession.emblem, "create updates session emblem");
		assertEquals(true, LobbySession.guildOwner, "create marks owner");
		assertEquals(1, accountChanges, "create dispatches account change");
		LobbySession.offAccountChange(listener);
		closeAll();
	}

	private static function testExactAuthoredLayout():Void {
		closeAll();
		LobbySession.guildId = 0;
		var popup = new CreateGuildPopup();
		var panel = DisplayUtil.findByName(popup, "panel");
		var transferPanel = DisplayUtil.findByName(popup, "transfer_bg");
		var name = Std.downcast(DisplayUtil.findByName(popup, "nameBox"), GameTextInput);
		var prose = Std.downcast(DisplayUtil.findByName(popup, "proseBox"), GameTextArea);
		var emblemBacking = DisplayUtil.findByName(popup, "emblemBacking");
		var change = DisplayUtil.findByName(popup, "changeEmblem_bt");
		var remove = DisplayUtil.findByName(popup, "deleteEmblem_bt");
		var transfer = DisplayUtil.findByName(popup, "transfer_bt");
		var confirm = DisplayUtil.findByName(popup, "confirm_bt");
		var cancel = DisplayUtil.findByName(popup, "cancel_bt");
		assertClose(-135.2, panel.x, "main ShadowBG keeps XFL X");
		assertClose(-108.8, panel.y, "main ShadowBG keeps XFL Y");
		assertClose(0.994140625, panel.scaleX, "main ShadowBG keeps XFL horizontal scale");
		assertClose(1.26116943359375, panel.scaleY, "main ShadowBG keeps XFL vertical scale");
		assertClose(-138.8, transferPanel.y, "transfer ShadowBG keeps XFL Y");
		assertClose(0.15704345703125, transferPanel.scaleY, "transfer ShadowBG keeps XFL vertical scale");
		assertEquals(false, transferPanel.visible, "create mode hides transfer strip");
		assertClose(-44, name.x, "guild name input keeps XFL X");
		assertClose(-60, name.y, "guild name input keeps XFL Y");
		assertClose(100 * 1.49998474121094, name.controlWidth, "guild name input keeps authored scale");
		assertEquals(20, name.maxChars, "guild name input keeps authored maximum");
		assertClose(-44, prose.x, "guild prose area keeps XFL X");
		assertClose(32, prose.y, "guild prose area keeps XFL Y");
		assertClose(240, prose.controlWidth, "guild prose area keeps authored scale");
		assertClose(100, prose.controlHeight, "guild prose area keeps authored height");
		assertEquals(100, prose.maxChars, "guild prose area keeps authored maximum");
		assertClose(-43, emblemBacking.x, "emblem backing visible bounds keep XFL X");
		assertClose(-27, emblemBacking.y, "emblem backing visible bounds keep XFL Y");
		assertClose(60, change.x, "change link keeps XFL X");
		assertClose(8, change.y, "change link keeps XFL Y");
		assertClose(60, remove.x, "delete link keeps XFL X");
		assertClose(-7.85, remove.y, "delete link keeps XFL Y");
		assertClose(-36.85, transfer.x, "transfer link keeps XFL X");
		assertClose(-131.85, transfer.y, "transfer link keeps XFL Y");
		assertClose(-114, confirm.x, "confirm button keeps XFL X");
		assertClose(95, confirm.y, "confirm button keeps XFL Y");
		assertClose(15, cancel.x, "cancel button keeps XFL X");
		assertClose(95, cancel.y, "cancel button keeps XFL Y");
		closeAll();
	}

	private static function testSaveErrorRestoresConfirm():Void {
		closeAll();
		CreateGuildPopup.saveFactory = function(url:String, fields:Map<String, String>, onResult:Dynamic->Void, onError:String->Void):Void {
			onError("nope");
		};
		var popup = new CreateGuildPopup();
		click(popup, "confirm_bt");
		assertClose(1, DisplayUtil.findByName(popup, "confirm_bt").alpha, "save error restores confirm alpha");
		click(popup, "confirm_bt");
		assertClose(1, DisplayUtil.findByName(popup, "confirm_bt").alpha, "save error permits a retry");
		closeAll();
	}

	private static function testEditLoadsDeletesAndPosts():Void {
		closeAll();
		LobbySession.guildId = 9;
		LobbySession.guildOwner = true;
		CreateGuildPopup.infoFactory = function(id:Int, onResult:Dynamic->Void, onError:String->Void):Void {
			assertEquals(9, id, "edit loads requested guild");
			onResult({guild: {guild_name: "Racers", note: "Fast only", emblem: "racer.png"}});
		};
		var saves:Array<{url:String, fields:Map<String, String>}> = [];
		CreateGuildPopup.saveFactory = function(url:String, fields:Map<String, String>, onResult:Dynamic->Void, onError:String->Void):Void {
			saves.push({url: url, fields: fields});
			onResult({guild_id: 9, guild_name: fields.get("name"), emblem: fields.get("emblem")});
		};

		var popup = new CreateGuildPopup(9);
		assertEquals("Racers", inputText(popup, "nameBox"), "edit populates name");
		assertEquals("Fast only", inputText(popup, "proseBox"), "edit populates note");
		assertEquals("racer.png", popup.emblemFileNameForTests(), "edit loads existing emblem");
		assertEquals(true, DisplayUtil.findByName(popup, "deleteEmblem_bt").visible, "custom edit emblem can be deleted");
		click(popup, "deleteEmblem_bt");
		assertEquals("default-emblem.jpg", popup.emblemFileNameForTests(), "delete emblem reverts to default");
		assertEquals(false, DisplayUtil.findByName(popup, "deleteEmblem_bt").visible, "delete emblem button hides after deletion");
		assertNotNull(lastMessage(), "delete emblem warns about confirm/cancel");
		closeMessagesOnly();

		setInput(popup, "proseBox", "Updated");
		click(popup, "confirm_bt");
		assertEquals(1, saves.length, "edit posts once");
		assertEquals(ServerConfig.guildEditUrl(), saves[0].url, "edit endpoint");
		assertEquals("9", saves[0].fields.get("guild_id"), "edit posts guild id");
		assertEquals("Racers", saves[0].fields.get("name"), "edit posts populated name");
		assertEquals("Updated", saves[0].fields.get("note"), "edit posts updated note");
		assertEquals("default-emblem.jpg", saves[0].fields.get("emblem"), "edit posts deleted emblem filename");
		closeAll();
	}

	private static function testModEditDoesNotUpdateAccount():Void {
		closeAll();
		LobbySession.guildId = 2;
		LobbySession.guildName = "Mine";
		LobbySession.guildOwner = false;
		CreateGuildPopup.infoFactory = function(id:Int, onResult:Dynamic->Void, onError:String->Void):Void {
			onResult({guild: {guild_name: "Other", note: "", emblem: "other.png"}});
		};
		CreateGuildPopup.saveFactory = function(url:String, fields:Map<String, String>, onResult:Dynamic->Void, onError:String->Void):Void {
			onResult({guild_id: 9, guild_name: "Other", emblem: "other.png"});
		};
		var popup = new CreateGuildPopup(9);
		click(popup, "confirm_bt");
		assertEquals(2, LobbySession.guildId, "moderator editing another guild does not change own guild id");
		assertEquals("Mine", LobbySession.guildName, "moderator editing another guild does not change own guild name");
		assertEquals(true, popup.fadeOutStarted, "moderator edit fades out after save");
		closeAll();
	}

	private static function testTransferGate():Void {
		closeAll();
		LobbySession.guildId = 9;
		LobbySession.guildOwner = true;
		LobbySession.remember = false;
		CreateGuildPopup.infoFactory = function(id:Int, onResult:Dynamic->Void, onError:String->Void):Void {
			onResult({guild: {guild_name: "Racers", note: "", emblem: "default-emblem.jpg"}});
		};
		var popup = new CreateGuildPopup(9);
		assertEquals(true, DisplayUtil.findByName(popup, "transfer_bt").visible, "owner edit shows transfer button");
		click(popup, "transfer_bt");
		assertNotNull(lastMessage(), "transfer without remember me shows warning");
		closeAll();

		var transfers = 0;
		CreateGuildPopup.transferFactory = function():Void transfers++;
		LobbySession.remember = true;
		popup = new CreateGuildPopup(9);
		click(popup, "transfer_bt");
		assertEquals(1, transfers, "remembered owner can open transfer flow");
		assertEquals(true, popup.fadeOutStarted, "transfer fades create/edit popup");
		closeAll();
	}

	private static function testGuildPopupEditButton():Void {
		closeAll();
		LobbySession.group = 2;
		LobbySession.isTrialMod = false;
		CreateGuildPopup.infoFactory = function(id:Int, onResult:Dynamic->Void, onError:String->Void):Void {
			onResult({guild: {guild_name: "Racers", note: "", emblem: "default-emblem.jpg"}});
		};
		var guild = new GuildPopup(9, "", false);
		guild.applyReturnData({
			guild: {guild_id: 9, owner_id: 5, guild_name: "Racers", gp_today: 0, gp_total: 0, member_count: 0, active_count: 0, note: ""},
			members: []
		});
		click(guild, "edit_bt");
		var open = Popup.getOpen();
		assertNotNull(Std.downcast(open[open.length - 1], CreateGuildPopup), "guild edit button opens CreateGuildPopup");
		closeAll();
	}

	private static function setInput(popup:Popup, name:String, value:String):Void {
		var input = Std.downcast(DisplayUtil.findByName(popup, name), GameTextInput);
		if (input != null) {
			input.text = value;
			return;
		}
		LobbyArt.text(popup, name).text = value;
	}

	private static function inputText(popup:Popup, name:String):String {
		var input = Std.downcast(DisplayUtil.findByName(popup, name), GameTextInput);
		if (input != null) return input.text;
		return LobbyArt.text(popup, name).text;
	}

	private static function click(popup:Popup, name:String):Void {
		var target = DisplayUtil.findByName(popup, name);
		if (target == null) throw name + " missing";
		target.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	}

	private static function lastMessage():Null<MessagePopup> {
		var open = Popup.getOpen();
		return Std.downcast(open[open.length - 1], MessagePopup);
	}

	private static function closeMessagesOnly():Void {
		for (popup in Popup.getOpen().copy()) {
			if (Std.isOfType(popup, MessagePopup)) popup.remove();
		}
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

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000001) throw '$message: expected $expected, got $actual';
	}
}
