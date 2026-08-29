package pr2.gameplay;

import openfl.events.Event;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundLoaderContext;
import openfl.media.SoundTransform;
import openfl.net.URLRequest;
import pr2.audio.GameMusic;
import pr2.audio.MusicCatalog.MusicTrack;
import pr2.lobby.account.Settings;
import pr2.net.ServerConfig;

class MusicSelectionTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		Settings.disablePersistenceForTests();
		pr2.DeterministicTestMode.runTest("MusicSelectionTest.testLevelSongSelection", testLevelSongSelection);
		if (pr2.DeterministicTestMode.finishSmokeSuite("MusicSelectionTest")) return;
		pr2.DeterministicTestMode.runTest("MusicSelectionTest.testUserSongSwitching", testUserSongSwitching);
		pr2.DeterministicTestMode.runTest("MusicSelectionTest.testStreamingEndpoint", testStreamingEndpoint);
		pr2.DeterministicTestMode.runTest("MusicSelectionTest.testPendingStreamCannotOutlivePlayer", testPendingStreamCannotOutlivePlayer);
		pr2.DeterministicTestMode.runTest("MusicSelectionTest.testArtifactSong", testArtifactSong);
		trace('MusicSelectionTest passed $assertions assertions');
	}

	private static function testLevelSongSelection():Void {
		var music = new RecordingGameMusic();
		var selection = new MusicSelection(music);
		assertEquals("assets/svg/effects/music_selection_01.svg", MusicSelection.BACKGROUND_ASSET,
			"music selection retains its authored XFL background source");
		assertTrue(selection.exactBackground.scale9Grid != null, "music selection background preserves the SquareBG scale grid");
		assertNear(214.02, selection.exactBackground.width, 0.1, "authored background preserves XFL width");
		assertNear(35.0, selection.exactBackground.height, 0.1, "authored background preserves XFL height");
		assertNear(7.0, selection.dropdown.x, 0.001, "dropdown preserves Flash x position");
		assertNear(7.0, selection.dropdown.y, 0.001, "dropdown preserves Flash y position");
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

	private static function testPendingStreamCannotOutlivePlayer():Void {
		var pending = new RecordingSound();
		var music = new GameMusic(function():Sound return pending);
		var track:MusicTrack = {id: "3", label: "Paradise on E - API", file: "03_paradise-on-e_ng32772.mp3"};
		music.setSong(track);
		assertEquals(1, pending.loads, "music starts loading the selected stream");
		assertEquals(0, pending.plays, "music waits for the stream before creating a channel");
		music.remove();
		pending.dispatchEvent(new Event(Event.COMPLETE));
		assertEquals(0, pending.plays, "a removed music player cannot start after its pending load finishes");

		var ready = new RecordingSound();
		music = new GameMusic(function():Sound return ready);
		music.setSong(track);
		ready.dispatchEvent(new Event(Event.COMPLETE));
		assertEquals(1, ready.plays, "the current music player starts exactly once when its stream is ready");
		music.remove();
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function assertNear(expected:Float, actual:Float, tolerance:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > tolerance) throw '$message: expected $expected +/- $tolerance, got $actual';
	}

	private static function assertTrue(actual:Bool, message:String):Void {
		assertions++;
		if (!actual) throw '$message: expected true';
	}
}

private class RecordingSound extends Sound {
	public var loads(default, null):Int = 0;
	public var plays(default, null):Int = 0;

	public function new() {
		super();
	}

	override public function load(stream:URLRequest, context:SoundLoaderContext = null):Void {
		loads++;
	}

	override public function play(startTime:Float = 0, loops:Int = 0, soundTransform:SoundTransform = null):SoundChannel {
		plays++;
		return null;
	}

	override public function close():Void {}
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
