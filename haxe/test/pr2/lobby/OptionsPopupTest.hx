package pr2.lobby;

import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.lobby.account.Settings;
import pr2.lobby.account.AlternateControls;
import pr2.lobby.dialogs.ChangePasswordPopup;
import pr2.lobby.dialogs.OptionsPopup;
import pr2.lobby.dialogs.Popup;
import pr2.runtime.FlCheckBox;
import pr2.runtime.FlSlider;
import pr2.util.DisplayUtil;

class OptionsPopupTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		var savedGroup = LobbySession.group;
		LobbySession.group = 1;
		Settings.useMemoryStoreForTests();
		Settings.init("Options Tester");
		Settings.setValue(Settings.MUSIC_VOLUME, 35);
		Settings.setValue(Settings.SOUND_VOLUME, 45);
		Settings.setValue(Settings.DISABLED_SONGS, ["2", "17"]);
		var popup = new OptionsPopup();
		assertEquals(true, DisplayUtil.findByName(popup, "changePass_bt").visible, "members can open change-password dialog");
		click(popup, "changePass_bt");
		var open = Popup.getOpen();
		var changePass = Std.downcast(open[open.length - 1], ChangePasswordPopup);
		assertNotNull(changePass, "change-password button opens the authored dialog");
		changePass.remove();

		var music = slider(popup, "musicSlider");
		var sound = slider(popup, "soundSlider");
		assertEquals(35.0, music.value, "music slider loads persisted value");
		assertEquals("35%", LobbyArt.text(popup, "musicPercentBox").text, "music label loads persisted value");
		music.value = 62;
		music.dispatchEvent(new Event(Event.CHANGE));
		sound.value = 18;
		sound.dispatchEvent(new Event(Event.CHANGE));
		assertEquals(62, Settings.musicLevel, "music changes persist immediately");
		assertEquals(18, Settings.soundLevel, "sound changes persist immediately");

		click(popup, "filterOff_bt");
		click(popup, "artOff_bt");
		assertEquals(-43.5, DisplayUtil.findByName(popup, "filterHighlight").y, "filter off moves authored highlight");
		assertEquals(false, DisplayUtil.findByName(popup, "art_bt").visible, "art quality is unavailable when art is off");

		click(popup, "artOn_bt");
		click(popup, "art_bt");
		var lossless = checkbox(popup, "lossless_chk");
		lossless.selected = true;
		click(popup, "music_bt");
		assertEquals(false, checkbox(popup, "song2").selected, "disabled song is unchecked");
		assertEquals(true, checkbox(popup, "song3").selected, "enabled song is checked");
		checkbox(popup, "song3").selected = false;

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
		trace('OptionsPopupTest passed $assertions assertions');
	}

	private static function click(popup:OptionsPopup, name:String):Void {
		var target = DisplayUtil.findByName(popup, name);
		if (target == null) throw name + " missing";
		target.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
	}

	private static function slider(popup:OptionsPopup, name:String):FlSlider {
		var value = Std.downcast(DisplayUtil.findByName(popup, name), FlSlider);
		if (value == null) throw name + " missing";
		return value;
	}

	private static function checkbox(popup:OptionsPopup, name:String):FlCheckBox {
		var value = Std.downcast(DisplayUtil.findByName(popup, name), FlCheckBox);
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
}
