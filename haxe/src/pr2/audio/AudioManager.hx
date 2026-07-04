package pr2.audio;

import openfl.display.DisplayObjectContainer;
import pr2.lobby.account.Settings;

class AudioManager {
	private static var menuMusic:Null<MenuMusic>;
	public static var startPlayingHook:Null<Void->Void> = null;
	public static var targetVolumeHook:Null<Float->Void> = null;

	public static function install(root:DisplayObjectContainer):Void {
		if (menuMusic != null) return;
		menuMusic = new MenuMusic();
		root.addChild(menuMusic);
	}

	public static function enterLogin():Void {
		if (Settings.musicLevel > 0) startPlaying();
		setTargetVolume(Settings.musicLevel / 100);
	}

	public static function enterLobby():Void {
		if (Settings.musicLevel > 0) startPlaying();
		setTargetVolume(0.6 * Settings.musicLevel / 100);
	}

	public static function leaveMenu():Void setTargetVolume(0);

	public static function musicLevelChanged():Void {
		if (Settings.musicLevel > 0) startPlaying();
		setTargetVolume(0.6 * Settings.musicLevel / 100);
	}

	public static function resetHooksForTests():Void {
		startPlayingHook = null;
		targetVolumeHook = null;
	}

	private static function startPlaying():Void {
		if (startPlayingHook != null) startPlayingHook();
		if (menuMusic != null) menuMusic.startPlaying();
	}

	private static function setTargetVolume(value:Float):Void {
		if (targetVolumeHook != null) targetVolumeHook(value);
		if (menuMusic != null) menuMusic.setTargetVolume(value);
	}
}
