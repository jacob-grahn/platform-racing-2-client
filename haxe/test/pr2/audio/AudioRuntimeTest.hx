package pr2.audio;

import pr2.lobby.account.Settings;

class AudioRuntimeTest {
	public static function main():Void {
		Settings.disablePersistenceForTests();
		var assertions = 0;
		var center = SoundEffects.spatialMix(0, 0, 0, 0, 1, 0, 80);
		assertNear(0.8, center.volume, "sound setting scales centered effect"); assertions++;
		if (pr2.DeterministicTestMode.finishSmokeSuite("AudioRuntimeTest")) return;
		assertNear(0, center.pan, "centered effect is not panned"); assertions++;
		var edge = SoundEffects.spatialMix(350, 0, 0, 0, 1, 0, 100);
		assertNear(0.5, edge.volume, "distance attenuates linearly"); assertions++;
		assertNear(0.5, edge.pan, "horizontal offset controls pan"); assertions++;
		var outside = SoundEffects.spatialMix(900, 0, 0, 0);
		assertNear(0, outside.volume, "effects past 700 pixels are silent"); assertions++;
		assertNear(1, outside.pan, "pan is clamped to the SoundTransform range"); assertions++;
		var rotatedBlock = pr2.gameplay.BlockCollision.rotatedWorldBlockPos(600, 480, 90, 30);
		assert(rotatedBlock.x == -510 && rotatedBlock.y == 600,
			"rotated block thumps use Flash's rotated block origin for spatial audio"); assertions++;
		assert(pr2.effects.ZapEffect.SOUND_PATH == "assets/audio/sfx/zap.mp3", "ZapEffect uses the named exported Flash ZapSound"); assertions++;
		assert(pr2.gameplay.RaceSounds.SQUASH_SOUND == "assets/audio/sfx/squash.mp3", "squash uses the named exported Flash SquashSound"); assertions++;
		assert(pr2.gameplay.RaceSounds.VICTORY_SOUND == "assets/audio/sfx/victory.mp3", "finishing uses the named exported Flash VictorySound"); assertions++;

		var songs = MusicCatalog.enabled(["2", "19"]);
		assert(songs.length == 18, "disabled songs are omitted outside the editor"); assertions++;
		assert(MusicCatalog.select(songs, "3", 0) == 2, "known song ids select exactly"); assertions++;
		assert(MusicCatalog.select(songs, "9", 1) == 2, "removed song ids fall back to random"); assertions++;
		var editorSongs = MusicCatalog.enabled(["2"], true);
		assert(editorSongs.length == 21 && editorSongs[1].id == "random", "editor keeps all songs and Random"); assertions++;
		var artifactSongs = MusicCatalog.enabled([], false, true);
		assert(artifactSongs[artifactSongs.length - 1].id == "16", "artifact unlock appends track 16"); assertions++;

		Settings.setValue(Settings.MUSIC_VOLUME, 140);
		Settings.setValue(Settings.SOUND_VOLUME, -4);
		assert(Settings.musicLevel == 100, "music volume is clamped and mirrored"); assertions++;
		assert(Settings.soundLevel == 0, "sound volume is clamped and mirrored"); assertions++;
		Settings.setValue(Settings.MUSIC_VOLUME, 100);
		Settings.setValue(Settings.SOUND_VOLUME, 100);
		trace('AudioRuntimeTest passed $assertions assertions');
	}

	private static function assertNear(expected:Float, actual:Float, message:String):Void {
		if (Math.abs(expected - actual) > 0.000001) throw '$message: expected $expected, got $actual';
	}

	private static function assert(condition:Bool, message:String):Void if (!condition) throw message;
}
