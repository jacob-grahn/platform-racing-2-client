package pr2.character;

import openfl.display.Sprite;
import openfl.events.Event;
import pr2.runtime.PR2MovieClip;

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
		testHeldWeaponDisplay();
		testJetPackFlameLifecycle();
		testBlockTouchProbes();
		testParticleEmitterLifecycle();
		testDjinnEffectsLifecycle();
		testCharacterSoundRequests();
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

		c.setHatId(13);
		assertTrue(c.hasHatFlag(Character.JIGG), "direct hat id updates special flags");
		assertTrue(!c.hasHatFlag(Character.COWBOY), "direct hat id clears stale special flags");
	}

	private static function testGetHighestHat():Void {
		var c = new Character();
		c.setHats([6, 0xFF0000, -1, 9, 0x00FF00, 0]);

		var top = c.getHighestHat();
		assertEquals(9, top.hatNum, "highest hat pops the top occupied slot first");
		assertEquals(0x00FF00, top.hatColor, "highest hat returns that slot's colour");
		assertEquals(0, top.hatColor2, "highest hat returns that slot's epic colour");
		assertEquals(1, c.hat2, "popped slot is reset to empty");

		var next = c.getHighestHat();
		assertEquals(6, next.hatNum, "next pop falls back to the lower slot");
		assertEquals(1, c.hat1, "lower slot reset after popping");

		var none = c.getHighestHat();
		assertEquals(0, none.hatNum, "popping with no hats returns the empty result");
		assertEquals(0, none.hatColor, "empty pop carries no colour");
		assertEquals(-1, none.hatColor2, "empty pop carries no epic colour");
	}

	private static function testHeldWeaponDisplay():Void {
		var c = new Character();
		c.setItem(4);

		assertEquals("Teleport", c.itemFrameName, "setItem resolves the held-item frame name");
		assertEquals(21, weaponClip(c, "standAnim").currentFrame, "setItem applies the authored weapon frame");

		c.changeState("jump");
		assertEquals(21, weaponClip(c, "jumpAnim").currentFrame, "held weapon survives animation changes");
	}

	private static function weaponClip(c:Character, stateName:String):PR2MovieClip {
		var state = c.display.getStateClip(stateName);
		assertTrue(state != null, '$stateName exists');
		var weapon = Std.downcast(state.getChildByTimelineName("weapon"), PR2MovieClip);
		assertTrue(weapon != null, '$stateName exposes weapon clip');
		return weapon;
	}

	private static function testJetPackFlameLifecycle():Void {
		var c = new Character();
		c.setItem(6);
		var starts:Array<String> = [];
		var stops = 0;
		c.onStartJetSound = function(request) starts.push(request.kind + ":" + request.volume + ":" + (request.target == c));
		c.onStopJetSound = function(character) {
			assertEquals(c, character, "Jet Pack sound stop targets the character");
			stops++;
		};
		var values = [0.1, 0.9, 0.2, 0.8];
		var index = 0;
		c.setJetFlameRandomForTest(function() return values[index++]);

		var jetPack = c.jetPackForState("standAnim");
		assertTrue(jetPack != null, "Jet Pack weapon exposes the jetPack state clip");
		assertEquals(1, jetPack.currentFrame, "Jet Pack starts on the off frame");

		c.beginJet();
		assertEquals("engine:0.6:true", starts.join("|"), "beginJet starts Flash's looping EngineSound");
		assertEquals(0, stops, "first beginJet has no existing EngineSound to stop");
		assertEquals(6, jetPack.currentFrame, "beginJet switches the current Jet Pack to the on frame");
		c.dispatchEvent(new Event(Event.ENTER_FRAME));

		var anim = Std.downcast(jetPack.getChildByTimelineName("anim"), PR2MovieClip);
		assertTrue(anim != null, "Jet Pack on frame exposes the flame anim");
		var fire1 = anim.getChildByTimelineName("fire1");
		var fire2 = anim.getChildByTimelineName("fire2");
		assertTrue(fire1 != null, "Jet Pack flame exposes fire1");
		assertTrue(fire2 != null, "Jet Pack flame exposes fire2");
		assertClose(0.55, fire1.scaleY, "jetPackTick jitters fire1 scaleY with Flash's 0.5-1.0 range");
		assertClose(0.95, fire2.alpha, "jetPackTick jitters fire2 alpha with Flash's 0.5-1.0 range");

		c.changeState("run");
		var runJetPack = c.jetPackForState("runAnim");
		c.beginJet();
		assertEquals("engine:0.6:true|engine:0.6:true", starts.join("|"), "beginJet restarts an existing EngineSound loop");
		assertEquals(1, stops, "restarting Jet Pack stops the previous EngineSound loop");
		c.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(6, runJetPack.currentFrame, "jetPackTick keeps the active state's Jet Pack on after state changes");

		c.endJet();
		assertEquals(2, stops, "endJet stops the active EngineSound loop");
		var resetClips = 0;
		for (stateName in CharacterDisplay.STATE_NAMES) {
			var stateJetPack = c.jetPackForState(stateName);
			if (stateJetPack != null) {
				resetClips++;
				assertEquals(1, stateJetPack.currentFrame, '$stateName Jet Pack returns to the off frame');
			}
		}
		assertTrue(resetClips > 1, "endJet resets every authored Jet Pack state clip that exists");
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

	private static function testParticleEmitterLifecycle():Void {
		var c = new Character();
		var started:Array<String> = [];
		var clears = 0;
		c.onStartParticleEmitter = function(request) {
			assertEquals(c, request.target, "particle emitter targets the character");
			started.push(request.kind + ":" + request.intervalMs + ":" + request.durationMs);
		};
		c.onClearParticleEmitter = function() clears++;

		c.beginSparkles(1234);
		assertEquals("sparkle:33:1234", started.join("|"), "beginSparkles starts Flash's sparkle emitter");
		assertEquals(0, clears, "first emitter does not clear anything");

		c.beginArrowSparkles();
		assertEquals("sparkle:33:1234|arrowSparkle:33:5000", started.join("|"), "arrow sparkles replace the old emitter");
		assertEquals(1, clears, "setting a new emitter clears the previous one");

		c.becomeInvincible(8);
		assertEquals("sparkle:33:1234|arrowSparkle:33:5000|rainbowStar:33:5000", started.join("|"),
			"becomeInvincible starts Flash's rainbow-star emitter");
		assertEquals(2, clears, "rainbow-star emitter replaces arrow sparkles");

		c.endSparkles();
		assertEquals(3, clears, "endSparkles clears the active emitter");
		c.remove();
		assertEquals(3, clears, "remove does not clear a missing emitter twice");
	}

	private static function testDjinnEffectsLifecycle():Void {
		var parent = new Sprite();
		var c = new Character();
		var started:Array<String> = [];
		var clears = 0;
		c.onStartDjinnEmitter = function(request) {
			assertEquals(c, request.target, "Djinn emitter targets the character");
			started.push(request.slot + ":" + request.graphic + ":" + request.colors.join(",") + ":" + request.life + ":" + request.startAlpha + ":"
				+ request.maxVelAlpha + ":" + request.minScale + ":" + request.maxScale + ":" + request.offsetX + ":" + request.offsetY);
		};
		c.onClearDjinnEmitters = function() clears++;

		c.setBodyId(35);
		assertEquals("", started.join("|"), "unmounted Djinn body does not start emitters");
		parent.addChild(c);
		assertEquals("body:DjinnIceGraphic:0,-1:16:0.1:0.5:-1:-0.75:-15:-10", started.join("|"),
			"mounted Frost Djinn body starts Flash body ice emitter");

		c.setFeetColors(0x112233, 0x445566);
		c.setFeetId(35);
		assertEquals(2, clears, "appearance changes clear existing Djinn emitters before replacing them");
		assertEquals(
			"body:DjinnIceGraphic:0,-1:16:0.1:0.5:-1:-0.75:-15:-10|body:DjinnIceGraphic:0,-1:16:0.1:0.5:-1:-0.75:-15:-10|body:DjinnIceGraphic:0,-1:16:0.1:0.5:-1:-0.75:-15:-10|foot1:DjinnIceGraphic:1122867,4478310:8:0.1:0.5:0.075:0.1:0:0|foot2:DjinnIceGraphic:1122867,4478310:8:0.1:0.5:0.075:0.1:0:0",
			started.join("|"),
			"Frost Djinn feet start separate foot emitters with feet colors");

		c.djinnUpdateAlpha(0.25);
		assertEquals(3, clears, "djinnUpdateAlpha refreshes active emitters");
		assertEquals("body:DjinnIceGraphic:0,-1:16:0.05:0.25:-1:-0.75:-15:-10|foot1:DjinnIceGraphic:1122867,4478310:8:0.05:0.25:0.075:0.1:0:0|foot2:DjinnIceGraphic:1122867,4478310:8:0.05:0.25:0.075:0.1:0:0",
			started.slice(started.length - 3).join("|"), "djinnUpdateAlpha applies Flash alpha scaling");

		parent.removeChild(c);
		assertEquals(4, clears, "removing a mounted character clears Djinn emitters");
		c.remove();
		assertEquals(4, clears, "remove does not clear already-cleared Djinn emitters twice");
	}

	private static function testCharacterSoundRequests():Void {
		var c = new Character();
		var sounds:Array<String> = [];
		c.x = 120;
		c.y = 240;
		c.onPlayCharacterSound = function(request) {
			sounds.push(request.kind + ":" + request.volume + ":" + Math.round(request.x) + ":" + Math.round(request.y));
		};

		c.beginSparkles();
		c.endSparkles(false);
		c.beginSparkles(100);
		c.endSparkles(true);
		c.gainHeart();

		assertEquals("speedUp:1:120:240|speedUp:1:120:240|slowDown:1:120:240|bumpHappy:0.75:120:240", sounds.join("|"),
			"sparkles and heart emit Flash character sound requests");
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
