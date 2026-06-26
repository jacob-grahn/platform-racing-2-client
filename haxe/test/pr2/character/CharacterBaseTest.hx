package pr2.character;

import openfl.events.Event;

/**
	B1 coverage for the ported `Character` base: animation state transitions (incl.
	the jump-sound hook), the four-slot hat stack (`setHats`/`getHighestHat`/flags),
	and the block-touch probe classification consumed by B4.
**/
class CharacterBaseTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testStateTransitions();
		testJumpSoundHook();
		testHatStack();
		testGetHighestHat();
		testBlockTouchProbes();
		testRecoveryAndRemoval();
		trace('CharacterBaseTest passed $assertions assertions');
	}

	private static function testStateTransitions():Void {
		var c = new Character();
		assertEquals("stand", c.state, "constructor starts in stand");
		assertTrue(c.display.getStateClip("standAnim").visible, "stand clip visible at start");

		c.changeState("run");
		assertEquals("run", c.state, "changeState updates state field");
		assertTrue(c.display.getStateClip("runAnim").visible, "run clip becomes visible");
		assertTrue(!c.display.getStateClip("standAnim").visible, "stand clip hidden after leaving");

		c.changeState("frozenSolid");
		assertEquals("frozenSolid", c.state, "raw state names append Anim for the clip");
		assertTrue(!c.display.getStateClip("runAnim").visible, "run clip hidden after leaving for frozen-solid");
	}

	private static function testJumpSoundHook():Void {
		var c = new Character();
		var jumps = 0;
		c.onPlayJumpSound = function(_, _) jumps++;

		c.velY = 0;
		c.changeState("jump");
		assertEquals(1, jumps, "entering jump with velY<=0 plays the jump sound");

		c.changeState("jump");
		assertEquals(1, jumps, "re-entering the same state does not re-fire");

		c.changeState("stand");
		c.velY = 12;
		c.changeState("jump");
		assertEquals(1, jumps, "entering jump while rising (velY>0) does not play the sound");
	}

	private static function testHatStack():Void {
		var c = new Character();
		// crown (6) in slot 1, top hat (9) in slot 2.
		c.setHats([6, 0xFF0000, -1, 9, 0x00FF00, 0]);

		assertEquals(6, c.hat1, "slot 1 takes the first hat id");
		assertEquals(0xFF0000, c.hat1Color, "slot 1 takes the first hat colour");
		assertEquals(-1, c.hat1Color2, "slot 1 epic colour preserved");
		assertEquals(9, c.hat2, "slot 2 takes the second hat id");
		assertEquals(1, c.hat3, "unfilled slots reset to the empty hat");

		assertTrue(c.hasHatFlag(Character.CROWN), "crown id raises the crown flag");
		assertTrue(c.hasHatFlag(Character.TOP), "top-hat id raises the top flag");
		assertTrue(!c.hasHatFlag(Character.COWBOY), "unworn special hats stay unflagged");

		// Re-applying resets flags from the previous stack.
		c.setHats([5, 0, -1]);
		assertTrue(c.hasHatFlag(Character.COWBOY), "cowboy id raises the cowboy flag");
		assertTrue(!c.hasHatFlag(Character.CROWN), "setHats clears flags from the old stack");
	}

	private static function testGetHighestHat():Void {
		var c = new Character();
		c.setHats([6, 0xFF0000, -1, 9, 0x00FF00, 0]);

		var top = c.getHighestHat();
		assertEquals(9, top.hatNum, "highest hat pops the top occupied slot first");
		assertEquals(0x00FF00, top.hatColor, "highest hat returns that slot's colour");
		assertEquals(1, c.hat2, "popped slot is reset to empty");

		var next = c.getHighestHat();
		assertEquals(6, next.hatNum, "next pop falls back to the lower slot");
		assertEquals(1, c.hat1, "lower slot reset after popping");

		var none = c.getHighestHat();
		assertEquals(0, none.hatNum, "popping with no hats returns the empty result");
		assertEquals(0, none.hatColor, "empty pop carries no colour");
	}

	private static function testBlockTouchProbes():Void {
		var c = new Character();
		c.x = 100;
		c.y = 200;

		var still = c.blockTouchProbes(0, 0);
		assertEquals(4, still.length, "a zero delta probes all four directions");

		var upRight = c.blockTouchProbes(5, -5);
		assertEquals(2, upRight.length, "moving up-right probes only up and right");
		// up probe: (x, y - charHeight - 1)
		assertEquals(100.0, upRight[0].x, "up probe keeps x");
		assertEquals(144.0, upRight[0].y, "up probe is y - charHeight - 1");
		// right probe: (x + halfWidth + 1, y - 10)
		assertEquals(111.0, upRight[1].x, "right probe is x + halfWidth + 1");
		assertEquals(190.0, upRight[1].y, "right probe is y - 10");

		var downLeft = c.blockTouchProbes(-3, 4);
		assertEquals(2, downLeft.length, "moving down-left probes only down and left");
		assertEquals(201.0, downLeft[0].y, "down probe is y + 1");
		assertEquals(89.0, downLeft[1].x, "left probe is x - halfWidth - 1");
	}

	private static function testRecoveryAndRemoval():Void {
		var c = new Character();
		c.beginRecovery(8);
		c.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(0.75, c.alpha, "first recovery frame flashes to 0.75 (phase 8%8=0 < 4)");
		c.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(0.5, c.alpha, "next recovery frame flashes to 0.5 (phase 7 >= 4)");

		// Drain the remaining recovery frames; alpha resets to full at the end.
		for (_ in 0...8) {
			c.dispatchEvent(new Event(Event.ENTER_FRAME));
		}
		assertClose(1.0, c.alpha, "recovery clears the flash when frames run out");

		c.beginRemove();
		c.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(0.98, c.alpha, "beginRemove fades alpha by 0.02 per frame");
		assertTrue(!c.removed, "still fading, not yet removed");
	}

	private static function assertEquals<T>(expected:T, actual:T, message:String):Void {
		assertions++;
		if (actual != expected) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertTrue(value:Bool, message:String):Void {
		assertions++;
		if (!value) {
			throw 'assertion failed: $message';
		}
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.0001) {
			throw '$message: expected $expected, got $actual';
		}
	}
}
