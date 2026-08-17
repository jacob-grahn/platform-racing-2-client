package pr2.character;

import openfl.events.Event;
import pr2.Constants;
import pr2.gameplay.BlockController;
import pr2.gameplay.player.LocalPlayerController;
import pr2.gameplay.player.LocalPlayerInput;
import pr2.level.BlockType;
import pr2.level.Level;
import pr2.level.Level.LevelBlock;
import pr2.level.Level.StatDefaults;
import pr2.level.Level.TilePosition;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;

class LocalCharacterTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		pr2.DeterministicTestMode.runTest("LocalCharacterTest.testDelegatesPhysicsAndMirrorsCharacterState", testDelegatesPhysicsAndMirrorsCharacterState);
		if (pr2.DeterministicTestMode.finishSmokeSuite("LocalCharacterTest")) return;
		pr2.DeterministicTestMode.runTest("LocalCharacterTest.testUnchangedHeldItemDoesNotResetUseAnimation", testUnchangedHeldItemDoesNotResetUseAnimation);
		pr2.DeterministicTestMode.runTest("LocalCharacterTest.testCowboyHatBoostsStatsAndForcesAirborneWaterModeUntilRemoved", testCowboyHatBoostsStatsAndForcesAirborneWaterModeUntilRemoved);
		pr2.DeterministicTestMode.runTest("LocalCharacterTest.testCowboyHatFlightDoesNotRepeatWaterExitBoost", testCowboyHatFlightDoesNotRepeatWaterExitBoost);
		pr2.DeterministicTestMode.runTest("LocalCharacterTest.testTopHatPassesThroughVanishBlocks", testTopHatPassesThroughVanishBlocks);
		pr2.DeterministicTestMode.runTest("LocalCharacterTest.testAprilFirstReversesControlsUntilArtifactRemoved", testAprilFirstReversesControlsUntilArtifactRemoved);
		pr2.DeterministicTestMode.runTest("LocalCharacterTest.testNormalRaceMineHitDropsHighestHat", testNormalRaceMineHitDropsHighestHat);
		pr2.DeterministicTestMode.runTest("LocalCharacterTest.testHatAttackHitDropsHighestHat", testHatAttackHitDropsHighestHat);
		trace('LocalCharacterTest passed $assertions assertions');
	}

	private static function testDelegatesPhysicsAndMirrorsCharacterState():Void {
		var level = flatLevel();
		var controller = new LocalPlayerController(level);
		var character = new LocalCharacter(level);
		assertSameState(controller, character, "initial sync");
		assertEquals("local", character.type, "local character type");

		var inputs = [
			new LocalPlayerInput(),
			new LocalPlayerInput(false, true),
			new LocalPlayerInput(false, true),
			new LocalPlayerInput(false, false, true),
			new LocalPlayerInput(false, false, true),
			new LocalPlayerInput(),
			new LocalPlayerInput(true, false),
			new LocalPlayerInput()
		];

		for (i in 0...inputs.length) {
			controller.step(inputs[i]);
			character.step(inputs[i].copy());
			assertSameState(controller, character, 'frame $i');
		}

		character.setGravity(2.5);
		controller.setGravity(2.5);
		controller.step(new LocalPlayerInput());
		character.step(new LocalPlayerInput());
		assertSameState(controller, character, "runtime gravity sync");
	}

	private static function testUnchangedHeldItemDoesNotResetUseAnimation():Void {
		var character = new LocalCharacter(heldSwordLevel());
		for (_ in 0...40) {
			character.step(new LocalPlayerInput(false, false, true));
			if (character.stateSnapshot().itemId == 8) break;
		}
		assertEquals(8, character.stateSnapshot().itemId, "sword is collected for the presentation regression");
		assertEquals(true, character.playItemUseAnimation("Sword"), "held sword starts its authored swing");
		character.display.advanceOneFrame();
		var swingFrame = character.display.itemActionFrame;

		character.step(new LocalPlayerInput());

		assertEquals(swingFrame, character.display.itemActionFrame, "unchanged controller sync preserves the sword swing frame");
		assertEquals(true, character.display.itemActionPlaying, "unchanged controller sync keeps the sword swing playing");
		@:privateAccess character.display.itemActionFrame = 14;
		character.display.advanceOneFrame();
		assertEquals(14, character.display.itemActionFrame, "sword swing finishes on its authored idle frame");
		assertEquals(false, character.display.itemActionPlaying, "sword swing stops after one pass");
		character.display.advanceOneFrame();
		assertEquals(14, character.display.itemActionFrame, "stopped sword swing does not loop back to its start");
	}

	private static function testCowboyHatBoostsStatsAndForcesAirborneWaterModeUntilRemoved():Void {
		var cowboy = new LocalCharacter(airborneLevel());
		cowboy.setHats([5, 0xFFFFFF, -1]);

		var equipped = cowboy.stateSnapshot();
		assertClose(50, equipped.speedStat, "cowboy movement boost leaves displayed speed unchanged like Flash");
		assertClose(50, equipped.accelerationStat, "cowboy movement boost leaves displayed acceleration unchanged like Flash");
		assertClose(50, equipped.jumpStat, "cowboy movement boost leaves displayed jumping unchanged like Flash");

		cowboy.step(new LocalPlayerInput());
		var swimming = cowboy.stateSnapshot();
		assertEquals("water", swimming.mode, "cowboy hat forces airborne water mode");
		assertEquals("swim", swimming.animation, "cowboy airborne mode uses swim animation");

		cowboy.setHats([]);
		var removed = cowboy.stateSnapshot();
		assertClose(50, removed.speedStat, "cowboy hat removal restores starting speed");
		assertClose(50, removed.accelerationStat, "cowboy hat removal restores starting acceleration");
		assertClose(50, removed.jumpStat, "cowboy hat removal restores starting jump");
	}

	private static function testCowboyHatFlightDoesNotRepeatWaterExitBoost():Void {
		var cowboy = new LocalCharacter(airborneLevel());
		var lowAccelerationCowboy = new LocalCharacter(airborneLevelWithAcceleration(0));
		cowboy.setHats([5, 0xFFFFFF, -1]);
		lowAccelerationCowboy.setHats([5, 0xFFFFFF, -1]);

		var expectedVy = 0.0;
		for (frame in 0...12) {
			expectedVy = (expectedVy - 1.86 * 0.65 + 0.7 * 0.25) * 0.92;
			cowboy.step(new LocalPlayerInput(false, false, true));
			lowAccelerationCowboy.step(new LocalPlayerInput(false, false, true));
			assertEquals("water", cowboy.stateSnapshot().mode, 'cowboy remains in water mode on flight frame $frame');
		}

		assertClose(expectedVy, cowboy.stateSnapshot().vy, "cowboy upward speed follows continuous Flash water physics");
		assertClose(cowboy.stateSnapshot().vy, lowAccelerationCowboy.stateSnapshot().vy,
			"cowboy flight uses the Flash acceleration minimum regardless of the lower starting acceleration stat");
	}

	private static function testTopHatPassesThroughVanishBlocks():Void {
		var normal = new LocalCharacter(vanishWallLevel());
		var top = new LocalCharacter(vanishWallLevel());
		top.setHats([9, 0xFFFFFF, -1]);

		for (_ in 0...8) {
			normal.step(new LocalPlayerInput(false, true));
			top.step(new LocalPlayerInput(false, true));
		}

		assertClose(80, normal.stateSnapshot().x, "vanish wall stops a character without top hat");
		assertAbove(top.stateSnapshot().x, 86, "top hat passes through vanish wall");
	}

	private static function testAprilFirstReversesControlsUntilArtifactRemoved():Void {
		var originalDateString = Character.dateStringNow;
		Character.dateStringNow = function() return "Apr 1";
		var april = new LocalCharacter(longFlatLevel());

		assertEquals(true, april.dateControlsReversed, "April 1 initializes date-driven reversed controls");
		assertEquals(false, april.artifactControlsReversed, "April 1 reversal is independent of artifact hat state");
		for (_ in 0...24) {
			april.step(new LocalPlayerInput(false, true));
		}
		assertBelow(april.stateSnapshot().vx, -0.1, "April 1 reversed controls turn right input into left movement");

		april.setHats([14, 0xFFFFFF, -1]);
		april.setHats([]);
		assertEquals(false, april.artifactControlsReversed, "artifact removal clears only artifact reversal state");
		for (_ in 0...24) {
			april.step(new LocalPlayerInput(false, true));
		}
		assertBelow(april.stateSnapshot().vx, -0.1, "artifact removal preserves April 1 reversed controls");
		Character.dateStringNow = originalDateString;
	}

	private static function testHatAttackHitDropsHighestHat():Void {
		var local = new LocalCharacter(delayedMineBlockLevel());
		local.setGameMode("hat");
		local.setHats([6, 0xFF0000, -1, 9, 0x00FF00, 0]);
		LobbySocket.resetSent();

		for (_ in 0...40) {
			local.step(new LocalPlayerInput());
			if (local.stateSnapshot().touchedBlockType == "mine") {
				break;
			}
		}

		assertEquals("land", local.stateSnapshot().mode, "crown hit in hat attack applies force without hurt animation");
		assertEquals("loose_hat`75`40`0", LobbySocket.lastSent(), "hat attack hit emits Flash loose-hat drop");
		assertEquals(6, local.hat1, "lower hat remains equipped after top hat drops");
		assertEquals(1, local.hat2, "highest occupied slot is cleared after drop");

		LobbySocket.resetSent();
		for (_ in 0...5) {
			local.step(new LocalPlayerInput());
		}
		assertEquals("", LobbySocket.lastSent(), "hurt recovery frames do not drop more hats");
	}

	private static function testNormalRaceMineHitDropsHighestHat():Void {
		var local = new LocalCharacter(delayedMineBlockLevel());
		local.setHats([9, 0x00FF00, -1]);
		LobbySocket.resetSent();

		for (_ in 0...40) {
			local.step(new LocalPlayerInput());
			if (local.stateSnapshot().touchedBlockType == "mine") {
				break;
			}
		}

		assertEquals("hurt", local.stateSnapshot().mode, "normal-race mine hit hurts the local character");
		@:privateAccess assertClose(65, local.recoveryFrames, "normal-race mine hit starts Flash's alpha recovery");
		local.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(0.75, local.alpha, "mine recovery starts the Flash blink phase");
		local.dispatchEvent(new Event(Event.ENTER_FRAME));
		local.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertClose(0.5, local.alpha, "mine recovery alternates the character alpha");
		assertEquals("loose_hat`75`40`0", LobbySocket.lastSent(), "normal-race mine hit emits Flash loose-hat drop");
		assertEquals(1, local.hat1, "normal-race mine hit clears the highest occupied hat");
	}

	private static function assertSameState(controller:LocalPlayerController, character:LocalCharacter, label:String):Void {
		var expected = controller.stateSnapshot();
		var actual = character.stateSnapshot();
		assertEquals(expected.serialize(), actual.serialize(), '$label debug state');
		assertClose(expected.x, character.x, '$label x');
		assertClose(expected.y, character.y, '$label y');
		assertClose(expected.vx, character.velX, '$label velX');
		assertClose(expected.vy, character.velY, '$label velY');
		assertEquals(expected.grounded, character.grounded, '$label grounded');
		assertEquals(expected.crouching, character.crouching, '$label crouching');
		assertEquals(expected.animation, character.state, '$label animation state');
		assertClose(controller.facingScaleX, character.display.scaleX, '$label facing scale');
	}

	private static function flatLevel():Level {
		return new Level(
			"local-character-flat",
			"Local Character Flat",
			8,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(6, 6),
			[
				new LevelBlock(2, 4, BlockType.Basic),
				new LevelBlock(3, 4, BlockType.Basic),
				new LevelBlock(4, 4, BlockType.Basic)
			]
		);
	}

	private static function heldSwordLevel():Level {
		return new Level(
			"local-character-held-sword",
			"Local Character Held Sword",
			8,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 5),
			new TilePosition(7, 6),
			[
				new LevelBlock(2, 3, BlockType.Item, "8"),
				new LevelBlock(2, 6, BlockType.Solid),
				new LevelBlock(3, 6, BlockType.Solid),
				new LevelBlock(4, 6, BlockType.Solid)
			]
		);
	}

	private static function airborneLevel():Level {
		return airborneLevelWithAcceleration(50);
	}

	private static function airborneLevelWithAcceleration(accelerationStat:Float):Level {
		return new Level(
			"local-character-airborne",
			"Local Character Airborne",
			8,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + accelerationStat / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(6, 6),
			[]
		);
	}

	private static function heavyGravityAirborneLevel():Level {
		return new Level(
			"local-character-heavy-airborne",
			"Local Character Heavy Airborne",
			8,
			8,
			30,
			2,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(6, 6),
			[]
		);
	}

	private static function nonSolidFloorLevel(type:BlockType):Level {
		return new Level(
			"local-character-non-solid-floor",
			"Local Character Non-solid Floor",
			8,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(6, 6),
			[new LevelBlock(2, 3, type)]
		);
	}

	private static function longFlatLevel():Level {
		var blocks:Array<LevelBlock> = [];
		for (tileX in 0...38) {
			blocks.push(new LevelBlock(tileX, 4, BlockType.Basic));
		}
		return new Level(
			"local-character-long-flat",
			"Local Character Long Flat",
			40,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(38, 6),
			blocks
		);
	}

	private static function vanishWallLevel():Level {
		return new Level(
			"local-character-vanish-wall",
			"Local Character Vanish Wall",
			8,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(6, 6),
			[
				new LevelBlock(1, 3, BlockType.Basic),
				new LevelBlock(2, 3, BlockType.Basic),
				new LevelBlock(3, 3, BlockType.Basic),
				new LevelBlock(4, 3, BlockType.Basic),
				new LevelBlock(3, 2, BlockType.Vanish)
			]
		);
	}

	private static function delayedMineBlockLevel():Level {
		return new Level(
			"local-character-delayed-mine-block",
			"Local Character Delayed Mine Block",
			5,
			6,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 1),
			new TilePosition(3, 4),
			[
				new LevelBlock(2, 3, BlockType.Mine),
				new LevelBlock(3, 4, BlockType.Finish)
			]
		);
	}

	private static function assertEquals<T>(expected:T, actual:T, label:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$label expected $expected but was $actual';
		}
	}

	private static function assertClose(expected:Float, actual:Float, label:String, epsilon:Float = 0.001):Void {
		assertions++;
		if (Math.abs(expected - actual) > epsilon) {
			throw '$label expected $expected but was $actual';
		}
	}

	private static function assertAbove(actual:Float, minimum:Float, label:String):Void {
		assertions++;
		if (actual <= minimum) {
			throw '$label expected above $minimum but was $actual';
		}
	}

	private static function assertBelow(actual:Float, maximum:Float, label:String):Void {
		assertions++;
		if (actual >= maximum) {
			throw '$label expected below $maximum but was $actual';
		}
	}
}
