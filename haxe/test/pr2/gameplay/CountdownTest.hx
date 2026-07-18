package pr2.gameplay;

import openfl.display.Sprite;
import pr2.lobby.account.Settings;

class CountdownTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testCountdownSequence();
		if (pr2.DeterministicTestMode.finishSmokeSuite("CountdownTest")) return;
		testCountdownSounds();
		trace('CountdownTest passed $assertions assertions');
	}

	private static function testCountdownSequence():Void {
		var finishCalls = 0;
		var parent = new Sprite();
		var countdown = new Countdown(function():Void finishCalls++);
		parent.addChild(countdown);

		assertEquals(0, countdown.counts, "no counts before playing");
		assertEquals(false, countdown.finished, "not finished before playing");
		@:privateAccess assertEquals("assets/svg/effects/countdown_01.svg", countdown.art.currentAssetPath,
			"countdown starts on exact composed XFL frame one");
		for (_ in 0...8) countdown.advance();
		@:privateAccess assertEquals("assets/svg/effects/countdown_09.svg", countdown.art.currentAssetPath,
			"first ready cue uses exact composed XFL frame nine");

		// Drive the authored 62-frame timeline to completion. Frame scripts at
		// 9/24/39 tick "count" and 54 fires "finish"; 62 self-removes.
		var guard = 8;
		while (countdown.parent != null && guard < 200) {
			countdown.advance();
			guard++;
		}

		assertEquals(3, countdown.counts, "three ready counts (3-2-1)");
		assertEquals(true, countdown.finished, "finish reached");
		assertEquals(1, finishCalls, "onFinish invoked exactly once");
		assertEquals(true, countdown.parent == null, "countdown self-removes after the last frame");
	}

	private static function testCountdownSounds():Void {
		var oldSoundLevel = Settings.soundLevel;
		Settings.soundLevel = 50;
		var effects:Array<String> = [];
		var countdown = new Countdown(null, function(path:String, volume:Float):Void {
			effects.push(path + ":" + volume);
		});

		for (_ in 0...62) {
			countdown.advance();
		}

		assertEquals("assets/audio/sfx/countdown_ready.mp3:0.2|assets/audio/sfx/countdown_ready.mp3:0.2|assets/audio/sfx/countdown_ready.mp3:0.2|assets/audio/sfx/countdown_go.mp3:0.25",
			effects.join("|"), "countdown plays three ready sounds and one go sound with Settings.soundLevel scaling");
		Settings.soundLevel = oldSoundLevel;
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
