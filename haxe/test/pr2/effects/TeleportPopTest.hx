package pr2.effects;

import openfl.display.Sprite;
import openfl.events.Event;

/**
	Regression guard for the teleport/safety poof effect. `TeleportPop` resolves
	the authored animation through `PR2MovieClip.fromLinkage`; the linkage is
	registered under its class name `TeleportAnimation`, not its identifier
	`TeleportEffectGraphic`. Passing the identifier threw "Unknown PR2 linkage
	class" from the ENTER_FRAME handler that spawns the poof (safety-net return
	and teleport blocks), which killed the whole frame loop and froze the game.
**/
class TeleportPopTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testConstructsAndSelfRemoves();
		trace('TeleportPopTest passed $assertions assertions');
	}

	private static function testConstructsAndSelfRemoves():Void {
		var parent = new Sprite();
		// playSound=false keeps the test off the audio path; the linkage lookup is
		// the part under test.
		var pop = new TeleportPop(120, 240, 0, 0, false);
		parent.addChild(pop);

		assertTrue(pop.numChildren > 0, "authored animation linkage resolved into a child");
		assertEquals(parent, pop.parent, "poof is mounted before it plays out");

		for (_ in 0...TeleportPop.LIFETIME_FRAMES) {
			pop.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertEquals(true, pop.parent == null, "poof removes itself after its lifetime");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertTrue(value:Bool, message:String):Void {
		assertions++;
		if (!value) {
			throw '$message: expected true';
		}
	}
}
