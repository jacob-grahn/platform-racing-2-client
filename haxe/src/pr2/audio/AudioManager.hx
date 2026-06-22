package pr2.audio;

import openfl.display.DisplayObjectContainer;
import pr2.lobby.account.Settings;

class AudioManager {
	private static var menuMusic:Null<MenuMusic>;

	public static function install(root:DisplayObjectContainer):Void {
		if (menuMusic != null) return;
		menuMusic = new MenuMusic();
		root.addChild(menuMusic);
	}

	public static function enterLogin():Void {
		if (menuMusic == null || Settings.musicLevel <= 0) return;
		menuMusic.startPlaying();
		menuMusic.setTargetVolume(Settings.musicLevel / 100);
	}

	public static function enterLobby():Void {
		if (menuMusic == null || Settings.musicLevel <= 0) return;
		menuMusic.startPlaying();
		menuMusic.setTargetVolume(0.6 * Settings.musicLevel / 100);
	}

	public static function leaveMenu():Void if (menuMusic != null) menuMusic.setTargetVolume(0);

	public static function musicLevelChanged():Void {
		if (menuMusic == null) return;
		if (Settings.musicLevel > 0) menuMusic.startPlaying();
		menuMusic.setTargetVolume(0.6 * Settings.musicLevel / 100);
	}
}
