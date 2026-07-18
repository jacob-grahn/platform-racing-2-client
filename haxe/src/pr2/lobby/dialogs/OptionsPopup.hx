package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.utils.Assets;
import pr2.audio.AudioManager;
import pr2.audio.SoundEffects;
import pr2.gameplay.RaceSounds;
import pr2.lobby.LobbySession;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.account.Settings;
import pr2.net.ServerConfig;
import pr2.ui.controls.GameSlider;
import pr2.util.DisplayUtil;

/** Authored lobby options popup: volume, chat/art toggles, controls and songs. */
class OptionsPopup extends Popup {
	private static inline var TRUE_Y:Float = -71.5;
	private static inline var FALSE_Y:Float = -43.5;
	private static final CONTROL_DEFAULTS = {wasdUp: "W", wasdRight: "D", wasdDown: "S", wasdLeft: "A", wasdItem: "I"};
	public static var playJumpSound:Float->Void = defaultPlayJumpSound;

	private var art:OptionsView;
	private var bindings:Array<Binding> = [];
	private var hoverCleanups:Array<Void->Void> = [];
	private var filterSwears:Bool;
	private var drawArt:Bool;
	private var accountButtons:Null<PopupButtonStack>;
	private var hoverActive:Null<HoverPopup>;

	public function new() {
		super();
		art = new OptionsView();
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
			sound.onRelease = function():Void soundSliderRelease(null);
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
		bindHover("art_bt", hoverArt, hoverOut);
		bindHover("music_bt", hoverMusic, hoverOut);
		bind("close_bt", startFadeOut);
		setupAccountButtons();
	}

	private function slider(name:String):Null<GameSlider> return Std.downcast(DisplayUtil.directChildByName(art, name), GameSlider);
	private function text(name:String):Null<TextField> return LobbyArt.directText(art, name);
	private function setText(name:String, value:String):Void { var field = text(name); if (field != null) field.text = value; }
	private function bind(name:String, handler:Void->Void):Void {
		var binding = LobbyArt.bind(DisplayUtil.directChildByName(art, name), handler);
		if (binding != null) bindings.push(binding);
	}

	private function bindHover(name:String, over:Void->Void, out:Void->Void):Void {
		var target = DisplayUtil.directChildByName(art, name);
		if (target == null) return;
		var onOver = function(_:Event):Void over();
		var onOut = function(_:Event):Void out();
		target.addEventListener(openfl.events.MouseEvent.MOUSE_OVER, onOver);
		target.addEventListener(openfl.events.MouseEvent.MOUSE_OUT, onOut);
		hoverCleanups.push(function():Void {
			target.removeEventListener(openfl.events.MouseEvent.MOUSE_OVER, onOver);
			target.removeEventListener(openfl.events.MouseEvent.MOUSE_OUT, onOut);
		});
	}

	public function hasActiveHover():Bool {
		return hoverActive != null;
	}

	private function setupAccountButtons():Void {
		accountButtons = new PopupButtonStack(art, 80, 20);
		var buttons:Map<String, DisplayObject> = new Map();
		for (name in ["changePass_bt", "changeEmail_bt", "guildLeave_bt", "guildCreate_bt", "guildEdit_bt", "guildTransfer_bt"]) {
			var button = DisplayUtil.directChildByName(art, name);
			if (button != null) buttons.set(name, button);
		}
		for (button in buttons) {
			accountButtons.hide(button);
		}
		if (!LobbySession.isMember()) return;
		accountButtons.add(buttons.get("changePass_bt"), function():Void {
			new ChangePasswordPopup();
			startFadeOut();
		});
		accountButtons.add(buttons.get("changeEmail_bt"), function():Void {
			new SetEmailPopup();
			LobbySession.hasEmail = true;
			startFadeOut();
		});
		if (LobbySession.guildId == 0) {
			accountButtons.add(buttons.get("guildCreate_bt"), function():Void {
				new CreateGuildPopup(0);
				startFadeOut();
			});
		} else if (LobbySession.guildOwner) {
			accountButtons.add(buttons.get("guildTransfer_bt"), function():Void {
				new TransferGuildPopup();
				startFadeOut();
			});
			accountButtons.add(buttons.get("guildEdit_bt"), function():Void {
				new CreateGuildPopup(LobbySession.guildId);
				startFadeOut();
			});
		} else {
			accountButtons.add(buttons.get("guildLeave_bt"), function():Void {
				new ConfirmPopup(confirmLeaveGuild, "Are you sure you want to leave your guild?");
			});
		}
	}

	private function confirmLeaveGuild():Void {
		new UploadingPopup(ServerConfig.guildLeaveUrl(), new Map<String, String>(), "Leaving guild...", doLeaveGuild);
		startFadeOut();
	}

	private function doLeaveGuild(ret:Dynamic):Void {
		if (ret != null && Reflect.field(ret, "success") == true) {
			LobbySession.clearGuild();
		}
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

	private function soundSliderRelease(_:Event):Void {
		playJumpSound(0.75 * (Settings.soundLevel / 100));
	}

	private function setFilter(value:Bool):Void { filterSwears = value; setHighlight("filterHighlight", value); }
	private function setDrawArt(value:Bool):Void {
		drawArt = value;
		setHighlight("artHighlight", value);
		var button = DisplayUtil.directChildByName(art, "art_bt");
		var offText = DisplayUtil.directChildByName(art, "artOffText");
		if (button != null) button.visible = value;
		if (offText != null) offText.visible = !value;
		if (!value) closeArtMenu();
		if (!value) hoverOut();
	}
	private function setHighlight(name:String, value:Bool):Void { var target = DisplayUtil.directChildByName(art, name); if (target != null) target.y = value ? TRUE_Y : FALSE_Y; }

	private function hoverArt():Void {
		if (!drawArt) return;
		hoverOut();
		var target = DisplayUtil.directChildByName(art, "art_bt");
		if (target != null) {
			hoverActive = new HoverPopup("Choose Art Quality",
				"Choose whether to draw art with lossless quality. This setting may degrade performance on some systems.", target);
			hoverActive.x += 5;
		}
	}

	private function hoverMusic():Void {
		hoverOut();
		var target = DisplayUtil.directChildByName(art, "music_bt");
		if (target != null) {
			hoverActive = new HoverPopup("Choose Music", "Choose which songs are allowed to play in a level.", target);
		}
	}

	private function hoverOut():Void {
		if (hoverActive != null) {
			hoverActive.remove();
			hoverActive = null;
		}
	}

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
		var target = DisplayUtil.directChildByName(art, "art_bt");
		if (target != null) {
			new OptionsArtQualityMenu(target);
		}
	}

	private function closeArtMenu():Void {
		if (OptionsArtQualityMenu.instance != null) {
			OptionsArtQualityMenu.instance.remove();
		}
	}

	private function toggleSongsMenu():Void {
		var target = DisplayUtil.directChildByName(art, "music_bt");
		if (target != null) {
			new OptionsSongsMenu(target);
		}
	}

	private function closeSongsMenu():Void {
		if (OptionsSongsMenu.instance != null) {
			OptionsSongsMenu.instance.remove();
		}
	}

	override public function remove():Void {
		hoverOut();
		closeArtMenu();
		closeSongsMenu();
		if (accountButtons != null) {
			accountButtons.remove();
			accountButtons = null;
		}
		saveControls();
		Settings.setValue(Settings.DRAW_ART, drawArt);
		Settings.setValue(Settings.FILTER_SWEARS, filterSwears);
		for (cleanup in hoverCleanups) cleanup();
		hoverCleanups = [];
		for (binding in bindings) LobbyArt.unbind(binding);
		bindings = [];
		var music = slider("musicSlider");
		var sound = slider("soundSlider");
		if (music != null) music.removeEventListener(Event.CHANGE, musicChanged);
		if (sound != null) {
			sound.removeEventListener(Event.CHANGE, soundChanged);
			sound.onRelease = null;
		}
		if (art != null) {
			art.dispose();
			if (art.parent != null) art.parent.removeChild(art);
			art = null;
		}
		super.remove();
	}

	private static function defaultPlayJumpSound(volume:Float):Void {
		if (Assets.exists(RaceSounds.JUMP_SOUND)) {
			SoundEffects.playSound(Assets.getSound(RaceSounds.JUMP_SOUND), volume);
		}
	}
}
