package pr2.audio;

import pr2.lobby.account.Settings;

class AudioRuntimeTest {
	public static function main():Void {
		Settings.disablePersistenceForTests();
		var assertions = 0;
		var center = SoundEffects.spatialMix(0, 0, 0, 0, 1, 0, 80);
		assertNear(0.8, center.volume, "sound setting scales centered effect"); assertions++;
		assertNear(0, center.pan, "centered effect is not panned"); assertions++;
		var edge = SoundEffects.spatialMix(350, 0, 0, 0, 1, 0, 100);
		assertNear(0.5, edge.volume, "distance attenuates linearly"); assertions++;
		assertNear(0.5, edge.pan, "horizontal offset controls pan"); assertions++;
		var outside = SoundEffects.spatialMix(900, 0, 0, 0);
		assertNear(0, outside.volume, "effects past 700 pixels are silent"); assertions++;
		assertNear(1, outside.pan, "pan is clamped to the SoundTransform range"); assertions++;

		assertNear(1000, TimelineSound.sample44ToMilliseconds(44100), "timeline sound sample points convert to milliseconds"); assertions++;
		var fade = [
			{mark44: 0, level0: 0, level1: 32768},
			{mark44: 44100, level0: 32768, level1: 0}
		];
		var fadeStart = TimelineSound.envelopeMixAt(fade, 0);
		assertNear(0, fadeStart.left, "timeline envelope starts at its authored left level"); assertions++;
		assertNear(1, fadeStart.right, "timeline envelope starts at its authored right level"); assertions++;
		var fadeMiddle = TimelineSound.envelopeMixAt(fade, 22050);
		assertNear(0.5, fadeMiddle.left, "timeline envelope interpolates the left level"); assertions++;
		assertNear(0.5, fadeMiddle.right, "timeline envelope interpolates the right level"); assertions++;
		var fadeEnd = TimelineSound.envelopeMixAt(fade, 50000);
		assertNear(1, fadeEnd.left, "timeline envelope holds its final left level"); assertions++;
		assertNear(0, fadeEnd.right, "timeline envelope holds its final right level"); assertions++;
		var defaultMix = TimelineSound.envelopeMixAt(null, 0);
		assertNear(1, defaultMix.left, "timeline sounds without envelopes use full left volume"); assertions++;
		assertNear(1, defaultMix.right, "timeline sounds without envelopes use full right volume"); assertions++;

		var stoppedA = 0;
		var stoppedB = 0;
		TimelineSound.registerActive("Sounds/a.mp3", function():Void stoppedA++);
		TimelineSound.registerActive("Sounds/a.mp3", function():Void stoppedA++);
		TimelineSound.registerActive("Sounds/b.mp3", function():Void stoppedB++);
		TimelineSound.processFrame({
			soundName: "Sounds/a.mp3",
			soundSync: "stop",
			elementCount: 0,
			elementTypes: []
		});
		assert(stoppedA == 2, "stop-sync terminates every active instance of the named sound"); assertions++;
		assert(stoppedB == 0, "stop-sync leaves other library sounds playing"); assertions++;
		TimelineSound.stopLibrarySound("Sounds/a.mp3");
		assert(stoppedA == 2, "stopped timeline sounds are removed from the active registry"); assertions++;
		TimelineSound.stopLibrarySound("Sounds/b.mp3");
		assert(stoppedB == 1, "other registered timeline sounds remain independently stoppable"); assertions++;

		var startSoundStops = 0;
		TimelineSound.registerActive("Sounds/start.mp3", function():Void startSoundStops++);
		assert(TimelineSound.isLibrarySoundActive("Sounds/start.mp3"), "registered timeline sound is active"); assertions++;
		TimelineSound.processFrame({
			soundName: "Sounds/start.mp3",
			soundSync: "start",
			elementCount: 0,
			elementTypes: []
		});
		assert(startSoundStops == 0, "start-sync does not interrupt an active instance"); assertions++;
		TimelineSound.stopLibrarySound("Sounds/start.mp3");
		assert(startSoundStops == 1, "start-sync suppression keeps the original instance registered"); assertions++;
		assert(!TimelineSound.isLibrarySoundActive("Sounds/start.mp3"), "stopped timeline sound is no longer active"); assertions++;

		var ownerA = {};
		var ownerB = {};
		var ownerAStops = 0;
		var ownerBStops = 0;
		TimelineSound.registerActive("Sounds/owned.mp3", function():Void ownerAStops++, ownerA);
		TimelineSound.registerActive("Sounds/owned.mp3", function():Void ownerBStops++, ownerB);
		TimelineSound.stopOwner(ownerA);
		assert(ownerAStops == 1, "disposing a timeline stops its owned sound"); assertions++;
		assert(ownerBStops == 0, "disposing a timeline leaves another timeline's sound active"); assertions++;
		assert(TimelineSound.isLibrarySoundActive("Sounds/owned.mp3"), "other owners remain registered after timeline disposal"); assertions++;
		TimelineSound.stopOwner(ownerA);
		assert(ownerAStops == 1, "disposed timeline sounds are removed from the owner registry"); assertions++;
		TimelineSound.stopOwner(ownerB);
		assert(ownerBStops == 1, "the remaining timeline owner can dispose its sound"); assertions++;
		assert(!TimelineSound.isLibrarySoundActive("Sounds/owned.mp3"), "owner disposal removes the final library registration"); assertions++;

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
