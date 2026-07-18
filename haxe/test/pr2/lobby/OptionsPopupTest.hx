package pr2.lobby;

import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.lobby.account.Settings;
import pr2.lobby.account.AlternateControls;
import pr2.lobby.dialogs.ChangePasswordPopup;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.CreateGuildPopup;
import pr2.lobby.dialogs.OptionsArtQualityMenu;
import pr2.lobby.dialogs.OptionsPopup;
import pr2.lobby.dialogs.OptionsSongsMenu;
import pr2.lobby.dialogs.OptionsView;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.SetEmailPopup;
import pr2.lobby.dialogs.TransferGuildPopup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.net.ServerConfig;
import pr2.ui.controls.GameSlider;
import pr2.util.TestDisplayUtil as DisplayUtil;

class OptionsPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var savedGroup = LobbySession.group;
		var savedGuildId = LobbySession.guildId;
		var savedGuildOwner = LobbySession.guildOwner;
		Settings.useMemoryStoreForTests();
		Settings.init("Options Tester");
		testAccountButtonStacks();
		if (pr2.DeterministicTestMode.finishSmokeSuite("OptionsPopupTest")) return;
		testAccountButtonsOpenAuthoredDialogs();
		testGuildLeaveFlow();
		testHoverPopups();
		testSoundSliderRelease();
		testArtQualityMenuSingleton();
		testSongsMenuSingleton();

		LobbySession.group = 1;
		LobbySession.guildId = 0;
		LobbySession.guildOwner = false;
		Settings.setValue(Settings.MUSIC_VOLUME, 35);
		Settings.setValue(Settings.SOUND_VOLUME, 45);
		Settings.setValue(Settings.DISABLED_SONGS, ["2", "17"]);
		var popup = new OptionsPopup();
		var view = optionsView(popup);
		assertNear(-137.5, view.panel.x, 0.000001, "options ShadowBG keeps XFL X");
		assertNear(-145, view.panel.y, 0.000001, "options ShadowBG keeps XFL Y");
		assertNear(1.01094055175781, view.panel.scaleX, 0.000001, "options ShadowBG keeps XFL horizontal scale");
		assertNear(1.51835632324219, view.panel.scaleY, 0.000001, "options ShadowBG keeps XFL vertical scale");
		assertEquals("-- Options --", view.title.text, "options title keeps exact authored copy");

		var music = slider(popup, "musicSlider");
		var sound = slider(popup, "soundSlider");
		assertNear(0, music.transform.matrix.a, 0.000001, "music slider keeps authored matrix a");
		assertNear(1, music.transform.matrix.b, 0.000001, "music slider keeps authored matrix b");
		assertNear(1, music.transform.matrix.c, 0.000001, "music slider keeps authored matrix c");
		assertNear(45.45, music.transform.matrix.tx, 0.000001, "music slider keeps XFL X");
		assertNear(-67.5, music.transform.matrix.ty, 0.000001, "music slider keeps XFL Y");
		assertNear(98.3, sound.transform.matrix.tx, 0.000001, "sound slider keeps XFL X");
		assertNear(-118.2, DisplayUtil.findByName(popup, "artOn_bt").x, 0.000001, "art On keeps XFL X");
		assertNear(-82.45, DisplayUtil.findByName(popup, "artOn_bt").y, 0.000001, "art On keeps XFL Y");
		assertNear(-68.75, LobbyArt.text(popup, "wasdUp").x, 0.000001, "alternate Up field keeps XFL X");
		assertNear(14.5, LobbyArt.text(popup, "wasdUp").y, 0.000001, "alternate Up field keeps XFL Y");
		assertEquals(35.0, music.value, "music slider loads persisted value");
		assertEquals("35%", LobbyArt.text(popup, "musicPercentBox").text, "music label loads persisted value");
		music.value = 62;
		music.dispatchEvent(new Event(Event.CHANGE));
		sound.value = 18;
		sound.dispatchEvent(new Event(Event.CHANGE));
		assertEquals(60, Settings.musicLevel, "music changes persist immediately at authored five-point snap interval");
		assertEquals(20, Settings.soundLevel, "sound changes persist immediately at authored five-point snap interval");

		click(popup, "filterOff_bt");
		click(popup, "artOff_bt");
		assertEquals(-43.5, DisplayUtil.findByName(popup, "filterHighlight").y, "filter off moves authored highlight");
		assertEquals(false, DisplayUtil.findByName(popup, "art_bt").visible, "art quality is unavailable when art is off");

		click(popup, "artOn_bt");
		click(popup, "art_bt");
		var lossless = OptionsArtQualityMenu.instance;
		assertNotNull(lossless, "art button opens art quality singleton");
		lossless.setLosslessForTests(true);
		click(popup, "music_bt");
		var songs = OptionsSongsMenu.instance;
		assertNotNull(songs, "music button opens songs singleton");
		assertEquals(false, songs.isSongSelectedForTests(2), "disabled song is unchecked");
		assertEquals(true, songs.isSongSelectedForTests(3), "enabled song is checked");
		songs.setSongSelectedForTests(3, false);

		var up = LobbyArt.text(popup, "wasdUp");
		up.text = "";
		LobbyArt.text(popup, "wasdItem").text = "X";
		popup.remove();
		var controls:Dynamic = Settings.getValue(Settings.ALTERNATE_CONTROLS, null);
		assertEquals(87, Reflect.field(controls, "up"), "empty control restores Flash default");
		assertEquals(88, Reflect.field(controls, "item"), "custom control persists as key code");
		assertEquals(true, AlternateControls.matches("item", 88), "saved alternate key drives gameplay input");
		assertEquals(false, AlternateControls.matches("item", 73), "replaced alternate key is inactive");
		assertEquals(false, Settings.getValue(Settings.FILTER_SWEARS, true), "filter choice persists on close");
		assertEquals(true, Settings.getValue(Settings.DRAW_ART, false), "art choice persists on close");
		assertEquals(true, Settings.getValue(Settings.ART_LOSSLESS_QUALITY, false), "quality choice persists on close");
		var disabled = Settings.disabledSongs();
		assertEquals(true, disabled.indexOf("2") >= 0 && disabled.indexOf("3") >= 0, "song choices persist on close");

		Settings.setValue(Settings.MUSIC_VOLUME, 100);
		Settings.setValue(Settings.SOUND_VOLUME, 100);
		LobbySession.group = savedGroup;
		LobbySession.guildId = savedGuildId;
		LobbySession.guildOwner = savedGuildOwner;
		closeAll();
		trace('OptionsPopupTest passed $assertions assertions');
	}

	private static function optionsView(popup:OptionsPopup):OptionsView {
		for (index in 0...popup.numChildren) {
			var view = Std.downcast(popup.getChildAt(index), OptionsView);
			if (view != null) return view;
		}
		throw "OptionsView missing";
	}

	private static function testAccountButtonStacks():Void {
		LobbySession.group = 0;
		LobbySession.guildId = 0;
		LobbySession.guildOwner = false;
		var guest = new OptionsPopup();
		assertMissing(guest, "changePass_bt", "guest has no change-password button");
		assertMissing(guest, "changeEmail_bt", "guest has no change-email button");
		assertMissing(guest, "guildCreate_bt", "guest has no guild-create button");
		guest.remove();

		LobbySession.group = 1;
		var guildless = new OptionsPopup();
		assertStack(guildless, ["changePass_bt", "changeEmail_bt", "guildCreate_bt"], "guildless member stack");
		assertMissing(guildless, "guildLeave_bt", "guildless member has no leave button");
		guildless.remove();

		LobbySession.guildId = 9;
		LobbySession.guildOwner = true;
		var owner = new OptionsPopup();
		assertStack(owner, ["changePass_bt", "changeEmail_bt", "guildTransfer_bt", "guildEdit_bt"], "owner stack");
		assertMissing(owner, "guildCreate_bt", "owner has no create button");
		owner.remove();

		LobbySession.guildOwner = false;
		var member = new OptionsPopup();
		assertStack(member, ["changePass_bt", "changeEmail_bt", "guildLeave_bt"], "non-owner member stack");
		assertMissing(member, "guildEdit_bt", "non-owner has no edit button");
		member.remove();
	}

	private static function testAccountButtonsOpenAuthoredDialogs():Void {
		LobbySession.group = 1;
		LobbySession.guildId = 0;
		LobbySession.guildOwner = false;
		LobbySession.hasEmail = false;
		var popup = new OptionsPopup();
		click(popup, "changePass_bt");
		var open = Popup.getOpen();
		var changePass = Std.downcast(open[open.length - 1], ChangePasswordPopup);
		assertNotNull(changePass, "change-password button opens the authored dialog");
		assertEquals(true, popup.fadeOutStarted, "change-password fades options popup like Flash");
		closeAll();

		LobbySession.group = 1;
		LobbySession.guildId = 0;
		LobbySession.guildOwner = false;
		LobbySession.hasEmail = false;
		popup = new OptionsPopup();
		click(popup, "changeEmail_bt");
		open = Popup.getOpen();
		var setEmail = Std.downcast(open[open.length - 1], SetEmailPopup);
		assertNotNull(setEmail, "change-email button opens the authored dialog");
		assertEquals(true, LobbySession.hasEmail, "change-email mirrors Flash hasEmail side effect");
		assertEquals(true, popup.fadeOutStarted, "change-email fades options popup like Flash");
		closeAll();

		LobbySession.group = 1;
		LobbySession.guildId = 0;
		LobbySession.guildOwner = false;
		popup = new OptionsPopup();
		click(popup, "guildCreate_bt");
		open = Popup.getOpen();
		var createGuild = Std.downcast(open[open.length - 1], CreateGuildPopup);
		assertNotNull(createGuild, "guild-create button opens the authored dialog");
		assertEquals(true, popup.fadeOutStarted, "guild-create fades options popup like Flash");
		closeAll();

		LobbySession.group = 1;
		LobbySession.guildId = 19;
		LobbySession.guildOwner = true;
		popup = new OptionsPopup();
		click(popup, "guildTransfer_bt");
		open = Popup.getOpen();
		var transferGuild = Std.downcast(open[open.length - 1], TransferGuildPopup);
		assertNotNull(transferGuild, "guild-transfer button opens the authored dialog");
		assertEquals(true, popup.fadeOutStarted, "guild-transfer fades options popup like Flash");
		closeAll();

		LobbySession.group = 1;
		LobbySession.guildId = 19;
		LobbySession.guildOwner = true;
		popup = new OptionsPopup();
		click(popup, "guildEdit_bt");
		open = Popup.getOpen();
		var editGuild = Std.downcast(open[open.length - 1], CreateGuildPopup);
		assertNotNull(editGuild, "guild-edit button opens the authored dialog");
		assertEquals(true, popup.fadeOutStarted, "guild-edit fades options popup like Flash");
		closeAll();
	}

	private static function testGuildLeaveFlow():Void {
		var savedPostFactory = UploadingPopup.postFactory;
		ServerConfig.setHost("http://example.test");
		LobbySession.group = 1;
		LobbySession.updateGuildState(27, "Leaving Soon", false, "old.png", false);
		var accountChanges = 0;
		var listener = function():Void accountChanges++;
		LobbySession.onAccountChange(listener);
		var posts:Array<{url:String, fields:Map<String, String>, onResult:String->Void}> = [];
		UploadingPopup.postFactory = function(url:String, fields:Map<String, String>, onResult:String->Void, onError:String->Void):Void {
			posts.push({url: url, fields: fields, onResult: onResult});
		};

		var popup = new OptionsPopup();
		click(popup, "guildLeave_bt");
		var open = Popup.getOpen();
		var confirm = Std.downcast(open[open.length - 1], ConfirmPopup);
		assertNotNull(confirm, "guild-leave opens confirmation popup");
		assertEquals(true, LobbyArt.text(confirm, "textBox").htmlText.indexOf("Are you sure you want to leave your guild?") >= 0,
			"guild-leave confirmation copy");
		click(confirm, "ok_bt");
		assertEquals(true, popup.fadeOutStarted, "confirmed guild leave fades options popup");
		assertEquals(1, posts.length, "confirmed guild leave posts once");
		assertEquals(ServerConfig.guildLeaveUrl(), posts[0].url, "guild-leave endpoint");
		assertEquals(0, mapSize(posts[0].fields), "guild-leave posts empty form data");
		var uploading = Std.downcast(Popup.getOpen()[Popup.getOpen().length - 1], UploadingPopup);
		assertNotNull(uploading, "guild-leave opens upload popup");
		assertEquals("Leaving guild...", LobbyArt.text(uploading, "textBox").text, "guild-leave upload label");

		posts[0].onResult('{"success":true}');
		assertEquals(0, LobbySession.guildId, "successful guild leave clears guild id");
		assertEquals("", LobbySession.guildName, "successful guild leave clears guild name");
		assertEquals(false, LobbySession.guildOwner, "successful guild leave clears owner flag");
		assertEquals("", LobbySession.emblem, "successful guild leave clears emblem");
		assertEquals(1, accountChanges, "successful guild leave dispatches account change");

		LobbySession.offAccountChange(listener);
		UploadingPopup.postFactory = savedPostFactory;
		ServerConfig.resetHost();
		closeAll();
	}

	private static function testHoverPopups():Void {
		LobbySession.group = 1;
		LobbySession.guildId = 0;
		LobbySession.guildOwner = false;
		Settings.setValue(Settings.DRAW_ART, true);
		var popup = new OptionsPopup();

		hover(popup, "art_bt", MouseEvent.MOUSE_OVER);
		assertEquals(true, popup.hasActiveHover(), "art button hover opens quality tooltip");
		hover(popup, "art_bt", MouseEvent.MOUSE_OUT);
		assertEquals(false, popup.hasActiveHover(), "art button mouse-out closes quality tooltip");

		click(popup, "artOff_bt");
		hover(popup, "art_bt", MouseEvent.MOUSE_OVER);
		assertEquals(false, popup.hasActiveHover(), "disabled art quality button has no tooltip");

		hover(popup, "music_bt", MouseEvent.MOUSE_OVER);
		assertEquals(true, popup.hasActiveHover(), "music button hover opens song tooltip");
		popup.remove();
		assertEquals(false, popup.hasActiveHover(), "removing options popup clears active hover tooltip");
		closeAll();
	}

	private static function testSoundSliderRelease():Void {
		var savedPlayJumpSound = OptionsPopup.playJumpSound;
		var heard:Array<Float> = [];
		OptionsPopup.playJumpSound = function(volume:Float):Void heard.push(volume);
		LobbySession.group = 1;
		LobbySession.guildId = 0;
		LobbySession.guildOwner = false;
		Settings.setValue(Settings.SOUND_VOLUME, 40);
		var popup = new OptionsPopup();
		var sound = slider(popup, "soundSlider");
		sound.value = 40;
		sound.dispatchEvent(new Event(Event.CHANGE));
		if (sound.onRelease != null) sound.onRelease();
		assertEquals(1, heard.length, "sound slider release plays jump sound once");
		assertNear(0.3, heard[0], 0.0001, "sound slider release scales jump sound volume");
		popup.remove();

		OptionsPopup.playJumpSound = function(volume:Float):Void heard.push(volume);
		if (sound.onRelease != null) sound.onRelease();
		assertEquals(1, heard.length, "removed options popup detaches sound release listener");
		OptionsPopup.playJumpSound = savedPlayJumpSound;
		closeAll();
	}

	private static function testArtQualityMenuSingleton():Void {
		LobbySession.group = 1;
		LobbySession.guildId = 0;
		LobbySession.guildOwner = false;
		Settings.setValue(Settings.DRAW_ART, true);
		Settings.setValue(Settings.ART_LOSSLESS_QUALITY, false);
		var popup = new OptionsPopup();

		click(popup, "art_bt");
		var first = OptionsArtQualityMenu.instance;
		assertNotNull(first, "art quality button creates singleton menu");
		assertEquals(false, first.isLosslessSelectedForTests(), "art quality menu loads persisted lossless value");
		assertEquals(false, first.autoDismissArmedForTests(), "art quality menu waits before outside-click arming");
		first.stageMouseDownForTests(10000, 10000);
		assertEquals(first, OptionsArtQualityMenu.instance, "outside click before arm delay does not dismiss");
		first.armAutoDismissForTests();
		assertEquals(true, first.autoDismissArmedForTests(), "art quality menu arms outside-click dismissal");
		first.stageMouseDownForTests(10000, 10000);
		assertEquals(null, OptionsArtQualityMenu.instance, "outside click after arm delay dismisses menu");

		click(popup, "art_bt");
		first = OptionsArtQualityMenu.instance;
		assertNotNull(first, "art quality menu reopens after dismissal");
		first.setLosslessForTests(true);
		click(popup, "art_bt");
		var second = OptionsArtQualityMenu.instance;
		assertNotNull(second, "art quality click replaces previous singleton");
		assertEquals(true, first.isRemoved(), "new art quality menu removes previous instance");
		assertEquals(true, second.isLosslessSelectedForTests(), "replacement art quality menu reloads saved lossless value");
		second.remove();
		assertEquals(true, Settings.getValue(Settings.ART_LOSSLESS_QUALITY, false), "art quality menu persists lossless value on removal");
		popup.remove();
		closeAll();
	}

	private static function testSongsMenuSingleton():Void {
		LobbySession.group = 1;
		LobbySession.guildId = 0;
		LobbySession.guildOwner = false;
		Settings.setValue(Settings.DISABLED_SONGS, [2, 17]);
		var popup = new OptionsPopup();

		click(popup, "music_bt");
		var first = OptionsSongsMenu.instance;
		assertNotNull(first, "music button creates singleton menu");
		assertEquals(false, first.isSongSelectedForTests(2), "songs menu loads numeric disabled song");
		assertEquals(true, first.isSongSelectedForTests(3), "songs menu keeps enabled song selected");
		assertEquals(-45.0, first.y, "songs menu applies Flash y offset");
		assertEquals(false, first.autoDismissArmedForTests(), "songs menu waits before outside-click arming");
		first.stageMouseDownForTests(10000, 10000);
		assertEquals(first, OptionsSongsMenu.instance, "songs outside click before arm delay does not dismiss");
		first.armAutoDismissForTests();
		first.stageMouseDownForTests(10000, 10000);
		assertEquals(null, OptionsSongsMenu.instance, "songs outside click after arm delay dismisses menu");

		click(popup, "music_bt");
		first = OptionsSongsMenu.instance;
		assertNotNull(first, "songs menu reopens after dismissal");
		first.setSongSelectedForTests(3, false);
		first.setSongSelectedForTests(9, false);
		first.setSongSelectedForTests(16, false);
		click(popup, "music_bt");
		var second = OptionsSongsMenu.instance;
		assertNotNull(second, "music button replaces previous songs singleton");
		assertEquals(true, first.isRemoved(), "new songs menu removes previous instance");
		assertEquals(false, second.isSongSelectedForTests(3), "replacement songs menu reloads persisted disabled song");
		second.remove();
		var raw:Array<Dynamic> = Settings.getValue(Settings.DISABLED_SONGS, []);
		assertEquals(2, raw[0], "songs menu persists disabled song ids numerically");
		assertEquals(true, raw.indexOf(3) >= 0, "songs menu persists newly disabled song");
		assertEquals(false, raw.indexOf(9) >= 0, "songs menu skips unavailable song 9");
		assertEquals(false, raw.indexOf(16) >= 0, "songs menu skips unavailable song 16");
		popup.remove();
		closeAll();
	}

	private static function click(container:openfl.display.DisplayObjectContainer, name:String):Void {
		var target = DisplayUtil.findByName(container, name);
		if (target == null) throw name + " missing";
		target.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	}

	private static function hover(container:openfl.display.DisplayObjectContainer, name:String, type:String):Void {
		var target = DisplayUtil.findByName(container, name);
		if (target == null) throw name + " missing";
		target.dispatchEvent(new MouseEvent(type));
	}

	private static function mapSize(map:Map<String, String>):Int {
		var count = 0;
		for (_ in map.keys()) count++;
		return count;
	}

	private static function slider(popup:OptionsPopup, name:String):GameSlider {
		var value = Std.downcast(DisplayUtil.findByName(popup, name), GameSlider);
		if (value == null) throw name + " missing";
		return value;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) throw message;
	}

	private static function assertNear(expected:Float, actual:Float, tolerance:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > tolerance) throw '$message: expected $expected, got $actual';
	}

	private static function assertMissing(popup:OptionsPopup, name:String, message:String):Void {
		assertions++;
		if (DisplayUtil.findByName(popup, name) != null) throw message;
	}

	private static function assertStack(popup:OptionsPopup, names:Array<String>, label:String):Void {
		for (i in 0...names.length) {
			var button = DisplayUtil.findByName(popup, names[i]);
			assertNotNull(button, label + " has " + names[i]);
			assertEquals(true, button.visible, label + " shows " + names[i]);
			assertEquals(80 - (20 * i), button.y, label + " positions " + names[i]);
		}
	}

	private static function closeAll():Void {
		for (popup in Popup.getOpen().copy()) {
			popup.remove();
		}
	}
}
