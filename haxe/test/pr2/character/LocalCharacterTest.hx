package pr2.character;

import pr2.harness.LocalPlayerController;
import pr2.harness.LocalPlayerInput;
import pr2.level.BlockType;
import pr2.level.FixtureLevel;
import pr2.level.FixtureLevel.LevelBlock;
import pr2.level.FixtureLevel.StatDefaults;
import pr2.level.FixtureLevel.TilePosition;

class LocalCharacterTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testDelegatesPhysicsAndMirrorsCharacterState();
		testPropellerHatSlowsFallWhenHoldingJump();
		testCowboyHatBoostsStatsAndForcesAirborneWaterModeUntilRemoved();
		testMoonHatReducesGravityUntilRemoved();
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

	private static function testPropellerHatSlowsFallWhenHoldingJump():Void {
		var normal = new LocalCharacter(airborneLevel());
		var propeller = new LocalCharacter(airborneLevel());
		propeller.setHats([4, 0xFFFFFF, -1]);

		normal.step(new LocalPlayerInput(false, false, true));
		propeller.step(new LocalPlayerInput(false, false, true));
		assertClose(normal.debugState().vy * 0.85, propeller.debugState().vy, "propeller slows falling while jump is held");

		var notHeld = new LocalCharacter(airborneLevel());
		notHeld.setHats([4, 0xFFFFFF, -1]);
		notHeld.step(new LocalPlayerInput());
		assertClose(normal.debugState().vy, notHeld.debugState().vy, "propeller does not slow falling without jump held");
	}

	private static function testCowboyHatBoostsStatsAndForcesAirborneWaterModeUntilRemoved():Void {
		var cowboy = new LocalCharacter(airborneLevel());
		cowboy.setHats([5, 0xFFFFFF, -1]);

		var equipped = cowboy.debugState();
		assertClose(100, equipped.speedStat, "cowboy hat raises speed to Flash minimum");
		assertClose(99.6, equipped.accelerationStat, "cowboy hat raises acceleration to Flash minimum");
		assertClose(100, equipped.jumpStat, "cowboy hat raises jump to Flash minimum");

		cowboy.step(new LocalPlayerInput());
		var swimming = cowboy.debugState();
		assertEquals("water", swimming.mode, "cowboy hat forces airborne water mode");
		assertEquals("swim", swimming.animation, "cowboy airborne mode uses swim animation");

		cowboy.setHats([]);
		var removed = cowboy.debugState();
		assertClose(50, removed.speedStat, "cowboy hat removal restores starting speed");
		assertClose(50, removed.accelerationStat, "cowboy hat removal restores starting acceleration");
		assertClose(50, removed.jumpStat, "cowboy hat removal restores starting jump");
	}

	private static function testMoonHatReducesGravityUntilRemoved():Void {
		var normal = new LocalCharacter(heavyGravityAirborneLevel());
		var moon = new LocalCharacter(heavyGravityAirborneLevel());
		moon.setHats([11, 0xFFFFFF, -1]);

		normal.step(new LocalPlayerInput());
		moon.step(new LocalPlayerInput());
		assertClose(normal.debugState().vy * 0.85, moon.debugState().vy, "moon hat applies low gravity");

		var removed = new LocalCharacter(heavyGravityAirborneLevel());
		removed.setHats([11, 0xFFFFFF, -1]);
		removed.setHats([]);
		removed.step(new LocalPlayerInput());
		assertClose(normal.debugState().vy, removed.debugState().vy, "moon hat removal restores level gravity");
	}

	private static function assertSameState(controller:LocalPlayerController, character:LocalCharacter, label:String):Void {
		var expected = controller.debugState();
		var actual = character.debugState();
		assertEquals(expected.serialize(), actual.serialize(), '$label debug state');
		assertClose(expected.x, character.x, '$label x');
		assertClose(expected.y, character.y, '$label y');
		assertClose(expected.vx, character.velX, '$label velX');
		assertClose(expected.vy, character.velY, '$label velY');
		assertEquals(expected.grounded, character.grounded, '$label grounded');
		assertEquals(expected.crouching, character.crouching, '$label crouching');
		assertEquals(expected.animation, character.state, '$label animation state');
		assertClose(0.9 * controller.facingScaleX, character.display.scaleX, '$label facing scale');
	}

	private static function flatLevel():FixtureLevel {
		return new FixtureLevel(
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

	private static function airborneLevel():FixtureLevel {
		return new FixtureLevel(
			"local-character-airborne",
			"Local Character Airborne",
			8,
			8,
			30,
			1,
			new StatDefaults(50, 0.2 + 50 / 60, 2 + 50 / 40),
			new TilePosition(2, 2),
			new TilePosition(6, 6),
			[]
		);
	}

	private static function heavyGravityAirborneLevel():FixtureLevel {
		return new FixtureLevel(
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
}
