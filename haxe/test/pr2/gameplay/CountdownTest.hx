package pr2.gameplay;

import openfl.display.Sprite;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.text.TextField;
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
		@:privateAccess assertEquals("assets/effects/countdown.lottie.json", countdown.art.timeline.sourcePath,
			"countdown uses semantic Lottie data");
		@:privateAccess assertEquals(1, countdown.art.currentFrame, "countdown starts on authored frame one");
		for (_ in 0...8) countdown.advance();
		@:privateAccess assertEquals(9, countdown.art.currentFrame, "first ready cue uses exact authored frame nine");
		@:privateAccess var label = findVisibleText(countdown.art.timeline);
		assertEquals(true, label != null, "countdown frame includes its visible native text layer");
		assertEquals("3", label.text, "first countdown frame renders its authored label");

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

	private static function findVisibleText(root:DisplayObjectContainer):Null<TextField> {
		for (index in 0...root.numChildren) {
			var child:DisplayObject = root.getChildAt(index);
			if (!child.visible) continue;
			var text = Std.downcast(child, TextField);
			if (text != null && text.text != "") return text;
			var container = Std.downcast(child, DisplayObjectContainer);
			if (container != null) {
				var nested = findVisibleText(container);
				if (nested != null) return nested;
			}
		}
		return null;
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
