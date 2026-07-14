package pr2.gameplay;

import openfl.events.Event;
import pr2.audio.GameMusic;
import pr2.audio.MusicCatalog.MusicTrack;
import pr2.lobby.account.Settings;
import pr2.net.ServerConfig;

class MusicSelectionTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		Settings.disablePersistenceForTests();
		testLevelSongSelection();
		if (pr2.DeterministicTestMode.finishSmokeSuite("MusicSelectionTest")) return;
		testUserSongSwitching();
		testStreamingEndpoint();
		testArtifactSong();
		trace('MusicSelectionTest passed $assertions assertions');
	}

	private static function testLevelSongSelection():Void {
		var music = new RecordingGameMusic();
		var selection = new MusicSelection(music);
		selection.setSong("3", 0);
		assertEquals("3", selection.selectedSongId(), "known level song is selected");
		assertEquals("3", music.lastSongId, "known level song starts playing");

		selection.setSong("9", 2);
		assertEquals("3", selection.selectedSongId(), "missing song falls back using Flash random selection");
		selection.remove();
	}

	private static function testUserSongSwitching():Void {
		var music = new RecordingGameMusic();
		var selection = new MusicSelection(music);
		selection.dropdown.selectedIndex = 2;
		selection.dropdown.dispatchEvent(new Event(Event.CHANGE));
		assertEquals("2", music.lastSongId, "dropdown changes switch the runtime song");
		selection.remove();
	}

	private static function testStreamingEndpoint():Void {
		var track:MusicTrack = {id: "3", label: "Paradise on E - API", file: "03_paradise-on-e_ng32772.mp3"};
		ServerConfig.resetHost();
		assertEquals("https://pr2hub.com/music/new/03_paradise-on-e_ng32772.mp3",
			GameMusic.streamUrl(track),
			"race music streams from the same host as the level/API endpoints");

		ServerConfig.setHost("/api");
		assertEquals("/api/music/new/03_paradise-on-e_ng32772.mp3",
			GameMusic.streamUrl(track),
			"music routes through the configured dev proxy host");
		ServerConfig.resetHost();
	}

	private static function testArtifactSong():Void {
		var music = new RecordingGameMusic();
		var selection = new MusicSelection(music);
		selection.gotArtifact();
		assertEquals("16", selection.selectedSongId(), "artifact appends and selects its song");
		assertEquals("16", music.lastSongId, "artifact song starts playing");
		selection.remove();
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}

private class RecordingGameMusic extends GameMusic {
	public var lastSongId(default, null):String = "";

	public function new() {
		super();
	}

	override public function setSong(song:MusicTrack):Void {
		lastSongId = song.id;
	}
}
