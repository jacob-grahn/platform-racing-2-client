package pr2.lobby;

import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.character.Parts;
import pr2.lobby.account.AccountCharacter;

import pr2.lobby.account.AccountCustomizeData;
import pr2.lobby.account.LoadoutsPopup;
import pr2.lobby.account.PartInfoPopup;
import pr2.lobby.account.PartPopup;
import pr2.lobby.account.PlayerDisplay;
import pr2.lobby.account.Presets;
import pr2.lobby.account.Settings;
import pr2.lobby.account.StatsSelect;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.lobby.dialogs.HoverDelayPopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.level.CourseMenu;
import pr2.lobby.tabs.AccountTab;
import pr2.ui.GuildName;
import pr2.util.DisplayUtil;

class AccountTabTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testCharacterGraphicScale();
		testCustomizePayload();
		testGuildRenderingUsesLinkedClipAndEmblem();
		testAccountSummaryValuesArePlainText();
		testManualPartDispatchSavesOverrideAndRefreshes();
		testRankTokenChangesRetestLevelAccess();
		testStatSlidersDoNotRunUnderRightArrow();
		testLoadoutsHoverPlacementAndCleanup();
		testPresetListingThumbnailsMaskNonEpicSecondColors();
		testHotkeyBlockingMatchesFlash();
		testHotkeyConfirmAppliesPreset();
		testHotkeys();
		testHoverDelayPopupCleanup();
		testPartInfoHoverAndPopupEntry();
		testPartInfoPopupCatalogRows();
		testPartPopupSpecialRenderingObtainLinksAndEquip();
		testRandomizeStyleButtonUsesDelayedHover();
		trace('AccountTabTest passed $assertions assertions');
	}

	private static function testCharacterGraphicScale():Void {
		var character = new AccountCharacter();
		assertEquals(1, character.scaleX, "Flash Character wrapper remains at scale 1");
		assertEquals(1, character.display.scaleX, "CharacterGraphic container remains at scale 1");
		var stand = character.display.getStateClip("standAnim");
		assertEquals(0.149993896484375, stand.scaleX, "standAnim preserves its authored internal scaleX");
		assertEquals(0.149993896484375, stand.scaleY, "standAnim preserves its authored internal scaleY");
		character.remove();
	}

	private static function testCustomizePayload():Void {
		var args = ["1", "2", "3", "4", "5", "6", "7", "8", "0,5,9", "1,6", "2,7", "3,8", "40", "50", "60", "21", "2", "4", "11", "12", "13", "14", "5,9", "6", "*", "", "1"];
		var data = AccountCustomizeData.parse(args);
		assertEquals(5, data.hat, "hat");
		assertEquals(3, data.hats.length, "owned hats");
		assertEquals(21, data.rank, "rank");
		assertEquals(14, data.feetColor2, "secondary feet color");
		assertEquals("*", data.epicBodies[0], "epic bodies");
		assertEquals(true, data.happyHour, "happy hour");
		assertEquals(null, AccountCustomizeData.parse(["short"]), "short payload rejected");
	}

	private static function testGuildRenderingUsesLinkedClipAndEmblem():Void {
		var handler = new CommandHandler();
		var savedFactory = GuildName.popupFactory;
		var openedGuilds:Array<Int> = [];
		GuildName.popupFactory = function(id:Int):Void openedGuilds.push(id);
		LobbySession.userName = "Tester";
		LobbySession.guildId = 42;
		LobbySession.guildName = "Speed <Guild>";
		LobbySession.emblem = "speed.png";
		var tab = new AccountTab();
		tab.initialize();
		handler.dispatch("setCustomizeInfo", customizeArgs());

		var guildName = @:privateAccess tab.guildName;
		assertNotNull(guildName, "guilded account renders GuildName clip");
		assertEquals(40.0, guildName.x, "account GuildName x matches Flash placement");
		assertEquals(54.0, guildName.y, "account GuildName y matches Flash placement");
		assertEquals(145.0, guildName.nameWidthForTests(), "account GuildName uses wide account width");
		assertEquals(false, guildName.nameHtmlForTests().indexOf("<b>") >= 0, "account GuildName uses plain text");
		assertEquals(true, guildName.nameHtmlForTests().indexOf("&lt;Guild&gt;") >= 0, "account GuildName escapes guild name");
		assertEquals("speed.png", guildName.emblemForTests().getFileName(), "account GuildName loads emblem");
		guildName.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(1, openedGuilds.length, "account GuildName remains clickable");
		assertEquals(42, openedGuilds[0], "account GuildName routes guild id");

		tab.remove();
		assertEquals(true, guildName.isRemoved(), "account tab removal cleans GuildName clip");
		GuildName.popupFactory = savedFactory;
		LobbySession.guildId = 0;
		LobbySession.guildName = "";
		LobbySession.emblem = "";
	}

	private static function testAccountSummaryValuesArePlainText():Void {
		var handler = new CommandHandler();
		LobbySession.userName = "Tester";
		LobbySession.guildId = 0;
		LobbySession.guildName = "";
		LobbySession.emblem = "";
		var tab = new AccountTab();
		tab.initialize();
		handler.dispatch("setCustomizeInfo", customizeArgs());
		var art = @:privateAccess tab.art;

		assertNotContains(fieldHtml(art, "nameBox"), "<b>", "account username is not bold");
		assertNotContains(fieldHtml(art, "rankBox"), "<b>", "account rank is not bold");
		assertNotContains(fieldHtml(art, "hatBox"), "<b>", "account hats count is not bold");
		assertNotContains(fieldHtml(art, "guildBox"), "<b>", "account empty guild value is not bold");
		tab.remove();
	}

	private static function testLoadoutsHoverPlacementAndCleanup():Void {
		var handler = new CommandHandler();
		var tab = new AccountTab();
		tab.initialize();
		handler.dispatch("setCustomizeInfo", customizeArgs());
		@:privateAccess tab.showLoadoutsHover();
		var hover = @:privateAccess tab.loadoutsHover;
		assertNotNull(hover, "loadouts hover is created after the delay callback");
		assertEquals(true, Math.abs(hover.x - (hover.width + 27.5)) < 0.001, "loadouts hover applies Flash horizontal offset");

		@:privateAccess tab.hideLoadoutsHover();
		assertEquals(null, @:privateAccess tab.loadoutsHover, "loadouts hover hides on mouse out/remove path");
		tab.remove();
	}

	private static function testHotkeyBlockingMatchesFlash():Void {
		var handler = new CommandHandler();
		var tab = new AccountTab();
		tab.initialize();
		handler.dispatch("setCustomizeInfo", customizeArgs());
		closeAllPopups();

		var selectable = new TextField();
		selectable.selectable = true;
		selectable.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):Void {
			@:privateAccess tab.onKeyDown(e);
		});
		var blockedByText = new KeyboardEvent(KeyboardEvent.KEY_DOWN, false, true, 0, 49);
		selectable.dispatchEvent(blockedByText);
		assertEquals(0, Popup.getOpen().length, "selectable text blocks loadout hotkeys");
		assertEquals(true, blockedByText.isDefaultPrevented(), "selectable text hotkey prevents default");

		var nonSelectable = new TextField();
		nonSelectable.selectable = false;
		nonSelectable.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):Void {
			@:privateAccess tab.onKeyDown(e);
		});
		nonSelectable.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, false, true, 0, 49));
		assertEquals(1, Popup.getOpen().length, "non-selectable text does not block loadout hotkeys");
		closeAllPopups();

		CourseMenu.instance = cast {};
		var blockedByCourseMenu = new KeyboardEvent(KeyboardEvent.KEY_DOWN, false, true, 0, 49);
		@:privateAccess tab.onKeyDown(blockedByCourseMenu);
		assertEquals(0, Popup.getOpen().length, "open CourseMenu blocks loadout hotkeys");
		assertEquals(true, blockedByCourseMenu.isDefaultPrevented(), "CourseMenu hotkey prevents default");
		CourseMenu.instance = null;
		tab.remove();
	}

	private static function testPresetListingThumbnailsMaskNonEpicSecondColors():Void {
		Settings.disablePersistenceForTests();
		Settings.init("Tester");
		Settings.setValue(Settings.PRESETS, [{
			num: 1, speed: 50, acceleration: 50, jumping: 50,
			hat: 5, head: 6, body: 7, feet: 8,
			hatColor: 1, headColor: 2, bodyColor: 3, feetColor: 4,
			hatColor2: 101, headColor2: 102, bodyColor2: 103, feetColor2: 104
		}]);
		Presets.resetForTests();
		var character = new AccountCharacter();
		var stats = new StatsSelect(150, 50, 50, 50);
		var display = new PlayerDisplay(character, ["5", "9"], ["6"], ["7"], ["8"], 5, 6, 7, 8, 0, 0, 0, 0,
			["9"], ["6"], ["*"], [], 0, 0, 0, 0);

		var popup = new LoadoutsPopup(character, stats, display);
		var preview = popup.previewsForTests()[0];
		assertEquals(-1, preview.hat1Color2, "preset listing masks non-epic hat secondary color");
		assertEquals(102, preview.headColor2, "preset listing keeps epic head secondary color");
		assertEquals(103, preview.bodyColor2, "preset listing keeps Epic Everything secondary color");
		assertEquals(-1, preview.feetColor2, "preset listing masks non-epic feet secondary color");

		popup.remove();
		display.remove();
		stats.remove();
		character.remove();
		Settings.disablePersistenceForTests();
		Presets.resetForTests();
		closeAllPopups();
	}

	private static function testHotkeyConfirmAppliesPreset():Void {
		Settings.disablePersistenceForTests();
		Settings.init("Tester");
		Settings.setValue(Settings.PRESETS, [{
			num: 1, speed: 11, acceleration: 12, jumping: 13,
			hat: 9, head: 6, body: 7, feet: 8,
			hatColor: 101, headColor: 102, bodyColor: 103, feetColor: 104,
			hatColor2: -1, headColor2: -1, bodyColor2: -1, feetColor2: -1
		}]);
		Presets.resetForTests();
		var handler = new CommandHandler();
		var tab = new AccountTab();
		tab.initialize();
		handler.dispatch("setCustomizeInfo", customizeArgs());
		closeAllPopups();

		@:privateAccess tab.onKeyDown(new KeyboardEvent(KeyboardEvent.KEY_DOWN, false, true, 0, 49));
		var confirm = Std.downcast(Popup.getOpen()[0], ConfirmPopup);
		assertNotNull(confirm, "loadout hotkey opens confirmation popup");
		assertEquals(5, @:privateAccess tab.character.hat1, "preset is not applied before confirmation");
		@:privateAccess confirm.clickOk();
		assertEquals(9, @:privateAccess tab.character.hat1, "confirm OK applies preset hat");
		assertEquals(6, @:privateAccess tab.character.head, "confirm OK applies preset head");
		assertEquals(7, @:privateAccess tab.character.body, "confirm OK applies preset body");
		assertEquals(8, @:privateAccess tab.character.feet, "confirm OK applies preset feet");
		assertEquals("11`12`13", @:privateAccess tab.stats.getInfoStr(), "confirm OK applies preset stats");
		closeAllPopups();
		tab.remove();
		Settings.disablePersistenceForTests();
		Presets.resetForTests();
	}

	private static function testManualPartDispatchSavesOverrideAndRefreshes():Void {
		var handler = new CommandHandler();
		LobbySession.userName = "Tester";
		LobbySocket.resetSent();
		var tab = new AccountTab();
		tab.initialize();
		handler.dispatch("setCustomizeInfo", customizeArgs());
		LobbySocket.resetSent();

		AccountTab.setManualPart("head", 42);

		assertEquals(2, LobbySocket.sentCommands.length, "manual part writes save then refresh");
		assertEquals("set_customize_info`1`2`3`4`11`12`13`-1`5`42`7`8`40`50`60", LobbySocket.sentCommands[0],
			"manual part override preserves colors/current parts and replaces requested part");
		assertEquals("get_customize_info`", LobbySocket.sentCommands[1], "manual part refreshes customize info");
		assertEquals(0, AccountTab.partToSet.length, "manual part reset clears pending override");
		tab.remove();
	}

	private static function testRankTokenChangesRetestLevelAccess():Void {
		var handler = new CommandHandler();
		var levelAccessChecks = 0;
		handler.defineCommand("testLevelAccess", function(_):Void levelAccessChecks++);
		LobbySocket.resetSent();
		var tab = new AccountTab();
		tab.initialize();
		handler.dispatch("setCustomizeInfo", customizeArgs());
		levelAccessChecks = 0;
		LobbySocket.resetSent();

		@:privateAccess tab.useRankToken();
		assertEquals("use_rank_token`", LobbySocket.sentCommands[0], "rank up emits use token command");
		assertEquals("get_customize_info`", LobbySocket.sentCommands[1], "rank up refreshes customize info");
		assertEquals(22.0, SecureData.getNumber("userRank"), "rank up updates local rank gate data");
		assertEquals(1, levelAccessChecks, "rank up retests level access immediately");

		@:privateAccess tab.unuseRankToken();
		assertEquals("unuse_rank_token`", LobbySocket.sentCommands[2], "rank down emits unuse token command");
		assertEquals("get_customize_info`", LobbySocket.sentCommands[3], "rank down refreshes customize info");
		assertEquals(21.0, SecureData.getNumber("userRank"), "rank down updates local rank gate data");
		assertEquals(2, levelAccessChecks, "rank down retests level access immediately");
		tab.remove();
	}

	private static function testStatSlidersDoNotRunUnderRightArrow():Void {
		var stats = new StatsSelect(150, 40, 50, 60);
		var speedSlider = @:privateAccess stats.speedSlider;
		var accelSlider = @:privateAccess stats.accelSlider;
		var jumpSlider = @:privateAccess stats.jumpnSlider;

		assertEquals(80.0, @:privateAccess speedSlider.slider.trackWidth, "speed slider track ends before right arrow");
		assertEquals(80.0, @:privateAccess accelSlider.slider.trackWidth, "acceleration slider track ends before right arrow");
		assertEquals(80.0, @:privateAccess jumpSlider.slider.trackWidth, "jumping slider track ends before right arrow");
		stats.remove();
	}

	private static function testHotkeys():Void {
		assertEquals(1, AccountTab.keyToSlot(49), "number one");
		assertEquals(10, AccountTab.keyToSlot(48), "number zero");
		assertEquals(5, AccountTab.keyToSlot(101), "numpad five");
		assertEquals(-1, AccountTab.keyToSlot(65), "non-number");
	}

	private static function testHoverDelayPopupCleanup():Void {
		var wrapper = new HoverDelayPopup("Title", "Body", 500);
		@:privateAccess wrapper.showPopup();
		assertNotNull(wrapper.hover, "direct show creates delayed hover popup");
		wrapper.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		assertEquals(null, wrapper.hover, "mouse down hides shown hover popup");
		@:privateAccess wrapper.showPopup();
		wrapper.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals(null, wrapper.hover, "mouse out hides shown hover popup");
		@:privateAccess wrapper.showPopup();
		wrapper.remove();
		assertEquals(null, wrapper.hover, "remove cleans shown hover popup");
	}

	private static function testPartInfoHoverAndPopupEntry():Void {
		closeAllPopups();
		var character = new AccountCharacter();
		var display = new PlayerDisplay(character, ["1", "2"], ["1", "6"], ["2", "7"], ["3", "8"], 1, 6, 7, 8, 0, 0, 0, 0,
			["2"], ["6"], ["7"], ["8"], 0, 0, 0, 0);

		@:privateAccess display.showInfo("head");
		var hover = @:privateAccess display.hover;
		assertNotNull(hover, "part info delay callback creates hover");
		assertEquals(true, Math.abs(hover.x - (hover.width + 25)) < 0.001, "part info hover applies Flash horizontal offset");
		display.headSelect.infoButton.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
		assertEquals(null, @:privateAccess display.hover, "part info mouse out clears hover");

		display.headSelect.infoButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		var first = PartInfoPopup.instance;
		assertNotNull(first, "part info click opens popup singleton");
		assertEquals("head", first.mode, "part info popup stores mode");
		assertEquals("1,6", first.ownedParts.join(","), "part info popup receives owned parts");
		assertEquals("6", first.ownedEpics.join(","), "part info popup receives epic parts");
		assertEquals(false, first.hasEpicEverything, "part info popup tracks EE state");

		display.feetSelect.infoButton.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		assertEquals(true, first.fadeOutStarted, "opening another part info popup fades existing singleton");
		assertEquals("feet", PartInfoPopup.instance.mode, "new singleton stores clicked mode");
		PartInfoPopup.instance.remove();
		display.remove();
		character.remove();
		closeAllPopups();
	}

	private static function testPartPopupSpecialRenderingObtainLinksAndEquip():Void {
		closeAllPopups();
		AccountTab.partToSet = [];

		var cheese = new PartPopup("HAT", 16, "Cheese", Parts.getDesc("HAT", 16), Parts.getObtain("HAT", 16), false, false);
		assertContains(cheese.obtainHtmlForTests(), "event:level`6207945", "cheese obtain text links the hidden hat level");
		assertContains(cheese.obtainHtmlForTests(), "ktosss450", "cheese obtain text links the creator");
		assertEquals(true, cheese.colorMC2VisibleForTests(), "cheese hat shows secondary color even before ownership");
		assertEquals(false, cheese.equipEnabledForTests(), "unowned part keeps Equip disabled");
		cheese.remove();

		var slender = new PartPopup("BODY", 32, "Slender", Parts.getDesc("BODY", 32), Parts.getObtain("BODY", 32), false, false);
		assertContains(slender.obtainHtmlForTests(), "event:level`1896157", "non-hat obtain text links special source level");
		assertContains(slender.obtainHtmlForTests(), "changelings", "non-hat obtain text links special creator");
		slender.remove();

		var first = new PartPopup("HAT", 15, "Jellyfish", Parts.getDesc("HAT", 15), Parts.getObtain("HAT", 15), true, false);
		var second = new PartPopup("BODY", 29, "Fred", Parts.getDesc("BODY", 29), Parts.getObtain("BODY", 29), true, false);
		assertEquals(true, first.fadeOutStarted, "opening a part detail fades the previous singleton");
		assertEquals(second, PartPopup.instance, "new part detail becomes singleton");
		assertEquals(true, second.targetForTests().y > -18.15, "Fred body preview applies Flash vertical adjustment");
		second.remove();
		first.remove();

		var artifact = new PartPopup("HAT", 14, "Artifact", Parts.getDesc("HAT", 14), Parts.getObtain("HAT", 14), true, true);
		assertEquals(true, artifact.targetForTests().y > 28.75, "artifact hat preview applies Flash vertical adjustment");
		assertEquals("You own this epic upgrade!", artifact.epicTextForTests(), "owned epic part uses Flash epic copy");
		assertEquals(true, artifact.epicFlashHasItemsForTests(), "owned epic part registers EpicFlash targets");
		artifact.remove();

		var djinn = new PartPopup("BODY", 35, "Frost Djinn", Parts.getDesc("BODY", 35), Parts.getObtain("BODY", 35), false, false);
		assertNotNull(djinn.djinnPreviewForTests(), "Djinn body uses full-character preview");
		assertEquals(0.1, djinn.djinnPreviewForTests().alpha, "unowned Djinn preview is dimmed");
		djinn.remove();

		var info = new PartInfoPopup("hat", ["16"], ["16"]);
		var cheeseListing = info.listingsForTests()[info.listingsForTests().length - 1];
		assertEquals(true, cheeseListing.colorMC2VisibleForTests(), "catalog row preserves cheese secondary color special case");
		@:privateAccess cheeseListing.clickHandler(new MouseEvent(MouseEvent.CLICK));
		var detail = PartPopup.instance;
		assertNotNull(detail, "catalog row click opens part detail popup");
		@:privateAccess detail.equipPart(new MouseEvent(MouseEvent.CLICK));
		assertEquals("hat", AccountTab.partToSet[0], "detail Equip dispatches manual part type");
		assertEquals(16, AccountTab.partToSet[1], "detail Equip dispatches manual part id");
		assertEquals(true, detail.fadeOutStarted, "detail Equip fades the detail popup");
		assertEquals(true, info.fadeOutStarted, "detail Equip fades the catalog popup");
		closeAllPopups();
	}

	private static function testPartInfoPopupCatalogRows():Void {
		closeAllPopups();
		var popup = new PartInfoPopup("head", ["1", "6"], ["6"]);
		var listings = popup.listingsForTests();
		assertEquals(Parts.getPartArray("head").length, listings.length, "part info popup populates Parts catalog rows");
		assertEquals(0.0, listings[0].x, "first listing starts first column");
		assertEquals(137.0, listings[1].x, "second listing uses Flash column width");
		assertEquals(160.0, listings[3].y, "fourth listing starts second row");
		assertEquals(1, listings[0].partIdForTests(), "first head row preserves part id");
		assertEquals("HEAD", listings[0].partTypeForTests(), "listing stores normalized type");
		assertEquals(true, listings[0].ownedVisibleForTests(), "owned part shows authored owned box");
		assertEquals(false, listings[0].epicVisibleForTests(), "owned non-epic part hides epic box");
		assertEquals(true, listings[5].ownedVisibleForTests(), "owned epic part shows owned box");
		assertEquals(true, listings[5].epicVisibleForTests(), "owned epic part shows epic box");
		assertEquals("Upgraded!", listings[5].epicTextForTests(), "owned epic part uses Flash upgraded copy");
		assertEquals(false, listings[6].ownedVisibleForTests(), "unowned part hides owned box");
		assertEquals(false, listings[6].epicVisibleForTests(), "unowned part hides epic box");
		popup.remove();

		var eePopup = new PartInfoPopup("head", ["1"], ["*"]);
		var eeListings = eePopup.listingsForTests();
		assertEquals(true, eePopup.hasEpicEverything, "popup tracks epic everything state");
		assertEquals(true, eeListings[0].epicVisibleForTests(), "EE shows epic state for owned non-epic parts");
		eePopup.remove();
		closeAllPopups();
	}

	private static function testRandomizeStyleButtonUsesDelayedHover():Void {
		var character = new AccountCharacter();
		var display = new PlayerDisplay(character, ["1", "2"], ["1", "2"], ["1", "2"], ["1", "2"], 1, 1, 1, 1, 0, 0, 0, 0,
			["1"], ["1"], ["1"], ["1"], 0, 0, 0, 0);
		var button = @:privateAccess display.randomButton;
		assertNotNull(button, "player display mounts randomize button");
		assertEquals("Randomize Style", button.title, "randomize button hover title");
		assertEquals("Create a random style for your character. Remember to save your current style if you like it first!", button.content,
			"randomize button hover copy");
		var randomGraphic = @:privateAccess display.randomGraphic;
		assertNotNull(randomGraphic, "randomize button mounts item-block graphic");
		assertEquals("ItemBlock", randomGraphic.name, "randomize button uses item block art");
		assertEquals(15.0, randomGraphic.width, "randomize item block is small");
		assertEquals(15.0, randomGraphic.height, "randomize item block stays square");
		display.remove();
		character.remove();
	}

	private static function fieldHtml(container:Dynamic, name:String):String {
		var field = Std.downcast(DisplayUtil.findByName(container, name), TextField);
		return field == null ? "" : field.htmlText;
	}

	private static function customizeArgs():Array<String> {
		return ["1", "2", "3", "4", "5", "6", "7", "8", "0,5,9", "1,6", "2,7", "3,8", "40", "50", "60", "21", "2",
			"4", "11", "12", "13", "14", "5,9", "6", "*", "", "1"];
	}

	private static function closeAllPopups():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) throw '$message: value was null';
	}

	private static function assertContains(haystack:String, needle:String, message:String):Void {
		assertions++;
		if (haystack == null || haystack.indexOf(needle) < 0) throw '$message: expected to find $needle in $haystack';
	}

	private static function assertNotContains(haystack:String, needle:String, message:String):Void {
		assertions++;
		if (haystack != null && haystack.indexOf(needle) >= 0) throw '$message: did not expect to find $needle in $haystack';
	}
}
