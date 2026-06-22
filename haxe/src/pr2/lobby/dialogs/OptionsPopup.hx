package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.events.Event;
import openfl.text.TextField;
import pr2.audio.AudioManager;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.account.Settings;
import pr2.runtime.FlCheckBox;
import pr2.runtime.FlSlider;
import pr2.runtime.FlSliderEvent;
import pr2.runtime.PR2MovieClip;

/** Authored lobby options popup: volume, chat/art toggles, controls and songs. */
class OptionsPopup extends Popup {
	private static inline var TRUE_Y:Float = -71.5;
	private static inline var FALSE_Y:Float = -43.5;
	private static final CONTROL_DEFAULTS = {wasdUp: "W", wasdRight: "D", wasdDown: "S", wasdLeft: "A", wasdItem: "I"};

	private var art:PR2MovieClip;
	private var bindings:Array<Binding> = [];
	private var filterSwears:Bool;
	private var drawArt:Bool;
	private var songsMenu:Null<PR2MovieClip>;
	private var artMenu:Null<PR2MovieClip>;

	public function new() {
		super();
		art = PR2MovieClip.fromLinkage("OptionsPopupGraphic", {maxNestedDepth: 6});
		addChild(art);
		filterSwears = Settings.getValue(Settings.FILTER_SWEARS, true);
		drawArt = Settings.getValue(Settings.DRAW_ART, true);

		var music = slider("musicSlider");
		var sound = slider("soundSlider");
		if (music != null) {
			music.value = Settings.musicLevel;
			music.addEventListener(Event.CHANGE, musicChanged);
		}
		if (sound != null) {
			sound.value = Settings.soundLevel;
			sound.addEventListener(Event.CHANGE, soundChanged);
		}
		setText("musicPercentBox", Settings.musicLevel + "%");
		setText("soundPercentBox", Settings.soundLevel + "%");
		loadControls();
		setHighlight("filterHighlight", filterSwears);
		setHighlight("artHighlight", drawArt);

		bind("filterOn_bt", function() setFilter(true));
		bind("filterOff_bt", function() setFilter(false));
		bind("artOn_bt", function() setDrawArt(true));
		bind("artOff_bt", function() setDrawArt(false));
		bind("art_bt", toggleArtMenu);
		bind("music_bt", toggleSongsMenu);
		bind("close_bt", startFadeOut);
		for (name in ["changePass_bt", "changeEmail_bt", "guildLeave_bt", "guildCreate_bt", "guildEdit_bt", "guildTransfer_bt"]) {
			var button = LobbyArt.findByName(art, name);
			if (button != null) button.visible = false;
		}
	}

	private function slider(name:String):Null<FlSlider> return Std.downcast(LobbyArt.findByName(art, name), FlSlider);
	private function text(name:String):Null<TextField> return LobbyArt.text(art, name);
	private function setText(name:String, value:String):Void { var field = text(name); if (field != null) field.text = value; }
	private function bind(name:String, handler:Void->Void):Void {
		var binding = LobbyArt.bind(LobbyArt.findByName(art, name), handler);
		if (binding != null) bindings.push(binding);
	}

	private function musicChanged(_:Event):Void {
		var control = slider("musicSlider");
		if (control == null) return;
		Settings.setValue(Settings.MUSIC_VOLUME, Std.int(control.value));
		setText("musicPercentBox", Settings.musicLevel + "%");
		AudioManager.musicLevelChanged();
	}

	private function soundChanged(_:Event):Void {
		var control = slider("soundSlider");
		if (control == null) return;
		Settings.setValue(Settings.SOUND_VOLUME, Std.int(control.value));
		setText("soundPercentBox", Settings.soundLevel + "%");
	}

	private function setFilter(value:Bool):Void { filterSwears = value; setHighlight("filterHighlight", value); }
	private function setDrawArt(value:Bool):Void {
		drawArt = value;
		setHighlight("artHighlight", value);
		var button = LobbyArt.findByName(art, "art_bt");
		var offText = LobbyArt.findByName(art, "artOffText");
		if (button != null) button.visible = value;
		if (offText != null) offText.visible = !value;
		if (!value) closeArtMenu();
	}
	private function setHighlight(name:String, value:Bool):Void { var target = LobbyArt.findByName(art, name); if (target != null) target.y = value ? TRUE_Y : FALSE_Y; }

	private function loadControls():Void {
		var controls:Dynamic = Settings.getValue(Settings.ALTERNATE_CONTROLS, Settings.DEFAULT_ALT_CONTROLS);
		for (field in Reflect.fields(CONTROL_DEFAULTS)) {
			var input = text(field);
			if (input == null) continue;
			input.maxChars = 1;
			input.restrict = "0-9 A-Z a-z";
			var key = field.substr(4).toLowerCase();
			var code:Null<Int> = Reflect.field(controls, key);
			input.text = code == null ? Reflect.field(CONTROL_DEFAULTS, field) : String.fromCharCode(code).toUpperCase();
		}
	}

	private function saveControls():Void {
		var controls:Dynamic = {};
		for (field in Reflect.fields(CONTROL_DEFAULTS)) {
			var input = text(field);
			var value = input == null ? "" : input.text.toUpperCase();
			if (value == "") value = Reflect.field(CONTROL_DEFAULTS, field);
			if (input != null) input.text = value;
			Reflect.setField(controls, field.substr(4).toLowerCase(), value.charCodeAt(0));
		}
		Settings.setValue(Settings.ALTERNATE_CONTROLS, controls);
	}

	private function toggleArtMenu():Void {
		if (!drawArt) return;
		if (artMenu != null) { closeArtMenu(); return; }
		artMenu = PR2MovieClip.fromLinkage("OptionsArtQualityMenuGraphic", {maxNestedDepth: 4});
		artMenu.x = -105;
		artMenu.y = -105;
		var check = Std.downcast(LobbyArt.findByName(artMenu, "lossless_chk"), FlCheckBox);
		if (check != null) check.selected = Settings.getValue(Settings.ART_LOSSLESS_QUALITY, false);
		addChild(artMenu);
	}

	private function closeArtMenu():Void {
		if (artMenu == null) return;
		var check = Std.downcast(LobbyArt.findByName(artMenu, "lossless_chk"), FlCheckBox);
		if (check != null) Settings.setValue(Settings.ART_LOSSLESS_QUALITY, check.selected);
		artMenu.dispose();
		if (artMenu.parent != null) artMenu.parent.removeChild(artMenu);
		artMenu = null;
	}

	private function toggleSongsMenu():Void {
		if (songsMenu != null) { closeSongsMenu(); return; }
		songsMenu = PR2MovieClip.fromLinkage("OptionsSongsMenuGraphic", {maxNestedDepth: 4});
		songsMenu.x = -205;
		songsMenu.y = -155;
		var disabled = Settings.disabledSongs();
		for (i in 1...22) if (i != 9 && i != 16) {
			var check = Std.downcast(LobbyArt.findByName(songsMenu, "song" + i), FlCheckBox);
			if (check != null) check.selected = disabled.indexOf(Std.string(i)) < 0;
		}
		addChild(songsMenu);
	}

	private function closeSongsMenu():Void {
		if (songsMenu == null) return;
		var disabled:Array<String> = [];
		for (i in 1...22) if (i != 9 && i != 16) {
			var check = Std.downcast(LobbyArt.findByName(songsMenu, "song" + i), FlCheckBox);
			if (check != null && !check.selected) disabled.push(Std.string(i));
		}
		Settings.setValue(Settings.DISABLED_SONGS, disabled);
		songsMenu.dispose();
		if (songsMenu.parent != null) songsMenu.parent.removeChild(songsMenu);
		songsMenu = null;
	}

	override public function remove():Void {
		closeArtMenu();
		closeSongsMenu();
		saveControls();
		Settings.setValue(Settings.DRAW_ART, drawArt);
		Settings.setValue(Settings.FILTER_SWEARS, filterSwears);
		for (binding in bindings) LobbyArt.unbind(binding);
		bindings = [];
		var music = slider("musicSlider");
		var sound = slider("soundSlider");
		if (music != null) music.removeEventListener(Event.CHANGE, musicChanged);
		if (sound != null) sound.removeEventListener(Event.CHANGE, soundChanged);
		if (art != null) {
			art.dispose();
			if (art.parent != null) art.parent.removeChild(art);
			art = null;
		}
		super.remove();
	}
}
